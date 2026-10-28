import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ClassElectionApp());
}

class ClassElectionApp extends StatelessWidget {
  const ClassElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Election',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7963A8)),
        scaffoldBackgroundColor: const Color(0xFFFFF8FF),
        cardTheme: CardThemeData(
          color: const Color(0xFFF7F0FA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5DCEB)),
          ),
        ),
      ),
      home: const ElectionHomePage(),
    );
  }
}

class Candidate {
  Candidate({required this.name, this.votes = 0});

  final String name;
  int votes;

  Map<String, dynamic> toJson() => {'name': name, 'votes': votes};

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      name: json['name'] as String,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ElectionHomePage extends StatefulWidget {
  const ElectionHomePage({super.key});

  @override
  State<ElectionHomePage> createState() => _ElectionHomePageState();
}

class _ElectionHomePageState extends State<ElectionHomePage> {
  static const String _candidatesKey = 'class_election_candidates_v1';
  static const String _votersKey = 'class_election_voters_v1';

  final TextEditingController _voterController = TextEditingController();
  final List<Candidate> _candidates = [
    Candidate(name: 'Macrine Singiza'),
    Candidate(name: 'Diane Uwase'),
    Candidate(name: 'SINGIZA GIHOZO Macrine'),
  ];

  Set<String> _voters = {};
  bool _loadingSavedData = true;
  bool _saving = false;
  int _selectedTab = 0;

  int get _totalVotes => _candidates.fold(0, (sum, candidate) => sum + candidate.votes);

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _voterController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCandidates = prefs.getString(_candidatesKey);
      final rawVoters = prefs.getStringList(_votersKey) ?? [];

      if (rawCandidates != null) {
        final decoded = jsonDecode(rawCandidates) as List<dynamic>;
        final saved = decoded
            .map((item) => Candidate.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        for (final candidate in _candidates) {
          final match = saved.where((item) => item.name == candidate.name);
          if (match.isNotEmpty) candidate.votes = match.first.votes;
        }
      }

      if (!mounted) return;
      setState(() {
        _voters = rawVoters.map((name) => name.toLowerCase()).toSet();
        _loadingSavedData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSavedData = false);
      _showMessage('Could not load saved data. You can still use the app.');
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _candidatesKey,
      jsonEncode(_candidates.map((candidate) => candidate.toJson()).toList()),
    );
    await prefs.setStringList(_votersKey, _voters.toList());
  }

  Future<void> _voteFor(Candidate candidate) async {
    final voterName = _voterController.text.trim();

    if (voterName.isEmpty) {
      _showMessage('Enter your name before voting.');
      return;
    }
    if (_voters.contains(voterName.toLowerCase())) {
      _showMessage('This name has already voted.');
      return;
    }

    setState(() => _saving = true);
    try {
      candidate.votes++;
      _voters.add(voterName.toLowerCase());
      await _saveData();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _voterController.clear();
      });
      _showMessage('Your vote for ${candidate.name} has been saved.');
    } catch (_) {
      // Roll back the in-memory change if saving fails.
      candidate.votes--;
      _voters.remove(voterName.toLowerCase());
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save your vote. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ElectionResultsPage(candidates: _candidates),
      ),
    );
  }

  void _openLiveApi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LiveAdvicePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winnerVotes = _candidates.isEmpty
        ? 0
        : _candidates.map((candidate) => candidate.votes).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
          IconButton(
            tooltip: 'Live API',
            onPressed: _openLiveApi,
            icon: const Icon(Icons.cloud_outlined),
          ),
          IconButton(
            tooltip: 'Election results',
            onPressed: _openResults,
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            tooltip: 'Refresh saved data',
            onPressed: _loadSavedData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loadingSavedData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Total Votes Cast: $_totalVotes',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _voterController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Your Name (Voter)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Candidates', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final candidate in _candidates)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(candidate.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text('${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'}',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : () => _voteFor(candidate),
                            icon: const Icon(Icons.how_to_vote_outlined, size: 17),
                            label: const Text('Vote'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Live API information'),
                    subtitle: const Text('Load a live advice message from the internet'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openLiveApi,
                  ),
                ),
                if (winnerVotes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Leading candidate: ${_candidates.firstWhere((c) => c.votes == winnerVotes).name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
          if (index == 1) _openResults();
          if (index == 2) _openLiveApi();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), label: 'Vote'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'Live API'),
        ],
      ),
    );
  }
}

class ElectionResultsPage extends StatelessWidget {
  const ElectionResultsPage({super.key, required this.candidates});

  final List<Candidate> candidates;

  @override
  Widget build(BuildContext context) {
    final total = candidates.fold<int>(0, (sum, candidate) => sum + candidate.votes);
    final highVotes = candidates.isEmpty
        ? 0
        : candidates.map((candidate) => candidate.votes).reduce((a, b) => a > b ? a : b);
    final winners = candidates.where((candidate) => candidate.votes == highVotes && highVotes > 0).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Election Results'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (winners.length == 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Winner: ${winners.first.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          else if (winners.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'The election is tied',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade600,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No votes have been cast yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 18),
          for (final candidate in candidates)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(candidate.name)),
                        Text('${candidate.votes} ${candidate.votes == 1 ? 'vote' : 'votes'} '
                            '(${total == 0 ? '0.0' : (candidate.votes / total * 100).toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: total == 0 ? 0 : candidate.votes / total,
                        backgroundColor: const Color(0xFFE8DDF4),
                        color: const Color(0xFF7963A8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LiveAdvicePage extends StatefulWidget {
  const LiveAdvicePage({super.key});

  @override
  State<LiveAdvicePage> createState() => _LiveAdvicePageState();
}

class _LiveAdvicePageState extends State<LiveAdvicePage> {
  String? _advice;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAdvice();
  }

  Future<void> _fetchAdvice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.adviceslip.com/advice'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final slip = decoded['slip'] as Map<String, dynamic>?;
      final advice = slip?['advice'] as String?;
      if (advice == null || advice.isEmpty) {
        throw const FormatException('Advice was missing from the response');
      }

      if (!mounted) return;
      setState(() {
        _advice = advice;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load live data. Check your internet connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live API Advice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading live advice...'),
                  ],
                )
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _fetchAdvice,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_quote, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _advice ?? '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _fetchAdvice,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Get new advice'),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Live data from api.adviceslip.com',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
