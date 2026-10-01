/// Model representing structured clinical FAQ knowledge entries.
class FaqKnowledgeModel {
  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> relatedChips;
  final String? actionRoute;
  final String? actionLabel;

  const FaqKnowledgeModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.keywords,
    this.relatedChips = const [],
    this.actionRoute,
    this.actionLabel,
  });
}
