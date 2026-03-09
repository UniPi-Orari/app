import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/ui/pages/create_event.dart';

class Event extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback? onEdited;

  const Event({
    super.key,
    required this.lesson,
    this.onEdited,
  });

  @override
  State<Event> createState() => EventState();
}

class EventState extends State<Event> {
  Future<void> _openEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventPage(lesson: widget.lesson),
      ),
    );
    widget.onEdited?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: widget.lesson.isLocal
          ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.45)
          : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.45),
      shadowColor: Colors.transparent,
      child: ListTile(
        onTap: widget.lesson.isLocal ? _openEdit : null,
        title: Text(
          widget.lesson.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${DateFormat('HH:mm').format(widget.lesson.startDateTime)} - ${DateFormat('HH:mm').format(widget.lesson.endDateTime)}',
        ),
        leading: CircleAvatar(
          child: Text(
            widget.lesson.roomName.replaceAll("Fib ", "").replaceAll("-Lab", ""),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              widget.lesson.isLocal ? "Modifica" : (widget.lesson.courseName ?? "Nessun corso"),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(
                          0.5,
                        ),
                  ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
