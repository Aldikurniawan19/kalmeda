/// Model representing an individual message within the Kalmeda Chatbot conversation.
class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestedChips;
  final String? actionRoute;
  final String? actionLabel;
  final String? recordNote;
  final List<int>? symptomIndices;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedChips = const [],
    this.actionRoute,
    this.actionLabel,
    this.recordNote,
    this.symptomIndices,
  });

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<String>? suggestedChips,
    String? actionRoute,
    String? actionLabel,
    String? recordNote,
    List<int>? symptomIndices,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      suggestedChips: suggestedChips ?? this.suggestedChips,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      recordNote: recordNote ?? this.recordNote,
      symptomIndices: symptomIndices ?? this.symptomIndices,
    );
  }
}
