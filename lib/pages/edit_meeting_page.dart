import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/meeting_controller.dart';
import '../models/meeting_model.dart';

class EditMeetingPage extends StatefulWidget {
  final Meeting meeting;

  const EditMeetingPage({required this.meeting, Key? key}) : super(key: key);

  @override
  State<EditMeetingPage> createState() => _EditMeetingPageState();
}

class _EditMeetingPageState extends State<EditMeetingPage> {
  late TextEditingController titleController;
  late TextEditingController linkController;
  late TextEditingController attendeesController;
  DateTime? selectedDateTime;

  final meetingController = Get.find<MeetingController>();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.meeting.title);
    linkController = TextEditingController(text: widget.meeting.meetLink);
    attendeesController = TextEditingController(text: ''); // Optional: format attendees usernames if needed
    selectedDateTime = widget.meeting.datetimeUTC.toLocal();
  }

  Future<void> updateMeeting() async {
    setState(() => loading = true);

    final updatedMeeting = widget.meeting.copyWith(
      title: titleController.text.trim(),
      meetLink: linkController.text.trim(),
      datetimeUTC: selectedDateTime!.toUtc(),
    );

    await meetingController.updateMeeting(updatedMeeting);

    setState(() => loading = false);

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7F00FF);

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Meeting"),
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
                        initialDate: selectedDateTime ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
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
                    updateMeeting();
                  }
                },
                child: Text("Update Meeting"),
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
