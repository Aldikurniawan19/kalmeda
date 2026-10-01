import 'package:flutter/foundation.dart';

/// Singleton service managing prefilled record drafts transferred from the clinical consultation feature.
class RecordDraftService extends ChangeNotifier {
  static final RecordDraftService _instance = RecordDraftService._internal();
  factory RecordDraftService() => _instance;
  RecordDraftService._internal();

  String? _pendingNote;
  Set<int> _pendingSymptoms = {};

  String? get pendingNote => _pendingNote;
  Set<int> get pendingSymptoms => Set.unmodifiable(_pendingSymptoms);
  bool get hasPendingDraft => _pendingNote != null || _pendingSymptoms.isNotEmpty;

  /// Sets the draft note and symptoms to be consumed by RecordScreen.
  void setDraft({required String note, Set<int>? symptoms}) {
    _pendingNote = note.trim();
    _pendingSymptoms = symptoms != null ? Set<int>.from(symptoms) : {};
    notifyListeners();
  }

  /// Consumes the pending draft if present and clears the pending state.
  void consumeDraft(void Function(String note, Set<int> symptoms) onApply) {
    if (hasPendingDraft) {
      final note = _pendingNote ?? '';
      final symptoms = Set<int>.from(_pendingSymptoms);
      _pendingNote = null;
      _pendingSymptoms.clear();
      onApply(note, symptoms);
    }
  }

  /// Clears any pending draft without applying.
  void clear() {
    _pendingNote = null;
    _pendingSymptoms.clear();
  }
}
