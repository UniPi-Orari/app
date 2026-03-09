import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/material.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/lesson_cache.dart';
import 'package:unipi_orario/ui/components/create_event/animated_reveal.dart';
import 'package:unipi_orario/ui/components/create_event/icon_row.dart';
import 'package:unipi_orario/ui/components/create_event/tappable_text.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key, this.lesson});
  final LessonModel? lesson;

  @override
  State<CreateEventPage> createState() => CreateEventPageState();
}

class CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController nameController = TextEditingController();

  // One-off
  DateTime date = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  // Recurring
  bool repeat = false;
  String recurrenceType = 'DAILY';
  final Set<int> selectedWeekdays = {};
  DateTime? recurrenceEndDate;
  DateTime recurringStartDate = DateTime.now();
  TimeOfDay recurringStartTime = TimeOfDay.now();
  TimeOfDay recurringEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  bool isSaving = false;

  bool get isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    if (l == null) return;

    nameController.text = l.name;

    if (l.isRecurring) {
      repeat = true;
      recurringStartDate = l.startDateTime;
      recurringStartTime = TimeOfDay.fromDateTime(l.startDateTime);
      recurringEndTime = TimeOfDay.fromDateTime(l.endDateTime);
      recurrenceEndDate = l.recurrenceEndDate;

      final rule = l.recurrenceRule!;
      if (rule == 'DAILY') {
        recurrenceType = 'DAILY';
      } else if (rule.startsWith('WEEKLY:')) {
        recurrenceType = 'WEEKLY';
        final days = rule.split(':')[1].split(',').map(int.parse);
        selectedWeekdays.addAll(days);
      }
    } else {
      date = l.startDateTime;
      startTime = TimeOfDay.fromDateTime(l.startDateTime);
      endTime = TimeOfDay.fromDateTime(l.endDateTime);
    }
  }

  // ─── Validation ───────────────────────────────────────────────────

  bool get timesValid {
    final s = repeat ? recurringStartTime : startTime;
    final e = repeat ? recurringEndTime : endTime;
    return e.hour > s.hour || (e.hour == s.hour && e.minute > s.minute);
  }

  bool get isValid {
    if (nameController.text.trim().isEmpty) return false;
    if (!timesValid) return false;
    if (repeat && recurrenceType == 'WEEKLY' && selectedWeekdays.isEmpty) return false;
    return true;
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  String buildRecurrenceRule() {
    if (!repeat) return 'NONE';
    if (recurrenceType == 'DAILY') return 'DAILY';
    final sorted = selectedWeekdays.toList()..sort();
    return 'WEEKLY:${sorted.join(',')}';
  }

  DateTime combineDateAndTime(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);

  String formatDate(DateTime dt) {
    const months = ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
    const weekdays = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String formatDateShort(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String weekdayLabel(int day) => ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day - 1];

  // ─── Pickers ──────────────────────────────────────────────────────

  Future<void> pickDate(BuildContext ctx) async {
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final now = DateTime.now();
    final picked = await showCupertinoCalendarPicker(
      ctx,
      widgetRenderBox: renderBox,
      initialDateTime: date,
      minimumDateTime: DateTime(2020),
      maximumDateTime: DateTime(2100),
      currentDateTime: now,
      mode: CupertinoCalendarMode.date,
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> pickTime(BuildContext ctx, {required bool isStart}) async {
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final initial = repeat ? (isStart ? recurringStartTime : recurringEndTime) : (isStart ? startTime : endTime);

    final picked = await showCupertinoTimePicker(
      ctx,
      widgetRenderBox: renderBox,
      initialTime: initial,
      onTimeChanged: (_) {},
    );
    if (picked == null) return;
    setState(() {
      if (repeat) {
        if (isStart) {
          recurringStartTime = picked;
        } else {
          recurringEndTime = picked;
        }
      } else {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      }
    });
  }

  Future<void> pickRecurrenceEndDate(BuildContext ctx) async {
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final now = DateTime.now();
    final picked = await showCupertinoCalendarPicker(
      ctx,
      widgetRenderBox: renderBox,
      initialDateTime: recurrenceEndDate ?? now.add(const Duration(days: 30)),
      minimumDateTime: now,
      maximumDateTime: DateTime(2100),
      currentDateTime: now,
      mode: CupertinoCalendarMode.date,
    );
    if (picked != null) setState(() => recurrenceEndDate = picked);
  }

  // ─── Save ─────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!isValid) return;
    setState(() => isSaving = true);
    try {
      final rule = buildRecurrenceRule();
      final DateTime startDT;
      final DateTime endDT;

      if (repeat) {
        startDT = combineDateAndTime(recurringStartDate, recurringStartTime);
        endDT = combineDateAndTime(recurringStartDate, recurringEndTime);
      } else {
        startDT = combineDateAndTime(date, startTime);
        endDT = combineDateAndTime(date, endTime);
      }

      if (isEditing) {
        final old = widget.lesson!;
        if (old.isRecurring) {
          await deleteLocalLessonSeries(old.recurrenceGroupId!);
        } else {
          await deleteLocalLesson(old.id!);
        }
      }

      await saveLocalLesson(
        name: nameController.text.trim(),
        startDateTime: startDT,
        endDateTime: endDT,
        recurrenceRule: rule,
        recurrenceEndDate: rule != 'NONE' ? recurrenceEndDate : null,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> delete() async {
    final l = widget.lesson!;
    setState(() => isSaving = true);
    try {
      if (l.isRecurring) {
        await deleteLocalLessonSeries(l.recurrenceGroupId!);
      } else {
        await deleteLocalLesson(l.id!);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella cancellazione: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Navigator.of(context).pop,
          icon: const Icon(Icons.close),
        ),
        title: Text(isEditing ? 'Modifica evento' : ''),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: colors.error,
              onPressed: isSaving ? null : delete,
              tooltip: 'Elimina',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              onPressed: isValid && !isSaving ? save : null,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva'),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 16, 16, 16),
            child: TextField(
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              autofocus: true,
              controller: nameController,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400),
              decoration: InputDecoration.collapsed(
                hintText: 'Aggiungi titolo',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colors.onSurface.withOpacity(0.38),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 4),
          IconRow(
            icon: Icons.access_time_outlined,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              sizeCurve: Curves.easeInOut,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              crossFadeState: repeat ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TappableText(
                        text: formatDate(date),
                        onTapWithContext: pickDate,
                      ),
                      const Spacer(),
                      TappableText(
                        text: formatTime(startTime),
                        onTapWithContext: (ctx) => pickTime(ctx, isStart: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      TappableText(
                        text: formatDate(date),
                        onTapWithContext: pickDate,
                        muted: true,
                      ),
                      const Spacer(),
                      TappableText(
                        text: formatTime(endTime),
                        onTapWithContext: (ctx) => pickTime(ctx, isStart: false),
                      ),
                    ],
                  ),
                  if (!timesValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "L'orario di fine deve essere dopo l'inizio.",
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                      ),
                    ),
                ],
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TappableText(
                        text: formatTime(recurringStartTime),
                        onTapWithContext: (ctx) => pickTime(ctx, isStart: true),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('–',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface.withOpacity(0.55),
                            )),
                      ),
                      TappableText(
                        text: formatTime(recurringEndTime),
                        onTapWithContext: (ctx) => pickTime(ctx, isStart: false),
                      ),
                    ],
                  ),
                  if (!timesValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "L'orario di fine deve essere dopo l'inizio.",
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 4),
          IconRow(
            icon: Icons.repeat_outlined,
            trailing: Switch(
              value: repeat,
              onChanged: (bool v) => setState(() {
                repeat = v;
                if (!v) {
                  selectedWeekdays.clear();
                  recurrenceEndDate = null;
                }
              }),
            ),
            child: Text('Si ripete', style: theme.textTheme.bodyLarge),
          ),
          AnimatedReveal(
            visible: repeat,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconRow(
                  icon: Icons.tune_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'DAILY', label: Text('Ogni giorno')),
                          ButtonSegment(value: 'WEEKLY', label: Text('Giorni specifici')),
                        ],
                        selected: {recurrenceType},
                        onSelectionChanged: (Set<String> s) => setState(() => recurrenceType = s.first),
                      ),
                      AnimatedReveal(
                        visible: recurrenceType == 'WEEKLY',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(7, (i) {
                                  final day = i + 1;
                                  final selected = selectedWeekdays.contains(day);
                                  return FilterChip(
                                    label: Text(weekdayLabel(day)),
                                    selected: selected,
                                    onSelected: (bool v) => setState(() {
                                      if (v) {
                                        selectedWeekdays.add(day);
                                      } else {
                                        selectedWeekdays.remove(day);
                                      }
                                    }),
                                  );
                                }),
                              ),
                              if (selectedWeekdays.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Seleziona almeno un giorno.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconRow(
                  icon: Icons.event_available_outlined,
                  child: Row(
                    children: [
                      TappableText(
                        text: recurrenceEndDate != null ? 'Fino al ${formatDateShort(recurrenceEndDate!)}' : 'Nessuna data di fine',
                        onTapWithContext: pickRecurrenceEndDate,
                        muted: recurrenceEndDate == null,
                      ),
                      if (recurrenceEndDate != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => recurrenceEndDate = null),
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(Icons.close, size: 16, color: colors.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
