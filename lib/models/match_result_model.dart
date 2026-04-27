class MatchResultModel {
  final String id;
  final String status;
  final String imagePath;
  final String note;
  final DateTime dateTime;

  const MatchResultModel({
    required this.id,
    required this.status,
    required this.imagePath,
    required this.note,
    required this.dateTime,
  });
}
