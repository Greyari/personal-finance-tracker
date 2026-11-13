import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import 'custom_reminder_icons.dart';

class StickyNote {
  final String id;
  final String text;
  final bool done;
  final int? reminderHour;
  final int? reminderMinute;
  final DateTime? reminderDate;
  final bool isDaily;
  final bool hasReminder;
  final String? lastNotifiedDate;

  const StickyNote({
    required this.id,
    required this.text,
    this.done = false,
    this.reminderHour,
    this.reminderMinute,
    this.reminderDate,
    this.isDaily = false,
    this.hasReminder = false,
    this.lastNotifiedDate,
  });

  StickyNote copyWith({
    String? text,
    bool? done,
    int? reminderHour,
    int? reminderMinute,
    DateTime? reminderDate,
    bool? isDaily,
    bool? hasReminder,
    String? lastNotifiedDate,
    bool clearReminder = false,
  }) {
    return StickyNote(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      reminderDate: clearReminder ? null : (reminderDate ?? this.reminderDate),
      isDaily: clearReminder ? false : (isDaily ?? this.isDaily),
      hasReminder: clearReminder ? false : (hasReminder ?? this.hasReminder),
      lastNotifiedDate: lastNotifiedDate ?? this.lastNotifiedDate,
    );
  }

  String get reminderLabel {
    if (!hasReminder || reminderHour == null || reminderMinute == null) {
      return '';
    }
    final timeStr =
        '${reminderHour!.toString().padLeft(2, '0')}:${reminderMinute!.toString().padLeft(2, '0')}';
    if (isDaily) {
      return 'Tiap Hari, $timeStr';
    }
    if (reminderDate != null) {
      final now = DateTime.now();
      final isToday = reminderDate!.year == now.year &&
          reminderDate!.month == now.month &&
          reminderDate!.day == now.day;
      final tomorrow = now.add(const Duration(days: 1));
      final isTomorrow = reminderDate!.year == tomorrow.year &&
          reminderDate!.month == tomorrow.month &&
          reminderDate!.day == tomorrow.day;

      if (isToday) return 'Hari ini, $timeStr';
      if (isTomorrow) return 'Besok, $timeStr';
      return '${reminderDate!.day}/${reminderDate!.month}, $timeStr';
    }
    return timeStr;
  }

