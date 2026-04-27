import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/auth_controller.dart';
import 'controllers/media_controller.dart';
import 'controllers/note_controller.dart';
import 'controllers/schedule_controller.dart';
import 'models/note_model.dart';
import 'models/note_tag_model.dart';
import 'services/fcm_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_routes.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('id_ID', null);

  final dir = await getApplicationDocumentsDirectory();

  // One-time migration: delete old corrupted Isar database
  // This runs only once to fix blank notes caused by schema mismatch
  final prefs = await SharedPreferences.getInstance();
  final hasReset = prefs.getBool('isar_db_reset_v1') ?? false;
  if (!hasReset) {
    final dbFile = File('${dir.path}/squadhub_db.isar');
    final dbLock = File('${dir.path}/squadhub_db.isar.lock');
    if (dbFile.existsSync()) dbFile.deleteSync();
    if (dbLock.existsSync()) dbLock.deleteSync();
    await prefs.setBool('isar_db_reset_v1', true);
  }

  final isar = await Isar.open(
    [NoteModelSchema, NoteTagModelSchema],
    directory: dir.path,
    name: 'squadhub_db',
  );

  await FcmService.initialize();

  runApp(SquadHubApp(isar: isar));
}

class SquadHubApp extends StatelessWidget {
  final Isar isar;

  const SquadHubApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(isar)),
        ChangeNotifierProvider(create: (_) => ScheduleController()),
        ChangeNotifierProvider(create: (_) => NoteController(isar)),
        ChangeNotifierProvider(create: (_) => MediaController()),
      ],
      child: MaterialApp(
        title: 'SquadHub',
        debugShowCheckedModeBanner: false,
        theme: AppColors.darkTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
