import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_providers.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatRoomModel chatRoom;
  final ChatParticipantInfo partner;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
    required this.partner,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _hasText = false;
  ChatMessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    _markRead();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _markRead() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(chatRepositoryProvider).markAsRead(
            chatId: widget.chatRoom.id,
            userId: user.uid,
          );
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(ChatMessageModel message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
    });
    _messageController.clear();
  }

  Future<void> _handleDelete(ChatMessageModel message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131826) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
        title: Text(
          'Hapus Pesan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Pesan ini akan dihapus secara permanen untuk semua orang.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Hapus',
              style: TextStyle(
                color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_editingMessage?.id == message.id) {
        _cancelEdit();
      }
      await ref.read(chatRepositoryProvider).deleteMessage(
            chatId: widget.chatRoom.id,
            messageId: message.id,
          );
      if (mounted) {
        showGlassSnackBar(context, 'Pesan berhasil dihapus');
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, 'Gagal menghapus pesan. Coba lagi.', isError: true);
      }
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    if (_editingMessage != null) {
      final msgToEdit = _editingMessage!;
      setState(() => _isSending = true);
      _messageController.clear();
      _cancelEdit();
      HapticFeedback.lightImpact();

      try {
        await ref.read(chatRepositoryProvider).editMessage(
              chatId: widget.chatRoom.id,
              messageId: msgToEdit.id,
              newText: text,
            );
        if (mounted) {
          showGlassSnackBar(context, 'Pesan berhasil diedit');
        }
      } catch (e) {
        if (mounted) {
          showGlassSnackBar(context, 'Gagal mengedit pesan. Coba lagi.', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();
    HapticFeedback.lightImpact();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            chatId: widget.chatRoom.id,
            senderId: currentUser.uid,
            senderName: profile?.displayName ?? 'Sobat',
            partnerId: widget.partner.userId,
            text: text,
          );
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, 'Gagal mengirim pesan. Periksa koneksi.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendPhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131826) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kirim Foto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Ambil dari Kamera',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _processImagePick(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Pilih dari Galeri Foto',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _processImagePick(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked == null) return;

      final currentUser = ref.read(currentUserProvider);
      final profile = ref.read(userProfileProvider).value;
      if (currentUser == null) return;

      setState(() => _isSending = true);
      HapticFeedback.lightImpact();

      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);

      await ref.read(chatRepositoryProvider).sendImageMessage(
            chatId: widget.chatRoom.id,
            senderId: currentUser.uid,
            senderName: profile?.displayName ?? 'Sobat',
            partnerId: widget.partner.userId,
            base64Image: base64Str,
          );
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, 'Gagal mengirim foto. Coba lagi.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatRoom.id));

    // Automatically mark incoming messages as read while room is open
    ref.listen<AsyncValue<List<ChatMessageModel>>>(
      chatMessagesStreamProvider(widget.chatRoom.id),
      (prev, next) {
        final messages = next.valueOrNull;
        if (messages != null && messages.isNotEmpty && currentUser != null) {
          final hasUnread = messages.any(
            (m) => m.senderId != currentUser.uid && !m.isRead,
          );
          if (hasUnread) {
            _markRead();
          }
        }
      },
    );

    return GlassScaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF34D399).withValues(alpha: isDark ? 0.25 : 0.15),
              backgroundImage: widget.partner.photoUrl != null
                  ? NetworkImage(widget.partner.photoUrl!)
                  : null,
              child: widget.partner.photoUrl == null
                  ? Text(
                      widget.partner.displayName.isNotEmpty
                          ? widget.partner.displayName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partner.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    widget.partner.email,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 38,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Belum ada pesan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kirim salam pertama untuk memulai obrolan! 🐾',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  );
                }

                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser?.uid;

                      return _ChatBubble(
                        message: message,
                        isMe: isMe,
                        isDark: isDark,
                        currentUserId: currentUser?.uid ?? '',
                        onEdit: _startEditing,
                        onDelete: _handleDelete,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(
                child: Text(
                  'Gagal memuat pesan: $err',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),

          // Bottom Input Bar
          _ChatInputBar(
            controller: _messageController,
            focusNode: _focusNode,
            editingMessage: _editingMessage,
            isSending: _isSending,
            hasText: _hasText,
            isDark: isDark,
            onSend: _handleSend,
            onPickPhoto: _pickAndSendPhoto,
            onCancelEdit: _cancelEdit,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isDark;
  final String currentUserId;
  final void Function(ChatMessageModel message)? onEdit;
  final void Function(ChatMessageModel message)? onDelete;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  void _showMessageOptions(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    final emojis = ['❤️', '😂', '👍', '😮', '😢', '🙏'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131826) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Emoji Reaction Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2236).withValues(alpha: 0.8)
                          : const Color(0xFFF1F5F9).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: emojis.map((emoji) {
                        final hasReacted = message.reactions[currentUserId] == emoji;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(ctx).pop();
                            ref.read(chatRepositoryProvider).toggleReaction(
                                  chatId: message.chatId,
                                  messageId: message.id,
                                  userId: currentUserId,
                                  emoji: emoji,
                                );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasReacted
                                  ? const Color(0xFF34D399).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (message.text.isNotEmpty && message.text != '📷 Foto')
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      title: Text(
                        'Salin Teks',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        Navigator.of(ctx).pop();
                        showGlassSnackBar(context, 'Teks berhasil disalin');
                      },
                    ),
                  if (isMe && message.type == 'text')
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      title: Text(
                        'Edit Pesan',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onEdit?.call(message);
                      },
                    ),
                  if (isMe)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                      ),
                      title: Text(
                        'Hapus Pesan',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onDelete?.call(message);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context, ref),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? (isDark
                    ? const Color(0xFF1B2236).withValues(alpha: 0.95)
                    : const Color(0xFF0F172A).withValues(alpha: 0.90))
                : (isDark
                    ? const Color(0xFF131826).withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.92)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: Border.all(
              color: isMe
                  ? const Color(0xFF34D399).withValues(alpha: isDark ? 0.35 : 0.20)
                  : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
                _ChatImageContent(
                  imageUrl: message.imageUrl!,
                  isDark: isDark,
                ),
                if (message.text.isNotEmpty && message.text != '📷 Foto')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      message.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isMe
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
              ] else ...[
                Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: isMe
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.65)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                  if (message.isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      '· diedit',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.60)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildCheckmarkIcon(message, isDark),
                  ],
                ],
              ),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showMessageOptions(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0D14).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.reactions.values.toSet().join(' '),
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (message.reactions.length > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${message.reactions.length}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmarkIcon(ChatMessageModel message, bool isDark) {
    if (message.isRead) {
      // Centang 2 Biru: Pesan sudah dibaca oleh pasangan
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFF38BDF8),
      );
    } else if (message.isDelivered) {
      // Centang 2 Abu-abu: Pesan sudah sampai / diterima di HP pasangan
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.45),
      );
    } else {
      // Centang 1 Abu-abu: Pesan baru terkirim ke server
      return Icon(
        Icons.done_rounded,
        size: 14,
        color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.45),
      );
    }
  }
}

