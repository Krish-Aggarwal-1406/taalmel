import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/meeting_controller.dart';
import '../models/meeting_model.dart';

class CollisionVisualizationPage extends StatelessWidget {
  CollisionVisualizationPage({Key? key}) : super(key: key);

  final MeetingController meetingController = Get.find<MeetingController>();

  bool meetingsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  Map<String, List<String>> getMeetingConflicts(List<Meeting> meetings) {
    Map<String, List<String>> conflicts = {};
    Duration duration = Duration(hours: 1);

    for (int i = 0; i < meetings.length; i++) {
      for (int j = i + 1; j < meetings.length; j++) {
        final m1 = meetings[i];
        final m2 = meetings[j];

        DateTime start1 = m1.datetimeUTC.toLocal();
        DateTime end1 = start1.add(duration);

        DateTime start2 = m2.datetimeUTC.toLocal();
        DateTime end2 = start2.add(duration);

        if (meetingsOverlap(start1, end1, start2, end2)) {
          conflicts.putIfAbsent(m1.id, () => []).add(m2.id);
          conflicts.putIfAbsent(m2.id, () => []).add(m1.id);
        }
      }
    }
    return conflicts;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7F00FF);

    return Scaffold(
      appBar: AppBar(
        title: Text("Timezone Collision Visualization"),
        backgroundColor: primaryColor,
      ),
      body: Obx(() {
        final meetings = meetingController.userMeetings;

        if (meetings.isEmpty) {
          return Center(child: Text("No meetings scheduled"));
        }

        final conflicts = getMeetingConflicts(meetings);

        return ListView.builder(
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final localStart = meeting.datetimeUTC.toLocal();
            final formattedTime = DateFormat('EEE, MMM d, h:mm a').format(localStart);
            final isConflicted = conflicts.containsKey(meeting.id);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isConflicted ? Colors.red.shade100 : Colors.green.shade100,
              child: ListTile(
                title: Text(meeting.title),
                subtitle: Text("Time: $formattedTime\nAttendees: ${meeting.attendees.length}"),
                trailing: isConflicted
                    ? Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28)
                    : Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
            );
          },
        );
      }),
    );
  }
}
