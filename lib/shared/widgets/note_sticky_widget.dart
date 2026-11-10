import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class StickyNote {
  final String id;
  final String text;
  final bool done;

  const StickyNote({required this.id, required this.text, this.done = false});

  StickyNote copyWith({String? text, bool? done}) =>
      StickyNote(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory StickyNote.fromJson(Map<String, dynamic> j) => StickyNote(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

const String _kNotesKey = 'sticky_notes_v2';
const int kNoteMaxLength = 120;

/// State notifier for sticky notes with guaranteed SharedPreferences fallback
/// so it NEVER fails even if provider overrides haven't fired yet.
class StickyNotesNotifier extends StateNotifier<AsyncValue<List<StickyNote>>> {
  SharedPreferences? _prefs;

  StickyNotesNotifier(this._prefs) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _load() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kNotesKey);
      if (raw == null || raw.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final decoded = jsonDecode(raw) as List;
      final list = decoded
          .map((e) => StickyNote.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (_) {
      // In case of parsing error, reset safely to empty list
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _save(List<StickyNote> notes) async {
    state = AsyncValue.data(notes);
    try {
      final prefs = await _getPrefs();
      await prefs.setString(
        _kNotesKey,
        jsonEncode(notes.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  List<StickyNote> get _current => state.value ?? const [];

  Future<void> add(String text) async {
    final newNote = StickyNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
    );
    await _save([newNote, ..._current]);
  }

  Future<void> edit(String id, String text) async {
    await _save([
      for (final n in _current) n.id == id ? n.copyWith(text: text) : n,
    ]);
  }

  Future<void> toggle(String id) async {
    await _save([
      for (final n in _current) n.id == id ? n.copyWith(done: !n.done) : n,
    ]);
  }

  Future<void> remove(String id) async {
    await _save(_current.where((n) => n.id != id).toList());
  }
}

final stickyNotesProvider =
    StateNotifierProvider<StickyNotesNotifier, AsyncValue<List<StickyNote>>>((ref) {
  return StickyNotesNotifier(ref.watch(sharedPreferencesProvider));
});

/// Shows the Frosted Glass Notes Modal Sheet
void showGlassNotesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _GlassNotesSheetContent(),
  );
}

class _GlassNotesSheetContent extends ConsumerWidget {
  const _GlassNotesSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final notesAsync = ref.watch(stickyNotesProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceHigh.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0x100F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('📌', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Catatan & Pengingat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary(context),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),

              // Notes List
              Expanded(
                child: notesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Gagal memuat catatan',
                      style: GoogleFonts.inter(color: AppColors.expense(context)),
                    ),
                  ),
                  data: (notes) {
                    if (notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '📝',
                              style: TextStyle(
                                fontSize: 44,
                                color: AppColors.textSecondary(context).withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada catatan pengingat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tulis tagihan, target belanja, atau rencana',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final note = notes[i];
                        return _NoteItemTile(note: note);
                      },
                    );
                  },
                ),
              ),

              // Add Note Quick Bar
              _AddNoteInputBar(ref: ref),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteItemTile extends ConsumerWidget {
  final StickyNote note;

  const _NoteItemTile({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: note.done
            ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))
            : (isDark ? AppColors.surface.withValues(alpha: 0.7) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.done
              ? Colors.transparent
              : (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0x180F172A)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => ref.read(stickyNotesProvider.notifier).toggle(note.id),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                note.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: note.done
                    ? AppColors.income(context)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note.text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: note.done
                    ? AppColors.textSecondary(context).withValues(alpha: 0.6)
                    : AppColors.textPrimary(context),
                decoration: note.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.expense(context).withValues(alpha: 0.7),
            onPressed: () => ref.read(stickyNotesProvider.notifier).remove(note.id),
          ),
        ],
      ),
    );
  }
}

class _AddNoteInputBar extends StatefulWidget {
  final WidgetRef ref;

  const _AddNoteInputBar({required this.ref});

  @override
  State<_AddNoteInputBar> createState() => _AddNoteInputBarState();
}

class _AddNoteInputBarState extends State<_AddNoteInputBar> {
  final _textController = TextEditingController();

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.ref.read(stickyNotesProvider.notifier).add(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.surfaceHigh
            : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: AppColors.isDark(context)
                ? AppColors.glassBorderDark
                : AppColors.glassBorderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLength: kNoteMaxLength,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Tulis pengingat baru...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.isDark(context)
                    ? AppColors.surface
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: isDark ? const Color(0xFF0A0D14) : Colors.white,
              ),
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Action Glass Note Button that floats nicely on Dashboard
class FloatingNoteButton extends ConsumerWidget {
  const FloatingNoteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final notesAsync = ref.watch(stickyNotesProvider);
    final uncompletedCount = notesAsync.maybeWhen(
      data: (notes) => notes.where((n) => !n.done).length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 74, right: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.92),
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.38 : 0.8),
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () => showGlassNotesSheet(context),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Catatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary(context),
                      ),
                    ),
                    if (uncompletedCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$uncompletedCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF0A0D14) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

/// Kept for backwards compatibility
class NoteStickyWidget extends StatelessWidget {
  const NoteStickyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
