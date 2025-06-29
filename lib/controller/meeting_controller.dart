import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Create a meeting in Firestore
  Future<void> createMeeting(Meeting meeting) async {
    try {
      isLoading.value = true;

      // Create meeting document in Firestore
      final docRef = await _firestore.collection('meetings').add(meeting.toMap());

      // Create meeting with the generated ID
      final meetingWithId = meeting.copyWith(id: docRef.id);

      // Add to local list
      userMeetings.add(meetingWithId);

      Get.snackbar('Success', 'Meeting created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create meeting: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update meeting in Firestore
  Future<void> updateMeeting(Meeting meeting) async {
    try {
      isLoading.value = true;

      // Update in Firestore
      await _firestore.collection('meetings').doc(meeting.id).update(meeting.toMap());

      // Update in local list
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

  // Delete meeting from Firestore
  Future<void> deleteMeeting(String meetingId) async {
    try {
      isLoading.value = true;

      // Delete from Firestore
      await _firestore.collection('meetings').doc(meetingId).delete();

      // Remove from local list
      userMeetings.removeWhere((meeting) => meeting.id == meetingId);

      Get.snackbar('Success', 'Meeting deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete meeting: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load meetings where current user is an attendee
  Future<void> loadMeetings() async {
    try {
      isLoading.value = true;

      final currentUserId = userController.uid.value;
      if (currentUserId.isEmpty) return;

      // Query meetings where current user is an attendee
      final snapshot = await _firestore
          .collection('meetings')
          .where('attendees', arrayContains: currentUserId)
          .orderBy('datetimeUTC')
          .get();

      // Convert documents to Meeting objects
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

  // Set up real-time listener for meetings
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

  // Get meetings created by current user
  List<Meeting> get myCreatedMeetings {
    final currentUserId = userController.uid.value;
    return userMeetings.where((meeting) => meeting.createdBy == currentUserId).toList();
  }

  // Get upcoming meetings
  List<Meeting> get upcomingMeetings {
    final now = DateTime.now();
    return userMeetings.where((meeting) => meeting.datetimeUTC.isAfter(now)).toList();
  }

  // Get past meetings
  List<Meeting> get pastMeetings {
    final now = DateTime.now();
    return userMeetings.where((meeting) => meeting.datetimeUTC.isBefore(now)).toList();
  }
}