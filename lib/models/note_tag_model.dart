import 'package:isar/isar.dart';

part 'note_tag_model.g.dart';

@collection
class NoteTagModel {
  Id id = Isar.autoIncrement;

  late int noteId;

  late String heroName;

  late String role;

  late String game;

  late DateTime createdAt;
}
