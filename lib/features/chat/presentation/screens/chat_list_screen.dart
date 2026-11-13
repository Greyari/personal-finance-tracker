import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_providers.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  void _showNewChatDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            Future<void> submitSearch() async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                setModalState(() => errorMessage = 'Silakan masukkan alamat email pasangan.');
                return;
              }

              final currentUser = ref.read(currentUserProvider);
              final currentProfile = ref.read(userProfileProvider).value;
              if (currentUser == null || currentProfile == null) return;

              if (email.toLowerCase() == currentUser.email?.toLowerCase()) {
                setModalState(() => errorMessage = 'Anda tidak dapat memulai chat dengan diri sendiri.');
                return;
              }

              setModalState(() {
                isLoading = true;
                errorMessage = null;
              });

              try {
                final chatRepo = ref.read(chatRepositoryProvider);
                final partner = await chatRepo.searchUserByEmail(email);

                if (partner == null) {
                  setModalState(() {
                    isLoading = false;
                    errorMessage = 'Akun dengan email ini belum ditemukan. Pastikan pasangan sudah mendaftar dan login di aplikasi.';
                  });
                  return;
                }

                final room = await chatRepo.getOrCreateChatRoom(
                  currentUser: currentProfile,
                  partner: partner,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatRoom: room,
                        partner: partner,
                      ),
                    ),
                  );
                }
              } catch (e) {
                setModalState(() {
                  isLoading = false;
                  errorMessage = 'Gagal menghubungkan: $e';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131826) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mulai Obrolan Baru',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Cari akun pasangan lewat alamat email',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Email Pasangan / Teman',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceHighDark : AppColors.surfaceHighLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: errorMessage != null
                                      ? (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                                  width: errorMessage != null ? 1.5 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.search,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setModalState(() => errorMessage = null);
                                  } else {
                                    setModalState(() {});
                                  }
                                },
                                onSubmitted: (_) => submitSearch(),
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 20,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  suffixIcon: emailController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                          onPressed: () {
                                            emailController.clear();
                                            setModalState(() => errorMessage = null);
                                          },
                                        )
                                      : null,
                                  hintText: 'contoh: nama@gmail.com',
                                  hintStyle: TextStyle(
                                    fontSize: 13.5,
                                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                        .withValues(alpha: 0.7),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pastikan pasanganmu sudah pernah login di aplikasi ini agar emailnya terdaftar di sistem direktori.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.35,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: GlassButton(
                                label: 'Cari & Mulai Chat',
                                icon: Icons.chat_rounded,
                                isLoading: isLoading,
                                onPressed: submitSearch,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(userChatsStreamProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          'Pesan & Obrolan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showNewChatDialog(context, ref),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.20 : 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_comment_rounded,
                size: 20,
                color: Color(0xFF34D399),
              ),
            ),
            tooltip: 'Mulai Chat Baru',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 95,
                        child: Lottie.asset(
                          'assets/lottie/cat_mascot.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Obrolan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hubungkan akun pasangan atau rekanmu dengan menekan tombol di bawah!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        label: 'Mulai Chat Baru 🐾',
                        icon: Icons.person_add_rounded,
                        onPressed: () => _showNewChatDialog(context, ref),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final room = chats[index];
                final partner = room.getOtherParticipant(currentUser?.uid ?? '') ??
                    const ChatParticipantInfo(
                      userId: '',
                      displayName: 'Pengguna',
                      email: '',
                    );
                final unread = room.getUnreadFor(currentUser?.uid ?? '');
                final timeStr = room.lastMessageTime != null
                    ? DateFormat('HH:mm').format(room.lastMessageTime!)
                    : '';

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chatRoom: room,
                          partner: partner,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        // Partner Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF34D399).withValues(alpha: isDark ? 0.25 : 0.15),
                          backgroundImage: partner.photoUrl != null
                              ? NetworkImage(partner.photoUrl!)
                              : null,
                          child: partner.photoUrl == null
                              ? Text(
                                  partner.displayName.isNotEmpty
                                      ? partner.displayName[0].toUpperCase()
                                      : 'P',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Chat Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      partner.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                                      color: unread > 0
                                          ? const Color(0xFF34D399)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      room.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                        color: unread > 0
                                            ? (isDark ? Colors.white : Colors.black87)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                  if (unread > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399),
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF34D399).withValues(alpha: 0.4),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0A0D14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (err, _) => Center(
            child: Text(
              'Gagal memuat obrolan: $err',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
