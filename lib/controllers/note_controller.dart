import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/note_model.dart';
import '../models/note_tag_model.dart';
import '../services/isar_service.dart';
import '../utils/app_constants.dart';

class NoteController extends ChangeNotifier {
  late final IsarService _isarService;
  StreamSubscription<List<NoteModel>>? _subscription;

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Semua';
  final Map<int, List<NoteTagModel>> _tagsMap = {};

  NoteController(Isar isar) {
    _isarService = IsarService(isar);
    _listenNotes();
  }

  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => AppConstants.categoryList;

  List<NoteModel> get filteredNotes {
    if (_selectedCategory == 'Semua') return _notes;
    return _notes
        .where((n) => n.category == _selectedCategory)
        .toList();
  }

  List<NoteTagModel> getTagsForNote(int noteId) {
    return _tagsMap[noteId] ?? [];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _listenNotes() {
    _subscription?.cancel();
    _subscription = _isarService.watchNotes().listen(
      (notes) {
        _notes = notes;
        notifyListeners();
      },
      onError: (e) {
        _setError('Gagal memuat catatan: ${e.toString()}');
      },
    );
  }

  Future<void> addNote({
    required String title,
    required String content,
    required String category,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      final note = NoteModel()
        ..title = title
        ..content = content
        ..category = category
        ..createdAt = DateTime.now();
      await _isarService.addNote(note);
    } catch (e) {
      _setError('Gagal menambah catatan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNote(NoteModel note) async {
    _setError(null);
    if (note.id == 0) {
      _setError('Error: ID catatan tidak valid (0)');
      return;
    }
    _setLoading(true);
    try {
      await _isarService.updateNote(note);
    } catch (e) {
      _setError('Gagal memperbarui catatan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNote(int id) async {
    _setError(null);
    _setLoading(true);
    try {
      await _isarService.deleteTagsByNoteId(id);
      await _isarService.deleteNote(id);
      _tagsMap.remove(id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTagsForNote(int noteId) async {
    final tags = await _isarService.getTagsByNoteId(noteId);
    _tagsMap[noteId] = tags;
  }

  Future<void> loadTagsForNote(int noteId) async {
    await _loadTagsForNote(noteId);
    notifyListeners();
  }

  Future<void> addTag({
    required int noteId,
    required String heroName,
    required String role,
    required String game,
  }) async {
    try {
      final tag = NoteTagModel()
        ..noteId = noteId
        ..heroName = heroName
        ..role = role
        ..game = game
        ..createdAt = DateTime.now();
      await _isarService.addTag(tag);
      await _loadTagsForNote(noteId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTag(int tagId, int noteId) async {
    try {
      await _isarService.deleteTag(tagId);
      await _loadTagsForNote(noteId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
