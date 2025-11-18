import 'package:flutter/material.dart';
import '../utils/fiscal_glossary.dart';
import '../widgets/fiscal_term_tooltip.dart';

/// Comprehensive help screen with fiscal term glossary, quick tips, and search
class HelpScreen extends StatefulWidget {
  /// Optional initial term to highlight (when navigating from tooltip)
  final String? initialTerm;

  const HelpScreen({
    super.key,
    this.initialTerm,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _searchResults = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // If initial term is provided, show it immediately
    if (widget.initialTerm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTermDialog(widget.initialTerm!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = {};
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = FiscalGlossary.searchTerms(query);
    });
  }

  void _showTermDialog(String term) {
    final explanation = FiscalGlossary.getExplanation(term);
    if (explanation != null) {
      showDialog(
        context: context,
        builder: (context) => FiscalTermDialog(
          term: term,
          explanation: explanation,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajutor și Glosar Fiscal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Caută',
            ),
            Tab(
              icon: Icon(Icons.book),
              text: 'Glosar',
            ),
            Tab(
              icon: Icon(Icons.tips_and_updates),
              text: 'Sfaturi',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildGlossaryTab(),
          _buildTipsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Semantics(
            label: 'Caută termeni fiscali',
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Caută termeni fiscali...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                        tooltip: 'Șterge căutarea',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
        ),
        Expanded(
          child: _isSearching
              ? _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nu am găsit rezultate',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Încearcă un alt termen',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final entry = _searchResults.entries.elementAt(index);
                        return _buildTermCard(entry.key, entry.value);
                      },
                    )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Caută termeni fiscali',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Introdu un cuvânt cheie pentru a găsi explicații despre termeni fiscali',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGlossaryTab() {
    final categories = HelpTopics.topicsByCategory;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final terms = categories[category]!;

        return Semantics(
          label: 'Categorie: $category',
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Icon(
                _getCategoryIcon(category),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text(
                '${terms.length} termeni',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: terms.map((term) {
                final explanation = FiscalGlossary.getExplanation(term) ?? '';
                // Get first meaningful line for preview
                final preview = explanation
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .skip(1) // Skip the term name
                    .firstWhere(
                      (line) => !line.startsWith('==='),
                      orElse: () => '',
                    )
                    .trim();

                return ListTile(
                  title: Text(
                    term,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: preview.isNotEmpty
                      ? Text(
                          preview.length > 100
                              ? '${preview.substring(0, 100)}...'
                              : preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTermDialog(term),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipsTab() {
    final tips = QuickTips.tips;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Introduction card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sfaturi Rapide',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Răspunsuri rapide la întrebările cele mai frecvente despre PFA și obligații fiscale în România.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tips
        ...tips.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuickTipCard(
              question: entry.key,
              answer: entry.value,
            ),
          );
        }),

        // Disclaimer
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disclaimer Important',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Această aplicație oferă informații generale despre fiscalitatea PFA în România. '
                  'Legislația fiscală este complexă și se schimbă frecvent.\n\n'
                  'Pentru situații specifice, consultați întotdeauna un expert contabil autorizat '
                  'sau un consultant fiscal calificat.\n\n'
                  'Nu ne asumăm răspunderea pentru decizii luate pe baza informațiilor din această aplicație.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermCard(String term, String explanation) {
    // Extract preview (first few lines)
    final lines = explanation.split('\n').where((l) => l.trim().isNotEmpty);
    final preview = lines.length > 3
        ? lines.take(3).join('\n')
        : lines.join('\n');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          term,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showTermDialog(term),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Baze':
        return Icons.foundation;
      case 'Taxe și Contribuții':
        return Icons.account_balance;
      case 'Sisteme de Impozitare':
        return Icons.calculate;
      case 'Venituri și Cheltuieli':
        return Icons.attach_money;
      case 'Documente și Registre':
        return Icons.folder;
      case 'Autorități și Sisteme':
        return Icons.business;
      case 'Termeni Contabili':
        return Icons.analytics;
      case 'TVA':
        return Icons.percent;
      case 'CAS și Pensii':
        return Icons.savings;
      case 'CASS și Sănătate':
        return Icons.local_hospital;
      default:
        return Icons.help_outline;
    }
  }
}
