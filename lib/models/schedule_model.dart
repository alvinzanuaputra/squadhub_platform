import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String game;
  final String description;
  final DateTime dateTime;
  final List<String> members;
  final String createdBy;

  const ScheduleModel({
    required this.id,
    required this.game,
    required this.description,
    required this.dateTime,
    required this.members,
    required this.createdBy,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      game: data['game'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] as List? ?? []),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'game': game,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'members': members,
      'createdBy': createdBy,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? game,
    String? description,
    DateTime? dateTime,
    List<String>? members,
    String? createdBy,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      game: game ?? this.game,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
