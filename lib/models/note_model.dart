import 'package:isar/isar.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;
  late String title;
  late String content;
  late String category;
  late DateTime createdAt;
}
