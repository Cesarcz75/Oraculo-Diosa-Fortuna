class AthenaResponse {
  const AthenaResponse({
    required this.title,
    required this.summary,
    required this.details,
    required this.category,
  });

  final String title;
  final String summary;
  final List<String> details;
  final String category;
}
