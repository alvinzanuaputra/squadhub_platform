import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import '../models/note_model.dart';
import '../models/note_tag_model.dart';
import '../models/schedule_model.dart';
import '../utils/app_constants.dart';

class SeedService {
  final Isar _isar;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SeedService(this._isar);

  Future<void> seedAll(String userId) async {
    await _seedSchedules(userId);
    await _seedNotes();
    await _seedTags();
  }

  Future<void> _seedSchedules(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.collectionSchedules)
          .where('createdBy', isEqualTo: userId)
          .limit(1)
          .get();

      // Only seed if no schedules exist for this user
      if (snapshot.docs.isNotEmpty) return;

      final now = DateTime.now();
      final schedules = [
        ScheduleModel(
          id: '',
          game: 'Mobile Legends',
          description: 'Ranked push Mythic bareng squad',
          dateTime: now.add(const Duration(hours: 2)),
          members: ['Rizky', 'Budi', 'Citra', 'Doni', 'Eka'],
          createdBy: userId,
        ),
        ScheduleModel(
          id: '',
          game: 'Free Fire',
          description: 'Custom room tournament preparation',
          dateTime: now.add(const Duration(days: 1)),
          members: ['Rizky', 'Budi', 'Citra'],
          createdBy: userId,
        ),
        ScheduleModel(
          id: '',
          game: 'PUBG Mobile',
          description: 'Latihan rotasi zone endgame',
          dateTime: now.add(const Duration(days: 3)),
          members: ['Rizky', 'Doni', 'Eka'],
          createdBy: userId,
        ),
        ScheduleModel(
          id: '',
          game: 'Mobile Legends',
          description: 'Draft pick practice sebelum turnamen',
          dateTime: now.add(const Duration(days: 7)),
          members: ['Rizky', 'Budi', 'Citra', 'Doni'],
          createdBy: userId,
        ),
      ];

      for (final schedule in schedules) {
        await _db
            .collection(AppConstants.collectionSchedules)
            .add(schedule.toMap());
      }
    } catch (_) {
      // Silently fail seeding
    }
  }

  Future<void> _seedNotes() async {
    try {
      final count = await _isar.noteModels.count();
      if (count > 0) return;

      final now = DateTime.now();
      final notes = [
        NoteModel()
          ..title = 'Counter Franco ML'
          ..content =
              'Franco lemah terhadap hero yang punya escape atau CC counter. Gunakan Kagura, Lunox, atau Lancelot untuk counter pick.\n\n- Kagura: umbrella untuk escape dari hook\n- Lunox: fase dark untuk immunity\n- Lancelot: skill 1 untuk menghindari hook'
          ..category = 'Hero Counter'
          ..createdAt = now.subtract(const Duration(days: 5)),
        NoteModel()
          ..title = 'Rotasi Zone PUBG'
          ..content =
              'Tips rotasi zone yang aman:\n1. Selalu cek minimap setiap 30 detik\n2. Prioritaskan vehicle jika zone jauh\n3. Masuk zone dari sisi yang paling sepi\n4. Jangan tunggu zone shrink terlalu kecil\n5. Komunikasi dengan tim saat rotasi'
          ..category = 'Strategi'
          ..createdAt = now.subtract(const Duration(days: 4)),
        NoteModel()
          ..title = 'Draft ML Tournament'
          ..content =
              'Setup draft untuk format best of 3:\n\nBan priority: Moskov, Julian, Estes (support kuat)\nPick 1: Roamer (Khufra/Atlas)\nPick 2: Gold lane (Melissa/Brody)\nPick 3: Jungle (Lesley/Fanny)\n\nFlexible picks: Phoveus, Xavier, Beatrix'
          ..category = 'Draft'
          ..createdAt = now.subtract(const Duration(days: 3)),
        NoteModel()
          ..title = 'Tips Warming Up Sebelum Mabar'
          ..content =
              'Rutinitas warming up 15 menit:\n1. Latihan aim di training mode (5 menit)\n2. Custom mode 1v1 dengan teammate (5 menit)\n3. Review hero yang akan dipakai (3 menit)\n4. Cek koneksi dan setup device (2 menit)\n\nJangan lupa stretch jari!'
          ..category = 'Umum'
          ..createdAt = now.subtract(const Duration(days: 2)),
        NoteModel()
          ..title = 'Counter Fanny ML'
          ..content =
              'Fanny hard counter picks:\n- Kaja: ultimate bisa nab Fanny dari udara\n- Diggie: ultimate memberikan immunity ke tim\n- Saber: ultimate lock Fanny sempurna\n- Atlas: fatal links + ultimate combo\n\nItem counter: Dominance Ice untuk slow attack speed'
          ..category = 'Hero Counter'
          ..createdAt = now.subtract(const Duration(days: 1)),
      ];

      await _isar.writeTxn(() async {
        for (final note in notes) {
          await _isar.noteModels.put(note);
        }
      });
    } catch (_) {
      // Silently fail seeding
    }
  }

  Future<void> _seedTags() async {
    try {
      final existingTags = await _isar.noteTagModels.where().findAll();
      if (existingTags.isNotEmpty) return;

      final notes = await _isar.noteModels.where().findAll();
      if (notes.isEmpty) return;

      final Map<String, List<Map<String, String>>> tagData = {
        'Counter Franco ML': [
          {'hero': 'Natalia', 'role': 'Assassin', 'game': 'Mobile Legends'},
          {'hero': 'Kagura', 'role': 'Mage', 'game': 'Mobile Legends'},
          {'hero': 'Lancelot', 'role': 'Assassin', 'game': 'Mobile Legends'},
        ],
        'Draft ML Tournament': [
          {'hero': 'Tigreal', 'role': 'Tank', 'game': 'Mobile Legends'},
          {'hero': 'Kadita', 'role': 'Mage', 'game': 'Mobile Legends'},
          {'hero': 'Pharsa', 'role': 'Mage', 'game': 'Mobile Legends'},
        ],
        'Counter Fanny ML': [
          {'hero': 'Kaja', 'role': 'Support', 'game': 'Mobile Legends'},
          {'hero': 'Diggie', 'role': 'Support', 'game': 'Mobile Legends'},
          {'hero': 'Nana', 'role': 'Mage', 'game': 'Mobile Legends'},
        ],
      };

      for (var note in notes) {
        if (tagData.containsKey(note.title)) {
          final tags = tagData[note.title]!;
          for (var tagInfo in tags) {
            final tag = NoteTagModel()
              ..noteId = note.id
              ..heroName = tagInfo['hero']!
              ..role = tagInfo['role']!
              ..game = tagInfo['game']!
              ..createdAt = DateTime.now();
            await _isar.writeTxn(() async {
              await _isar.noteTagModels.put(tag);
            });
          }
        }
      }
    } catch (_) {
      // Silently fail seeding
    }
  }
}
