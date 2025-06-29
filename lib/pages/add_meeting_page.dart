import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/meeting_controller.dart';
import '../models/meeting_model.dart';

class AddMeetingPage extends StatefulWidget {
  const AddMeetingPage({Key? key}) : super(key: key);

  @override
  State<AddMeetingPage> createState() => _AddMeetingPageState();
}

class _AddMeetingPageState extends State<AddMeetingPage> {
  final titleController = TextEditingController();
  final linkController = TextEditingController();
  final attendeesController = TextEditingController();
  DateTime? selectedDateTime;

  final meetingController = Get.find<MeetingController>();
  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  Future<void> createMeeting() async {
    setState(() => loading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final usernames = attendeesController.text
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();

    final attendeesIds = <String>[];
    for (final username in usernames) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        attendeesIds.add(snapshot.docs.first.id);
      }
    }

    if (!attendeesIds.contains(currentUser.uid)) {
      attendeesIds.add(currentUser.uid);
    }

    final meeting = Meeting(
      id: '',
      title: titleController.text.trim(),
      datetimeUTC: selectedDateTime!.toUtc(),
      createdBy: currentUser.uid,
      attendees: attendeesIds,
      meetLink: linkController.text.trim(),
    );

    await meetingController.createMeeting(meeting);

    setState(() => loading = false);

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7F00FF);
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Meeting"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Meeting Title'),
                validator: (val) => val!.isEmpty ? "Title required" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: attendeesController,
                decoration: InputDecoration(
                  labelText: 'Attendees (comma-separated usernames)',
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: linkController,
                decoration: InputDecoration(labelText: 'Meeting Link (optional)'),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    selectedDateTime == null
                        ? "Pick date & time"
                        : "${selectedDateTime!.toLocal()}",
                    style: TextStyle(fontSize: 16),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text("Pick"),
                  ),
                ],
              ),
              SizedBox(height: 30),
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedDateTime != null) {
                    createMeeting();
                  }
                },
                child: Text("Create Meeting"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding:
                  EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
