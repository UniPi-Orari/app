import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipi_orario/entities/lesson.dart';

class Event extends StatefulWidget {
  final Lesson lesson;
  const Event({
    super.key,
    required this.lesson,
  });

  @override
  State<Event> createState() => EventState();
}

class EventState extends State<Event> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.45),
      shadowColor: Colors.transparent,
      child: ListTile(
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
              widget.lesson.courseName ?? "Nessun corso",
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
