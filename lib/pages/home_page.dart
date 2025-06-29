import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/meeting_controller.dart';
import 'add_meeting_page.dart';
import 'time_collision_page.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final MeetingController meetingController = Get.find<MeetingController>();

  bool meetingsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  // Fixed: Pass meetings as parameter instead of accessing observable inside
  Map<String, List<String>> getMeetingConflicts(List meetings) {
    Map<String, List<String>> conflicts = {};
    Duration meetingDuration = Duration(hours: 1);

    for (int i = 0; i < meetings.length; i++) {
      for (int j = i + 1; j < meetings.length; j++) {
        DateTime start1 = meetings[i].datetimeUTC.toLocal();
        DateTime end1 = start1.add(meetingDuration);

        DateTime start2 = meetings[j].datetimeUTC.toLocal();
        DateTime end2 = start2.add(meetingDuration);

        if (meetingsOverlap(start1, end1, start2, end2)) {
          conflicts.putIfAbsent(meetings[i].id, () => []).add(meetings[j].id);
          conflicts.putIfAbsent(meetings[j].id, () => []).add(meetings[i].id);
        }
      }
    }

    return conflicts;
  }

  void launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'Error',
        'Could not open the link',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7F00FF);

    return Scaffold(
      appBar: AppBar(
        title: Text("Taalmel"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            tooltip: 'View Timezone Collisions',
            onPressed: () {
              Get.to(() => CollisionVisualizationPage());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add),
        onPressed: () {
          Get.to(() => AddMeetingPage());
        },
      ),
      body: Obx(() {
        final meetings = meetingController.userMeetings;

        if (meetings.isEmpty) {
          return Center(child: Text("No meetings scheduled"));
        }

        // Fixed: Pass meetings to the function instead of accessing observable again
        final conflicts = getMeetingConflicts(meetings);

        return ListView.builder(
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final localTime = meeting.datetimeUTC.toLocal();
            final formattedTime = DateFormat('EEE, MMM d, h:mm a').format(localTime);
            final isConflicted = conflicts.containsKey(meeting.id);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(meeting.title),
                subtitle: Text("Time: $formattedTime\nAttendees: ${meeting.attendees.length}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConflicted)
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    if (meeting.meetLink.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.link),
                        onPressed: () => launchURL(meeting.meetLink),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}