class _ChatImageContent extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  const _ChatImageContent({
    required this.imageUrl,
    required this.isDark,
  });

  Uint8List? _decodeBytes() {
    try {
      String clean = imageUrl;
      if (clean.startsWith('data:image')) {
        clean = clean.split(',').last;
      }
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  void _openViewer(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBytes();
    if (bytes == null) {
      return Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2236) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openViewer(context, bytes),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.memory(
              bytes,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_in_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final Uint8List bytes;

  const _FullScreenImageViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatMessageModel? editingMessage;
  final bool isSending;
  final bool hasText;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onPickPhoto;
  final VoidCallback onCancelEdit;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.editingMessage,
    required this.isSending,
    required this.hasText,
    required this.isDark,
    required this.onSend,
    required this.onPickPhoto,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D111A).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editingMessage != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161C2C)
                      : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mengedit Pesan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            ),
                          ),
                          Text(
                            editingMessage!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: onCancelEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(10, editingMessage != null ? 6 : 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Photo Attachment Button
                  GestureDetector(
                    onTap: isSending ? null : onPickPhoto,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF161C2C)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text Field Capsule
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 42, maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF161C2C)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: editingMessage != null ? 'Edit pesan...' : 'Ketik pesan...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send / Save Button
                  GestureDetector(
                    onTap: (isSending || (!hasText && editingMessage == null)) ? null : onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (hasText || editingMessage != null)
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFF161C2C) : const Color(0xFFE2E8F0)),
                        shape: BoxShape.circle,
                        border: (hasText || editingMessage != null)
                            ? null
                            : Border.all(
                                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                                width: 1.0,
                              ),
                        boxShadow: (hasText || editingMessage != null)
                            ? [
                                BoxShadow(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isSending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                ),
                              )
                            : Icon(
                                editingMessage != null
                                    ? Icons.check_rounded
                                    : Icons.arrow_upward_rounded,
                                color: (hasText || editingMessage != null)
                                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : (isDark ? Colors.white38 : Colors.black38),
                                size: 21,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
