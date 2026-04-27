import 'package:isar/isar.dart';
import '../models/note_model.dart';
import '../models/note_tag_model.dart';

class IsarService {
  final Isar _isar;

  IsarService(this._isar);

  Stream<List<NoteModel>> watchNotes() {
    return _isar.noteModels.where().watch(fireImmediately: true);
  }

  Future<void> addNote(NoteModel note) async {
    await _isar.writeTxn(() async {
      await _isar.noteModels.put(note);
    });
  }

  Future<void> updateNote(NoteModel note) async {
    await _isar.writeTxn(() async {
      await _isar.noteModels.put(note);
    });
  }

  Future<void> deleteNote(int id) async {
    await _isar.writeTxn(() async {
      await _isar.noteModels.delete(id);
    });
  }

  Future<int> countNotes() async {
    return await _isar.noteModels.count();
  }

  Future<void> addTag(NoteTagModel tag) async {
    await _isar.writeTxn(() async {
      await _isar.noteTagModels.put(tag);
    });
  }

  Future<List<NoteTagModel>> getTagsByNoteId(int noteId) async {
    return await _isar.noteTagModels
        .filter()
        .noteIdEqualTo(noteId)
        .findAll();
  }

  Future<void> deleteTag(int tagId) async {
    await _isar.writeTxn(() async {
      await _isar.noteTagModels.delete(tagId);
    });
  }

  Future<void> deleteTagsByNoteId(int noteId) async {
    final tags = await getTagsByNoteId(noteId);
    final ids = tags.map((t) => t.id).toList();
    await _isar.writeTxn(() async {
      await _isar.noteTagModels.deleteAll(ids);
    });
  }

  Stream<List<NoteTagModel>> watchTagsByNoteId(int noteId) {
    return _isar.noteTagModels
        .filter()
        .noteIdEqualTo(noteId)
        .watch(fireImmediately: true);
  }
}