  bool isDueNow(DateTime now) {
    if (!hasReminder || done || reminderHour == null || reminderMinute == null) {
      return false;
    }
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (lastNotifiedDate == todayStr) {
      return false;
    }

    if (isDaily) {
      if (now.hour > reminderHour! ||
          (now.hour == reminderHour! && now.minute >= reminderMinute!)) {
        return true;
      }
      return false;
    } else {
      if (reminderDate == null) return false;
      final scheduled = DateTime(
        reminderDate!.year,
        reminderDate!.month,
        reminderDate!.day,
        reminderHour!,
        reminderMinute!,
      );
      return now.isAfter(scheduled) || now.isAtSameMomentAs(scheduled);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderDate': reminderDate?.toIso8601String(),
        'isDaily': isDaily,
        'hasReminder': hasReminder,
        'lastNotifiedDate': lastNotifiedDate,
      };

  factory StickyNote.fromJson(Map<String, dynamic> j) => StickyNote(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        reminderHour: j['reminderHour'] as int?,
        reminderMinute: j['reminderMinute'] as int?,
        reminderDate: j['reminderDate'] != null
            ? DateTime.tryParse(j['reminderDate'] as String)
            : null,
        isDaily: j['isDaily'] as bool? ?? false,
        hasReminder: j['hasReminder'] as bool? ?? false,
        lastNotifiedDate: j['lastNotifiedDate'] as String?,
      );
}

const String _kNotesKey = 'sticky_notes_v3';
const int kNoteMaxLength = 140;

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
    await addNote(text: text);
  }

  Future<void> addNote({
    required String text,
    int? reminderHour,
    int? reminderMinute,
    DateTime? reminderDate,
    bool isDaily = false,
    bool hasReminder = false,
  }) async {
    final newNote = StickyNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      reminderDate: reminderDate,
      isDaily: isDaily,
      hasReminder: hasReminder,
    );
    await _save([newNote, ..._current]);

    if (hasReminder && reminderHour != null && reminderMinute != null) {
      final notifId = newNote.id.hashCode.abs() % 100000000;
      await NotificationService().scheduleNoteReminder(
        id: notifId,
        title: 'Pengingat Catatan',
        body: text,
        hour: reminderHour,
        minute: reminderMinute,
        date: reminderDate,
        isDaily: isDaily,
      );
    }
  }

  Future<void> edit(String id, String text) async {
    await _save([
      for (final n in _current) n.id == id ? n.copyWith(text: text) : n,
    ]);
  }

  Future<void> updateReminder(
    String id, {
    required int? hour,
    required int? minute,
    required DateTime? date,
    required bool isDaily,
    required bool hasReminder,
  }) async {
    await _save([
      for (final n in _current)
        n.id == id
            ? n.copyWith(
                reminderHour: hour,
                reminderMinute: minute,
                reminderDate: date,
                isDaily: isDaily,
                hasReminder: hasReminder,
                clearReminder: !hasReminder,
              )
            : n,
    ]);

    final notifId = id.hashCode.abs() % 100000000;
    if (hasReminder && hour != null && minute != null) {
      final note = _current.firstWhere((n) => n.id == id, orElse: () => StickyNote(id: id, text: ''));
      await NotificationService().scheduleNoteReminder(
        id: notifId,
        title: 'Pengingat Catatan',
        body: note.text.isNotEmpty ? note.text : 'Catatan Anda memiliki pengingat terjadwal',
        hour: hour,
        minute: minute,
        date: date,
        isDaily: isDaily,
      );
    } else {
      await NotificationService().cancelNotification(notifId);
    }
  }

  Future<void> toggle(String id) async {
    await _save([
      for (final n in _current) n.id == id ? n.copyWith(done: !n.done) : n,
    ]);
    final note = _current.firstWhere((n) => n.id == id, orElse: () => StickyNote(id: id, text: ''));
    final notifId = id.hashCode.abs() % 100000000;
    if (note.done && !note.isDaily) {
      await NotificationService().cancelNotification(notifId);
    }
  }

  Future<void> remove(String id) async {
    final notifId = id.hashCode.abs() % 100000000;
    await NotificationService().cancelNotification(notifId);
    await _save(_current.where((n) => n.id != id).toList());
  }

  Future<void> markNotified(String id, String dateStr) async {
    await _save([
      for (final n in _current)
        n.id == id ? n.copyWith(lastNotifiedDate: dateStr) : n,
    ]);
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
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceHigh.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.96),
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

              // Header with Custom Handcrafted Glass Pin Icon
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
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0x100F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const CustomGlassPinIcon(size: 20),
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
                            const CustomGlassPinIcon(size: 44),
                            const SizedBox(height: 14),
                            Text(
                              'Belum ada catatan pengingat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tulis tagihan, rencana, atau jadwalkan jam pengingat',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final now = DateTime.now();
                    final dueNotes = notes.where((n) => n.isDueNow(now)).toList();

                    return Column(
                      children: [
                        if (dueNotes.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.income(context).withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.income(context).withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                CustomLuxuryBellIcon(
                                  size: 20,
                                  accentColor: AppColors.income(context),
                                  hasRipples: true,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengingat Waktunya Tiba!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.income(context),
                                        ),
                                      ),
                                      Text(
                                        '${dueNotes.length} catatan perlu perhatian Anda sekarang.',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.textPrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: notes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final note = notes[i];
                              return _NoteItemTile(note: note);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Add Note Quick Bar with Reminder Selector
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
    final isDue = note.isDueNow(DateTime.now());

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
              : isDue
                  ? AppColors.income(context).withValues(alpha: 0.75)
                  : (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0x180F172A)),
          width: isDue && !note.done ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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

          // Reminder Chip row if note has active reminder
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4),
            child: Row(
              children: [
                if (note.hasReminder) ...[
                  InkWell(
                    onTap: () async {
                      final res = await _showReminderConfigModal(
                        context: context,
                        initialHour: note.reminderHour,
                        initialMinute: note.reminderMinute,
                        initialIsDaily: note.isDaily,
                        initialDate: note.reminderDate,
                      );
                      if (res != null) {
                        if (res['clear'] == true) {
                          ref.read(stickyNotesProvider.notifier).updateReminder(
                            note.id,
                            hour: null,
                            minute: null,
                            date: null,
                            isDaily: false,
                            hasReminder: false,
                          );
                        } else {
                          ref.read(stickyNotesProvider.notifier).updateReminder(
                            note.id,
                            hour: res['hour'] as int?,
                            minute: res['minute'] as int?,
                            date: res['date'] as DateTime?,
                            isDaily: res['isDaily'] as bool? ?? false,
                            hasReminder: true,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDue
                            ? AppColors.income(context).withValues(alpha: isDark ? 0.28 : 0.20)
                            : AppColors.income(context).withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDue
                              ? AppColors.income(context).withValues(alpha: 0.70)
                              : AppColors.income(context).withValues(alpha: 0.35),
                          width: isDue ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomLuxuryBellIcon(
                            size: 13,
                            accentColor: AppColors.income(context),
                            hasRipples: isDue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDue ? 'Waktunya! • ${note.reminderLabel}' : note.reminderLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.income(context),
                            ),
                          ),
                          if (note.isDaily) ...[
                            const SizedBox(width: 5),
                            CustomDailyRepeatIcon(
                              size: 11,
                              color: AppColors.income(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  InkWell(
                    onTap: () async {
                      final res = await _showReminderConfigModal(context: context);
                      if (res != null && res['hasReminder'] == true) {
                        ref.read(stickyNotesProvider.notifier).updateReminder(
                          note.id,
                          hour: res['hour'] as int?,
                          minute: res['minute'] as int?,
                          date: res['date'] as DateTime?,
                          isDaily: res['isDaily'] as bool? ?? false,
                          hasReminder: true,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomLuxuryBellIcon(
                            size: 12,
                            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                            hasRipples: false,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+ Atur Jam Pengingat',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary(context).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
  int? _reminderHour;
  int? _reminderMinute;
  DateTime? _reminderDate;
  bool _isDaily = false;
  bool _hasReminder = false;

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.ref.read(stickyNotesProvider.notifier).addNote(
      text: text,
      reminderHour: _hasReminder ? _reminderHour : null,
      reminderMinute: _hasReminder ? _reminderMinute : null,
      reminderDate: _hasReminder ? _reminderDate : null,
      isDaily: _hasReminder ? _isDaily : false,
      hasReminder: _hasReminder,
    );
    _textController.clear();
    setState(() {
      _hasReminder = false;
      _reminderHour = null;
      _reminderMinute = null;
      _reminderDate = null;
      _isDaily = false;
    });
  }

  String _getReminderLabel() {
    if (!_hasReminder || _reminderHour == null || _reminderMinute == null) {
      return '';
    }
    final timeStr =
        '${_reminderHour!.toString().padLeft(2, '0')}:${_reminderMinute!.toString().padLeft(2, '0')}';
    if (_isDaily) {
      return 'Tiap Hari, $timeStr';
    }
    if (_reminderDate != null) {
      final now = DateTime.now();
      if (_reminderDate!.day == now.day && _reminderDate!.month == now.month) {
        return 'Hari ini, $timeStr';
      }
      return 'Besok, $timeStr';
    }
    return timeStr;
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
        color: isDark ? AppColors.surfaceHigh : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    hintText: 'Tulis catatan pengingat...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surface : Colors.white,
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
          const SizedBox(height: 8),

          // Reminder Configuration Chip Toggle
          InkWell(
            onTap: () async {
              final res = await _showReminderConfigModal(
                context: context,
                initialHour: _reminderHour,
                initialMinute: _reminderMinute,
                initialIsDaily: _isDaily,
                initialDate: _reminderDate,
              );
              if (res != null) {
                setState(() {
                  if (res['clear'] == true) {
                    _hasReminder = false;
                    _reminderHour = null;
                    _reminderMinute = null;
                    _reminderDate = null;
                    _isDaily = false;
                  } else {
                    _hasReminder = true;
                    _reminderHour = res['hour'] as int?;
                    _reminderMinute = res['minute'] as int?;
                    _isDaily = res['isDaily'] as bool? ?? false;
                    _reminderDate = res['date'] as DateTime?;
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _hasReminder
                    ? AppColors.income(context).withValues(alpha: isDark ? 0.20 : 0.12)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasReminder
                      ? AppColors.income(context).withValues(alpha: 0.45)
                      : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomLuxuryBellIcon(
                    size: 14,
                    accentColor: _hasReminder ? AppColors.income(context) : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hasReminder
                        ? 'Pengingat: ${_getReminderLabel()}'
                        : 'Ingatkan saya di jam segini (Tiap hari / Sekali)',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: _hasReminder ? FontWeight.w700 : FontWeight.w500,
                      color: _hasReminder
                          ? AppColors.income(context)
                          : AppColors.textSecondary(context),
                    ),
                  ),
                  if (_hasReminder) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _hasReminder = false;
                          _reminderHour = null;
                          _reminderMinute = null;
                          _reminderDate = null;
                          _isDaily = false;
                        });
                      },
                      child: const Icon(Icons.close_rounded, size: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted Glass Modal for configuring reminder time & recurrence
Future<Map<String, dynamic>?> _showReminderConfigModal({
  required BuildContext context,
  int? initialHour,
  int? initialMinute,
  bool initialIsDaily = false,
  DateTime? initialDate,
}) async {
  final isDark = AppColors.isDark(context);
  final now = DateTime.now();
  int selectedHour = initialHour ?? ((now.hour + 1) % 24);
  int selectedMinute = initialMinute ?? 0;
  bool isDaily = initialIsDaily;
  DateTime selectedDate = initialDate ?? now;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final timeStr =
              '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: CustomLuxuryBellIcon(
                          size: 20,
                          accentColor: AppColors.income(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Atur Waktu Pengingat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Waktu / Jam Selector
                  Text(
                    'PILIH JAM PENGINGAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(hour: selectedHour, minute: selectedMinute),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedHour = picked.hour;
                          selectedMinute = picked.minute;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 22,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                timeStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Ubah Jam',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Preset chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickTimeChip(
                          label: 'Pagi 08:00',
                          hour: 8,
                          minute: 0,
                          isSelected: selectedHour == 8 && selectedMinute == 0,
                          onTap: () => setModalState(() {
                            selectedHour = 8;
                            selectedMinute = 0;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: 'Siang 13:00',
                          hour: 13,
                          minute: 0,
                          isSelected: selectedHour == 13 && selectedMinute == 0,
                          onTap: () => setModalState(() {
                            selectedHour = 13;
                            selectedMinute = 0;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: 'Sore 17:00',
                          hour: 17,
                          minute: 0,
                          isSelected: selectedHour == 17 && selectedMinute == 0,
                          onTap: () => setModalState(() {
                            selectedHour = 17;
                            selectedMinute = 0;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip(
                          label: 'Malam 20:00',
                          hour: 20,
                          minute: 0,
                          isSelected: selectedHour == 20 && selectedMinute == 0,
                          onTap: () => setModalState(() {
                            selectedHour = 20;
                            selectedMinute = 0;
                          }),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Frekuensi: Setiap Hari vs Hanya Sekali
                  Text(
                    'FREKUENSI PENGINGAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => isDaily = true),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDaily
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDaily
                                    ? Colors.transparent
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomDailyRepeatIcon(
                                  size: 15,
                                  color: isDaily
                                      ? (isDark ? const Color(0xFF0A0D14) : Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Setiap Hari',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDaily
                                        ? (isDark ? const Color(0xFF0A0D14) : Colors.white)
                                        : AppColors.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => isDaily = false),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isDaily
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !isDaily
                                    ? Colors.transparent
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 16,
                                  color: !isDaily
                                      ? (isDark ? const Color(0xFF0A0D14) : Colors.white)
                                      : AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hanya Sekali',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: !isDaily
                                        ? (isDark ? const Color(0xFF0A0D14) : Colors.white)
                                        : AppColors.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // If not daily, show date quick chips
                  if (!isDaily) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickDateChip(
                          label: 'Hari ini',
                          isSelected: selectedDate.day == now.day && selectedDate.month == now.month,
                          onTap: () => setModalState(() => selectedDate = now),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickDateChip(
                          label: 'Besok',
                          isSelected: selectedDate.day == now.add(const Duration(days: 1)).day,
                          onTap: () => setModalState(() => selectedDate = now.add(const Duration(days: 1))),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setModalState(() => selectedDate = pickedDate);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Test notification trigger button
                  InkWell(
                    onTap: () async {
                      await NotificationService().showInstantNotification(
                        id: 99999,
                        title: 'Tes Pengingat Personal Finance',
                        body: 'Notifikasi berhasil muncul di bilah status HP Anda!',
                      );
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Notifikasi telah dikirim ke bilah status HP!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.income(context).withValues(alpha: isDark ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.income(context).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomLuxuryBellIcon(
                            size: 16,
                            accentColor: AppColors.income(context),
                            hasRipples: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Uji Notifikasi ke HP Sekarang',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.income(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, {'clear': true}),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Hapus Pengingat',
                            style: TextStyle(
                              color: AppColors.expense(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, {
                            'hour': selectedHour,
                            'minute': selectedMinute,
                            'isDaily': isDaily,
                            'date': selectedDate,
                            'hasReminder': true,
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            foregroundColor: isDark ? const Color(0xFF0A0D14) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Simpan Pengingat', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildQuickTimeChip({
  required String label,
  required int hour,
  required int minute,
  required bool isSelected,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0x180F172A))
            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF0F172A))
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

Widget _buildQuickDateChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0x180F172A))
            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF0F172A))
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
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
    final hasActiveReminder = notesAsync.maybeWhen(
      data: (notes) => notes.any((n) => !n.done && n.hasReminder),
      orElse: () => false,
    );
    final dueCount = notesAsync.maybeWhen(
      data: (notes) {
        final now = DateTime.now();
        return notes.where((n) => !n.done && n.isDueNow(now)).length;
      },
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
                color: dueCount > 0
                    ? AppColors.income(context).withValues(alpha: isDark ? 0.80 : 0.85)
                    : Colors.white.withValues(alpha: isDark ? 0.38 : 0.8),
                width: dueCount > 0 ? 1.5 : 1.2,
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
                    // Handcrafted Unique Custom Glass Pin Icon
                    const CustomGlassPinIcon(size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Catatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary(context),
                      ),
                    ),
                    if (hasActiveReminder || dueCount > 0) ...[
                      const SizedBox(width: 6),
                      CustomLuxuryBellIcon(
                        size: 14,
                        accentColor: AppColors.income(context),
                        hasRipples: dueCount > 0,
                      ),
                    ],
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
