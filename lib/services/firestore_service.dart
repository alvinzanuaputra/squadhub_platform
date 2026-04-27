import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ScheduleModel>> getSchedules() {
    return _db
        .collection('schedules')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      await _db
          .collection('schedules')
          .add(schedule.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      await _db
          .collection('schedules')
          .doc(schedule.id)
          .update(schedule.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _db
          .collection('schedules')
          .doc(id)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
