import 'dart:async';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/firestore_service.dart';

class ScheduleController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  StreamSubscription? _subscription;

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ScheduleModel? get nearestSchedule {
    final upcoming = _schedules.where(
      (s) => s.dateTime.isAfter(DateTime.now())
    ).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.first;
  }

  void listenSchedules() {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.getSchedules().listen(
      (data) {
        _schedules = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addSchedule({
    required String game,
    required String description,
    required DateTime dateTime,
    required List<String> members,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final schedule = ScheduleModel(
        id: '',
        game: game,
        description: description,
        dateTime: dateTime,
        members: members,
        createdBy: createdBy,
      );

      await _service.addSchedule(schedule);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.updateSchedule(schedule);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _service.deleteSchedule(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
