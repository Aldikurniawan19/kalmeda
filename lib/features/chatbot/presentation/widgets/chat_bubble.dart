import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';

/// Presentation widget rendering user and clinical assistant chat bubbles in WhatsApp aesthetic.
/// Adheres strictly to `aturan-desain.md` (no emojis, cohesive typography, high accessibility contrast).
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final ValueChanged<String>? onChipTapped;
  final void Function(String route, ChatMessageModel message)? onActionTapped;

  const ChatBubble({
    super.key,
    required this.message,
    this.onChipTapped,
    this.onActionTapped,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildBotBubble(context);
    }
  }

  /// Outgoing user bubble styled in Kalmeda soft rose palette with double check marks,
  /// authentic WhatsApp nip corner, and compact content-hugging width.
  Widget _buildUserBubble(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: AppSizes.space8,
          left: 48,
          right: 2,
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 6),
        decoration: BoxDecoration(
          color: AppColors.chatUserBubble,
          border: Border.all(color: AppColors.chatUserBubbleBorder, width: 0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(3), // WhatsApp outgoing nip
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: FormattedMessageView.parseInlineSpans(
                      message.text,
                      baseStyle: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      boldStyle: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Incoming consultant bot bubble styled with Kalmeda clean card, WhatsApp incoming nip, and clinical authority badge.
  Widget _buildBotBubble(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.86;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: AppSizes.space12,
          right: 32,
          left: 2,
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Answer Container
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.chatBotBubble,
                border: Border.all(
                  color: AppColors.chatBotBubbleBorder,
                  width: 0.8,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3), // WhatsApp incoming nip
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Header: Kalmeda primary icon + title + verified badge
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.support_agent_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Konsultan Medis Kalmeda',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Structured Formatted Body Text (Bold words, headers, and numbered/bullet lists)
                  FormattedMessageView(
                    text: message.text,
                  ),

                  // Reassuring Expert Reference & Clinical Authority Card
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chatExpertCardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.chatExpertCardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 15,
                          color: AppColors.chatExpertCardTitle,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Referensi Pakar Terpercaya',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.chatExpertCardTitle,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ditinjau oleh Tim Dokter Spesialis Obstetri & Ginekologi (Sp.OG) berdasarkan standar ilmiah ACOG, POGI, dan Standar Kemenkes RI.',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.35,
                                  color: AppColors.chatExpertCardText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action shortcut button (e.g. Catat Gejala)
                  if (message.actionRoute != null &&
                      message.actionLabel != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            onActionTapped?.call(message.actionRoute!, message),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: Text(message.actionLabel!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primaryLight),
                          backgroundColor: AppColors.primarySoft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Timestamp at bottom right
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Follow-up Suggestion Chips
            if (message.suggestedChips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pertanyaan Terkait:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.suggestedChips.map((chip) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.help_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            chip,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.cardBackground,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onPressed: () => onChipTapped?.call(chip),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders chat bubble text with structured typography:
/// - Inline bold parsing for `**text**`
/// - Clear emphasized section headers (e.g. "Lakukan langkah-langkah berikut:") with subtle primary accent indicator
/// - Structured numbered lists (1., 2., 3.) with soft rounded number pills, bold item titles, and hanging-indent descriptions
/// - Structured bullet lists (•, -) with primary circular dots, bold item titles, and hanging-indent descriptions
/// - Clean paragraph spacing adhering strictly to `aturan-desain.md` (no emojis, cohesive typography)
class FormattedMessageView extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? boldStyle;

  const FormattedMessageView({
    super.key,
    required this.text,
    this.baseStyle,
    this.boldStyle,
  });

  static List<InlineSpan> parseInlineSpans(
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }
      final boldText = match.group(1) ?? '';
      spans.add(TextSpan(
        text: boldText,
        style: boldStyle,
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  bool _isHeaderLine(String line) {
    final clean = line.trim();
    if (clean.isEmpty) return false;

    // Explicit markdown bold header: **Judul:** or **Judul**
    if (clean.startsWith('**') &&
        (clean.endsWith('**') || clean.endsWith(':') || clean.endsWith(':**'))) {
      return true;
    }

    // Markdown H2/H3 syntax
    if (clean.startsWith('### ') || clean.startsWith('## ') || clean.startsWith('# ')) {
      return true;
    }

    final lower = clean.toLowerCase();

    // Clinical question headers: "Kapan sebaiknya memeriksakan diri...?"
    if (lower.startsWith('kapan') && clean.endsWith('?')) return true;

    // Header directives ending with colon
    if (clean.endsWith(':')) {
      if (lower.contains('langkah') ||
          lower.contains('berikut') ||
          lower.contains('penyebab') ||
          lower.contains('tanda') ||
          lower.contains('waspada') ||
          lower.contains('kapan') ||
          lower.contains('disarankan') ||
          lower.contains('anjuran') ||
          lower.contains('faktor') ||
          lower.contains('kondisi ini') ||
          lower.contains('ditemukan pada') ||
          lower.contains('perbedaan') ||
          lower.contains('tips') ||
          lower.contains('mitos') ||
          lower.contains('fakta') ||
          lower.contains('perhatian') ||
          lower.contains('catatan') ||
          lower.contains('rekomendasi') ||
          lower.contains('penanganan')) {
        return true;
      }
    }

    // Directives
    if (lower.startsWith('lakukan langkah') ||
        lower.startsWith('langkah penanganan') ||
        lower.startsWith('rekomendasi medis:') ||
        lower.startsWith('peringatan:') ||
        lower.startsWith('tanda bahaya')) {
      return true;
    }

    return false;
  }

  Widget _buildHeader(String text, TextStyle defaultBold) {
    String cleanText = text.trim();
    cleanText = cleanText.replaceFirst(RegExp(r'^#+\s*'), '');
    cleanText = cleanText.replaceAll('**', '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3, right: 7),
            width: 3.5,
            height: 13.5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              cleanText,
              style: defaultBold.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.35,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(
    String number,
    String content,
    TextStyle defaultBase,
    TextStyle defaultBold,
  ) {
    String title = '';
    String description = content;

    // Detect if content starts with bold markdown: **Title:** or **Title**:
    final boldMatch = RegExp(r'^\s*\*\*(.+?)\*\*\s*(:?)\s*').firstMatch(content);
    if (boldMatch != null) {
      final matchedBold = boldMatch.group(1)!.trim();
      final hasColon = boldMatch.group(2) == ':' || matchedBold.endsWith(':');
      final cleanTitle = matchedBold.replaceAll(RegExp(r':+$'), '').trim();
      title = hasColon ? '$cleanTitle:' : cleanTitle;
      description = content.substring(boldMatch.end).trim();
    } else {
      final colonIndex = content.indexOf(':');
      if (colonIndex != -1 && colonIndex < 50) {
        title = content.substring(0, colonIndex + 1).trim().replaceAll('**', '');
        description = content.substring(colonIndex + 1).trim();
      }
    }

    final spanChildren = <InlineSpan>[];
    if (title.isNotEmpty) {
      spanChildren.add(
        TextSpan(
          text: description.isNotEmpty ? '$title ' : title,
          style: defaultBold.copyWith(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    if (description.isNotEmpty) {
      spanChildren.addAll(
        parseInlineSpans(
          description,
          baseStyle: defaultBase,
          boldStyle: defaultBold,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number indicator pill badge
          Container(
            margin: const EdgeInsets.only(top: 2, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: spanChildren),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    String content,
    TextStyle defaultBase,
    TextStyle defaultBold,
  ) {
    String title = '';
    String description = content;

    // Detect if content starts with bold markdown: **Title:** or **Title**:
    final boldMatch = RegExp(r'^\s*\*\*(.+?)\*\*\s*(:?)\s*').firstMatch(content);
    if (boldMatch != null) {
      final matchedBold = boldMatch.group(1)!.trim();
      final hasColon = boldMatch.group(2) == ':' || matchedBold.endsWith(':');
      final cleanTitle = matchedBold.replaceAll(RegExp(r':+$'), '').trim();
      title = hasColon ? '$cleanTitle:' : cleanTitle;
      description = content.substring(boldMatch.end).trim();
    } else {
      final colonIndex = content.indexOf(':');
      if (colonIndex != -1 && colonIndex < 50) {
        title = content.substring(0, colonIndex + 1).trim().replaceAll('**', '');
        description = content.substring(colonIndex + 1).trim();
      }
    }

    final spanChildren = <InlineSpan>[];
    if (title.isNotEmpty) {
      spanChildren.add(
        TextSpan(
          text: description.isNotEmpty ? '$title ' : title,
          style: defaultBold.copyWith(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    if (description.isNotEmpty) {
      spanChildren.addAll(
        parseInlineSpans(
          description,
          baseStyle: defaultBase,
          boldStyle: defaultBold,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8, left: 3),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: spanChildren),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(
    String text,
    TextStyle defaultBase,
    TextStyle defaultBold,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: parseInlineSpans(
            text,
            baseStyle: defaultBase,
            boldStyle: defaultBold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultBase = baseStyle ??
        const TextStyle(
          fontSize: 13.5,
          height: 1.48,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
        );

    final defaultBold = boldStyle ??
        const TextStyle(
          fontSize: 13.5,
          height: 1.48,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (widgets.isNotEmpty && widgets.last is! SizedBox) {
          widgets.add(const SizedBox(height: 4));
        }
        continue;
      }

      // 1. Numbered item: "1. ...", "2) ..."
      final numberedMatch = RegExp(r'^(\d+)[\.\)]\s+(.+)').firstMatch(line);
      if (numberedMatch != null) {
        final number = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!;
        widgets.add(_buildNumberedItem(number, content, defaultBase, defaultBold));
        continue;
      }

      // 2. Bullet item: "• ...", "- ..."
      final bulletMatch = RegExp(r'^[•\-\*]\s+(.+)').firstMatch(line);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!;
        widgets.add(_buildBulletItem(content, defaultBase, defaultBold));
        continue;
      }

      // 3. Section header
      if (_isHeaderLine(line)) {
        widgets.add(_buildHeader(line, defaultBold));
        continue;
      }

      // 4. Normal paragraph
      widgets.add(_buildParagraph(line, defaultBase, defaultBold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
