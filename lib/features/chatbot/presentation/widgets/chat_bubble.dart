import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';
import 'package:menstracker/features/chatbot/presentation/widgets/chat_message_entrance.dart';

/// Presentation widget rendering user and clinical assistant chat bubbles in WhatsApp aesthetic.
/// Adheres strictly to `aturan-desain.md` (no emojis, cohesive typography, high accessibility contrast).
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final ValueChanged<String>? onChipTapped;
  final void Function(String route, ChatMessageModel message)? onActionTapped;

  /// When true, follow-up chips pop in one after another.
  final bool isNew;

  const ChatBubble({
    super.key,
    required this.message,
    this.onChipTapped,
    this.onActionTapped,
    this.isNew = false,
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
              // Voice Note Player Header (if voice note)
              if (message.isVoiceNote) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Waveform lines visualizer
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(14, (i) {
                        final heights = [6.0, 12.0, 16.0, 8.0, 18.0, 14.0, 20.0, 10.0, 15.0, 8.0, 14.0, 18.0, 10.0, 6.0];
                        return Container(
                          width: 2.2,
                          height: heights[i % heights.length],
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.voiceDurationSeconds != null
                          ? '0:${message.voiceDurationSeconds.toString().padLeft(2, '0')}'
                          : '0:07',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: AppColors.chatUserBubbleBorder),
                const SizedBox(height: 4),
              ],

              // Message / Transcript Text
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
                  // Sender Header: Kalmeda title + verified badge
                  Row(
                    children: const [
                      Text(
                        'Konsultan Medis Kalmeda',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Structured Formatted Body Text (Bold words, headers, and numbered/bullet lists)
                  FormattedMessageView(text: message.text),

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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pertanyaan Terkait:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.suggestedChips.asMap().entries.map((
                        entry,
                      ) {
                        final chip = entry.value;
                        return StaggeredPopIn(
                          index: entry.key,
                          animate: isNew,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onChipTapped?.call(chip),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.8,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_right_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    Flexible(
                                      child: Text(
                                        chip,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
/// - Inline bold parsing for `**text**`, `*text*`, `***text***`, and `__text__`
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

  /// Strips any stray or unclosed asterisk characters from plain text chunks.
  static String _cleanResidualAsterisks(String s) {
    return s.replaceAll('*', '');
  }

  /// Parses inline markdown / WhatsApp text formatting (*bold*, **bold**, ***bold-italic***, __bold__, _italic_)
  /// into styled TextSpans without leaking literal asterisk symbols into the UI.
  static List<InlineSpan> parseInlineSpans(
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    if (text.isEmpty) return const [];

    final spans = <InlineSpan>[];

    // Priority ordered regex matching:
    // Group 1 & 2: ***bold-italic***
    // Group 3 & 4: **bold**
    // Group 5 & 6: *bold* (WhatsApp style single-asterisk bold / italic)
    // Group 7 & 8: __bold__
    // Group 9 & 10: _italic_
    final inlineRegex = RegExp(
      r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*([^\*\n]+?)\*)|(__([^_]+?)__)|(_([^_]+?)_)',
    );

    int lastMatchEnd = 0;

    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        final rawNormal = text.substring(lastMatchEnd, match.start);
        final cleanNormal = _cleanResidualAsterisks(rawNormal);
        if (cleanNormal.isNotEmpty) {
          spans.add(TextSpan(text: cleanNormal, style: baseStyle));
        }
      }

      if (match.group(1) != null) {
        // ***bold-italic***
        final boldItalicText = _cleanResidualAsterisks(match.group(2) ?? '');
        if (boldItalicText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: boldItalicText,
              style: boldStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          );
        }
      } else if (match.group(3) != null) {
        // **bold**
        final boldContent = _cleanResidualAsterisks(match.group(4) ?? '');
        if (boldContent.isNotEmpty) {
          spans.add(TextSpan(text: boldContent, style: boldStyle));
        }
      } else if (match.group(5) != null) {
        // *bold* -> rendered with boldStyle as expected in WhatsApp & health consultations
        final singleAsteriskText = _cleanResidualAsterisks(match.group(6) ?? '');
        if (singleAsteriskText.isNotEmpty) {
          spans.add(TextSpan(text: singleAsteriskText, style: boldStyle));
        }
      } else if (match.group(7) != null) {
        // __bold__
        final doubleUnderscoreText = match.group(8) ?? '';
        if (doubleUnderscoreText.isNotEmpty) {
          spans.add(TextSpan(text: doubleUnderscoreText, style: boldStyle));
        }
      } else if (match.group(9) != null) {
        // _italic_
        final italicText = match.group(10) ?? '';
        if (italicText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: italicText,
              style: baseStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          );
        }
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      final rawRemaining = text.substring(lastMatchEnd);
      final cleanRemaining = _cleanResidualAsterisks(rawRemaining);
      if (cleanRemaining.isNotEmpty) {
        spans.add(TextSpan(text: cleanRemaining, style: baseStyle));
      }
    }

    // Fallback if all was empty or only asterisks
    if (spans.isEmpty && text.isNotEmpty) {
      final clean = _cleanResidualAsterisks(text);
      if (clean.isNotEmpty) {
        spans.add(TextSpan(text: clean, style: baseStyle));
      }
    }

    return spans;
  }

  /// Extracts title and description from a list item line, properly stripping markdown asterisks from title
  /// and preparing description for inline span rendering.
  static (String title, String description) _extractListTitleAndDescription(
    String rawContent,
  ) {
    var content = rawContent.trim();

    // 1. Strip any residual bullet marker or stray asterisk prefix
    content = content.replaceFirst(
      RegExp(r'^(?:\*\*)?[•\-\*]\s*(?:\*\*)?\s*'),
      '',
    );

    // 2. Case A: Content starts with bold markdown title:
    // e.g. "**Title:** desc", "**Title**: desc", "***Title:*** desc", "*Title:* desc", "*Title*: desc"
    final leadingBoldMatch = RegExp(
      r'^\s*\*{1,3}(.+?)\*{1,3}\s*(?::|-)?\s*(.*)$',
      dotAll: true,
    ).firstMatch(content);

    if (leadingBoldMatch != null) {
      final rawTitle = leadingBoldMatch.group(1)!.trim();
      final remainder = leadingBoldMatch.group(2)!.trim();
      final cleanTitle = rawTitle
          .replaceAll('*', '')
          .replaceAll(RegExp(r':+$'), '')
          .trim();
      final title = cleanTitle.isNotEmpty ? '$cleanTitle:' : '';
      return (title, remainder);
    }

    // 3. Case B: Content has closing bold before colon (e.g. "**1. Title:** desc" -> content "Title:** desc")
    final closingBoldMatch = RegExp(
      r'^([^\*:]+?)\*{1,3}\s*:\s*(.*)$',
      dotAll: true,
    ).firstMatch(content);

    if (closingBoldMatch != null) {
      final rawTitle = closingBoldMatch.group(1)!.trim();
      final remainder = closingBoldMatch.group(2)!.trim();
      final cleanTitle = rawTitle.replaceAll('*', '').trim();
      final title = cleanTitle.isNotEmpty ? '$cleanTitle:' : '';
      return (title, remainder);
    }

    // 4. Case C: Content has plain title before colon without asterisks:
    // e.g. "Title: desc" (length < 45 chars)
    final colonIndex = content.indexOf(':');
    if (colonIndex != -1 && colonIndex > 0 && colonIndex < 45) {
      final rawTitle = content.substring(0, colonIndex).trim();
      final remainder = content.substring(colonIndex + 1).trim();
      final cleanTitle = rawTitle.replaceAll('*', '').trim();
      if (cleanTitle.isNotEmpty) {
        return ('$cleanTitle:', remainder);
      }
    }

    // 5. Case D: Content has dash separator: "Title - desc"
    final dashIndex = content.indexOf(' - ');
    if (dashIndex != -1 && dashIndex > 0 && dashIndex < 45) {
      final rawTitle = content.substring(0, dashIndex).trim();
      final remainder = content.substring(dashIndex + 3).trim();
      final cleanTitle = rawTitle.replaceAll('*', '').trim();
      if (cleanTitle.isNotEmpty) {
        return ('$cleanTitle:', remainder);
      }
    }

    // 6. Default: No dedicated title, full text is description
    return ('', content);
  }

  /// Normalizes incoming message text by separating glued section headers, inline numbered items,
  /// and inline bullet points into structured markdown lines.
  static String _normalizeMessageText(String raw) {
    if (raw.isEmpty) return raw;

    var s = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 1. Separate headers attached to previous paragraphs or on the same line
    // e.g. "perut membuncit. **Secara fisiologis klinis..." -> "perut membuncit.\n\n**Secara fisiologis klinis..."
    final headerPrefixes = [
      r'Secara fisiologis klinis',
      r'Secara medis klinis',
      r'Secara klinis ginekologi',
      r'Secara klinis',
      r'Tanda-tanda bahaya',
      r'Tanda bahaya',
      r'Tanda yang perlu diwaspadai',
      r'Langkah-langkah penanganan',
      r'Langkah penanganan',
      r'Langkah-langkah pereda',
      r'Langkah yang disarankan',
      r'Langkah mandiri',
      r'Tindakan mandiri',
      r'Rekomendasi klinis',
      r'Referensi Pakar',
      r'Pemeriksaan Lanjutan',
      r'Evaluasi Lanjutan',
      r'Pantauan Siklus',
      r'Kapan sebaiknya',
      r'Kapan harus ke dokter',
      r'Kapan keterlambatan',
      r'Kapan Wajar vs Bahaya',
      r'Perbedaan utama',
      r'Karakteristik',
      r'Faktor pemicu',
      r'Penyebab umum',
    ];

    final headerPattern =
        '(?:\n|^|\\s)(\\*\\*(?:${headerPrefixes.join('|')})[^\n\\*]*?\\*\\*:?)';
    s = s.replaceAllMapped(
      RegExp(headerPattern, caseSensitive: false),
      (m) => '\n\n${m.group(1)!.trim()}\n',
    );

    // Also handle markdown headers like '### Header' or '| Header'
    s = s.replaceAllMapped(
      RegExp(r'(?<=[^\n])\s*(#{1,4}\s+[^\n]+)'),
      (m) => '\n\n${m.group(1)!.trim()}\n',
    );

    // 2. Separate inline numbered list items (e.g. "kalori. 2. **Menghindari..." -> "kalori.\n2. **Menghindari...")
    // Strictly match list numbers 1..20 (never 4-digit years like 2026)
    s = s.replaceAllMapped(
      RegExp(r'(?<=[^\n])\s+([1-9]|1[0-9]|20)[\.\)]\s*(?=(?:\*\*)?[A-Z])'),
      (m) => '\n${m.group(1)}. ',
    );

    // 3. Separate inline bullet points (e.g. "dokter: • **Nyeri..." or "standar. • **Nyeri...")
    s = s.replaceAllMapped(
      RegExp(r'(?<=[^\n])\s+([•\-\*])\s*(?=(?:\*\*)?[A-Z])'),
      (m) => '\n${m.group(1)} ',
    );

    // 4. Ensure trailing colons in bold headers are followed by a newline if immediately followed by text
    s = s.replaceAllMapped(
      RegExp(r'(\*\*[^\n\*]+?\*\*:?)\s*(?=[1-9•\-\*])'),
      (m) => '${m.group(1)}\n',
    );

    // 5. Clean up excessive consecutive newlines (> 2) to maintain neat spacing
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return s.trim();
  }

  bool _isHeaderLine(String line) {
    var clean = line.trim();
    if (clean.isEmpty) return false;

    // Do not treat numbered list items as headers (e.g. "1. Kompres Hangat: ...")
    if (RegExp(r'^(?:\*\*)?(?:[•\-\*]\s*)?([1-9]|1[0-9]|20)[\.\)]\s+').hasMatch(clean)) {
      return false;
    }

    // Markdown H1/H2/H3/H4 syntax
    if (clean.startsWith('#### ') ||
        clean.startsWith('### ') ||
        clean.startsWith('## ') ||
        clean.startsWith('# ')) {
      return true;
    }

    // Pipe / Flag syntax: "| Header"
    if (clean.startsWith('| ') ||
        clean.startsWith('|**') ||
        clean.startsWith('| *')) {
      return true;
    }

    // Strip leading list bullet markers, hashes, and pipes if present
    final cleanWithoutBullet = clean
        .replaceFirst(
          RegExp(r'^(?:[\|\#]+\s*)?(?:\*\*)?[•\-\*]\s*(?:\*\*)?'),
          '',
        )
        .trim();

    final noAsterisks = cleanWithoutBullet
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('|', '')
        .trim();
    final lower = noAsterisks.toLowerCase();

    // Standard clinical section headers keywords
    if (lower.startsWith('referensi pakar') ||
        lower.startsWith('secara fisiologis klinis') ||
        lower.startsWith('secara medis klinis') ||
        lower.startsWith('secara klinis') ||
        lower.startsWith('tanda-tanda bahaya') ||
        lower.startsWith('tanda bahaya') ||
        lower.startsWith('tanda yang perlu diwaspadai') ||
        lower.startsWith('langkah penanganan') ||
        lower.startsWith('langkah-langkah penanganan') ||
        lower.startsWith('langkah-langkah pereda') ||
        lower.startsWith('langkah yang disarankan') ||
        lower.startsWith('langkah mandiri') ||
        lower.startsWith('tindakan mandiri') ||
        lower.startsWith('pereda alami') ||
        lower.startsWith('evaluasi lanjutan') ||
        lower.startsWith('pantauan siklus') ||
        lower.startsWith('rekomendasi klinis') ||
        lower.startsWith('pemeriksaan lanjutan') ||
        lower.startsWith('berdasarkan kalender') ||
        lower.startsWith('melihat kalender') ||
        lower.startsWith('melihat riwayat') ||
        lower.startsWith('kapan wajar vs bahaya') ||
        lower.startsWith('perbedaan utama') ||
        lower.startsWith('karakteristik')) {
      return true;
    }

    // Explicit markdown bold header ending with colon or short title: **Judul:** or **Judul**
    if ((cleanWithoutBullet.startsWith('**') ||
            cleanWithoutBullet.startsWith('*')) &&
        (cleanWithoutBullet.endsWith('**') ||
            cleanWithoutBullet.endsWith('*') ||
            cleanWithoutBullet.endsWith(':') ||
            cleanWithoutBullet.endsWith(':**') ||
            cleanWithoutBullet.endsWith(':*')) &&
        noAsterisks.length < 140) {
      // If it looks like a single bullet item with description, don't treat as header
      // e.g. "**Nyeri Hebat:** Jika kram terasa..." (colon is inside first 35 chars, then long text > 60 chars)
      final firstColonIndex = noAsterisks.indexOf(':');
      if (firstColonIndex != -1 &&
          firstColonIndex < 35 &&
          noAsterisks.length > 60 &&
          !lower.startsWith('referensi') &&
          !lower.startsWith('secara fisiologis') &&
          !lower.startsWith('secara medis') &&
          !lower.startsWith('secara klinis') &&
          !lower.startsWith('tanda') &&
          !lower.startsWith('langkah')) {
        return false;
      }
      return true;
    }

    // Clinical question headers: "Kapan sebaiknya memeriksakan diri...?"
    if (lower.startsWith('kapan') && clean.endsWith('?') && clean.length < 120) {
      return true;
    }

    // Header directives ending with colon (and not a list item)
    if (clean.endsWith(':') && clean.length < 140) {
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
          lower.contains('penanganan') ||
          lower.contains('referensi')) {
        return true;
      }
    }

    return false;
  }

  Widget _buildHeader(String text, TextStyle defaultBold) {
    var cleanText = text.trim();
    cleanText = cleanText.replaceFirst(RegExp(r'^[\|\#]+\s*'), '');
    cleanText = cleanText.replaceFirst(
      RegExp(r'^(?:\*\*)?[•\-\*]\s*(?:\*\*)?'),
      '',
    );
    cleanText = cleanText.replaceAll('*', '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2, right: 8),
            width: 3.5,
            height: 16,
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
                height: 1.38,
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
    final (title, description) = _extractListTitleAndDescription(content);

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
          // Number indicator pill badge
          Container(
            margin: const EdgeInsets.only(top: 2.5, right: 8),
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
          Expanded(child: Text.rich(TextSpan(children: spanChildren))),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    String content,
    TextStyle defaultBase,
    TextStyle defaultBold,
  ) {
    final (title, description) = _extractListTitleAndDescription(content);

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
      padding: const EdgeInsets.only(bottom: 5),
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
          Expanded(child: Text.rich(TextSpan(children: spanChildren))),
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
    final defaultBase =
        baseStyle ??
        const TextStyle(
          fontSize: 13.5,
          height: 1.48,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
        );

    final defaultBold =
        boldStyle ??
        const TextStyle(
          fontSize: 13.5,
          height: 1.48,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );

    final normalized = _normalizeMessageText(text);
    final lines = normalized.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (widgets.isNotEmpty && widgets.last is! SizedBox) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      // 1. Numbered item: "1. ...", "2) ...", "**1. ...", "**1)**" (Strictly 1..20, never years like 2026)
      final numberedMatch = RegExp(
        r'^(?:\*\*)?(?:[•\-\*]\s*)?([1-9]|1[0-9]|20)[\.\)]\s*(?:\*\*)?\s*(.+)',
      ).firstMatch(line);
      if (numberedMatch != null) {
        final number = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!;
        widgets.add(
          _buildNumberedItem(number, content, defaultBase, defaultBold),
        );
        continue;
      }

      // 2. Section header (evaluated before generic bullet match so headers with bullet/asterisk formatting get vertical flag)
      if (_isHeaderLine(line)) {
        widgets.add(_buildHeader(line, defaultBold));
        continue;
      }

      // 3. Bullet item: "• ...", "- ...", "* ...", "**• ...", "**- ...", "*** ..."
      final bulletMatch = RegExp(
        r'^(?:\*\*)?[•\-\*]\s*(?:\*\*)?\s*(.+)',
      ).firstMatch(line);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!;
        widgets.add(_buildBulletItem(content, defaultBase, defaultBold));
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

