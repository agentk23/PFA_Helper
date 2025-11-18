import 'package:flutter/material.dart';
import '../utils/fiscal_glossary.dart';

/// A widget that displays a help icon next to fiscal terms
/// and shows a detailed explanation when tapped.
///
/// Usage:
/// ```dart
/// Row(
///   children: [
///     Text('Impozit pe Venit'),
///     FiscalTermTooltip(term: 'IMPOZIT PE VENIT'),
///   ],
/// )
/// ```
class FiscalTermTooltip extends StatelessWidget {
  /// The fiscal term to explain (must match a key in FiscalGlossary)
  final String term;

  /// Custom icon to display (defaults to help icon)
  final IconData? icon;

  /// Size of the icon (defaults to 18)
  final double iconSize;

  /// Color of the icon (defaults to theme secondary color)
  final Color? iconColor;

  const FiscalTermTooltip({
    super.key,
    required this.term,
    this.icon,
    this.iconSize = 18.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final explanation = FiscalGlossary.getExplanation(term);

    // If no explanation found, don't show the icon
    if (explanation == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Ajutor pentru $term',
      hint: 'Apasă pentru a vedea explicația',
      button: true,
      child: IconButton(
        icon: Icon(
          icon ?? Icons.help_outline,
          size: iconSize,
        ),
        color: iconColor ?? Theme.of(context).colorScheme.secondary,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        onPressed: () {
          _showExplanationDialog(context, term, explanation);
        },
        tooltip: 'Ajutor pentru $term',
      ),
    );
  }

  void _showExplanationDialog(
    BuildContext context,
    String term,
    String explanation,
  ) {
    showDialog(
      context: context,
      builder: (context) => FiscalTermDialog(
        term: term,
        explanation: explanation,
      ),
    );
  }
}

/// Dialog that displays the full explanation of a fiscal term
class FiscalTermDialog extends StatelessWidget {
  final String term;
  final String explanation;

  const FiscalTermDialog({
    super.key,
    required this.term,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              term,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SelectableText(
          explanation,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Închide'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Navigate to full help screen
            Navigator.pushNamed(context, '/help', arguments: term);
          },
          child: const Text('Vezi mai multe'),
        ),
      ],
      semanticLabel: 'Explicație pentru $term',
    );
  }
}

/// A compact inline help widget that shows explanation in a tooltip
class FiscalTermInlineHelp extends StatelessWidget {
  /// The fiscal term to explain
  final String term;

  /// The label text to display
  final String label;

  /// Text style for the label
  final TextStyle? labelStyle;

  const FiscalTermInlineHelp({
    super.key,
    required this.term,
    required this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final explanation = FiscalGlossary.getExplanation(term);

    if (explanation == null) {
      return Text(label, style: labelStyle);
    }

    // Extract first line of explanation for tooltip
    final shortExplanation = explanation.split('\n').firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => explanation,
        );

    return Semantics(
      label: '$label - $shortExplanation',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 4),
          Tooltip(
            message: shortExplanation,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => FiscalTermDialog(
                    term: term,
                    explanation: explanation,
                  ),
                );
              },
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that wraps a label and value with an optional help tooltip
class FiscalFieldWithHelp extends StatelessWidget {
  /// The fiscal term for help
  final String term;

  /// Label to display
  final String label;

  /// Value to display
  final String value;

  /// Whether to show help icon
  final bool showHelp;

  const FiscalFieldWithHelp({
    super.key,
    required this.term,
    required this.label,
    required this.value,
    this.showHelp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (showHelp) ...[
                  const SizedBox(width: 4),
                  FiscalTermTooltip(
                    term: term,
                    iconSize: 16,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: '$label: $value',
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that displays a quick tip from the glossary
class QuickTipCard extends StatelessWidget {
  final String question;
  final String answer;
  final IconData icon;

  const QuickTipCard({
    super.key,
    required this.question,
    required this.answer,
    this.icon = Icons.tips_and_updates,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Semantics(
        label: 'Sfat rapid: $question',
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
