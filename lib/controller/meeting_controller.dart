import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/meeting_model.dart';
import '../controller/user_controller.dart';

class MeetingController extends GetxController {
  var userMeetings = <Meeting>[].obs;
  var isLoading = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController userController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();
    loadMeetings();
  }

  Future<void> createMeeting(Meeting meeting) async {
    try {
      isLoading.value = true;

      final docRef = await _firestore.collection('meetings').add(meeting.toMap());

      final meetingWithId = meeting.copyWith(id: docRef.id);

      userMeetings.add(meetingWithId);

      Get.snackbar('Success', 'Meeting created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create meeting: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMeeting(Meeting meeting) async {
    try {
      isLoading.value = true;

      await _firestore.collection('meetings').doc(meeting.id).update(meeting.toMap());

      int index = userMeetings.indexWhere((m) => m.id == meeting.id);
      if (index != -1) {
        userMeetings[index] = meeting;
        userMeetings.refresh();
      }

      Get.snackbar('Success', 'Meeting updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update meeting: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('meetings').doc(meetingId).delete();

      userMeetings.removeWhere((meeting) => meeting.id == meetingId);

      Get.snackbar('Success', 'Meeting deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete meeting: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMeetings() async {
    try {
      isLoading.value = true;

      final currentUserId = userController.uid.value;
      if (currentUserId.isEmpty) return;

      final snapshot = await _firestore
          .collection('meetings')
          .where('attendees', arrayContains: currentUserId)
          .orderBy('datetimeUTC')
          .get();

      final meetings = snapshot.docs
          .map((doc) => Meeting.fromFirestore(doc))
          .toList();

      userMeetings.value = meetings;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load meetings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void listenToMeetings() {
    final currentUserId = userController.uid.value;
    if (currentUserId.isEmpty) return;

    _firestore
        .collection('meetings')
        .where('attendees', arrayContains: currentUserId)
        .orderBy('datetimeUTC')
        .snapshots()
        .listen((snapshot) {
      final meetings = snapshot.docs
          .map((doc) => Meeting.fromFirestore(doc))
          .toList();

      userMeetings.value = meetings;
    });
  }

  List<Meeting> get myCreatedMeetings {
    final currentUserId = userController.uid.value;
    return userMeetings.where((meeting) => meeting.createdBy == currentUserId).toList();
  }

  List<Meeting> get upcomingMeetings {
    final now = DateTime.now();
    return userMeetings.where((meeting) => meeting.datetimeUTC.isAfter(now)).toList();
  }

  List<Meeting> get pastMeetings {
    final now = DateTime.now();
    return userMeetings.where((meeting) => meeting.datetimeUTC.isBefore(now)).toList();
  }
}