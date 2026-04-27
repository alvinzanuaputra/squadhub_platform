import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/match_result_model.dart';

class MediaController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  final List<MatchResultModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchResultModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<void> pickAndAddResult({
    required String status,
    required String note,
    required ImageSource source,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final result = MatchResultModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          status: status,
          imagePath: image.path,
          note: note,
          dateTime: DateTime.now(),
        );
        _results.insert(0, result);
        _errorMessage = null;
      }
    } catch (e) {
      final errMsg = e.toString().toLowerCase();
      if (errMsg.contains('permission')) {
        _errorMessage =
            'Izin kamera/galeri ditolak. Buka Pengaturan → Izin Aplikasi.';
      } else {
        _errorMessage = 'Gagal mengambil foto: $e';
      }
      // ignore: avoid_print
      print('Media picker error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
