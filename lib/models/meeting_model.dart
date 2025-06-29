import 'package:cloud_firestore/cloud_firestore.dart';

class Meeting {
  final String id;
  final String title;
  final DateTime datetimeUTC;
  final String createdBy;
  final List<String> attendees;
  final String meetLink;

  Meeting({
    required this.id,
    required this.title,
    required this.datetimeUTC,
    required this.createdBy,
    required this.attendees,
    required this.meetLink,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Meeting(
      id: doc.id,
      title: data['title'] ?? '',
      datetimeUTC: (data['datetimeUTC'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      meetLink: data['meetLink'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'datetimeUTC': Timestamp.fromDate(datetimeUTC),
      'createdBy': createdBy,
      'attendees': attendees,
      'meetLink': meetLink,
    };
  }

  Meeting copyWith({
    String? id,
    String? title,
    DateTime? datetimeUTC,
    String? createdBy,
    List<String>? attendees,
    String? meetLink,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      datetimeUTC: datetimeUTC ?? this.datetimeUTC,
      createdBy: createdBy ?? this.createdBy,
      attendees: attendees ?? this.attendees,
      meetLink: meetLink ?? this.meetLink,
    );
  }
}
