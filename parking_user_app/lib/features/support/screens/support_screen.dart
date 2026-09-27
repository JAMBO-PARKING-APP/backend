import 'package:flutter/material.dart';
import 'package:parking_user_app/core/api_client.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _articles = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('user/help/');
      final dynamic payload = response.data;
      final List<dynamic> list;
      if (payload is List) {
        list = payload;
      } else if (payload is Map && payload['items'] is List) {
        list = payload['items'] as List<dynamic>;
      } else {
        throw const FormatException('The help response was invalid.');
      }
      if (!mounted) return;
      setState(() {
        _articles = list
            .whereType<Map>()
            .map((article) => article.cast<String, dynamic>())
            .toList(growable: false);
      });
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Could not load help articles: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & support')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : _articles.isEmpty
        ? const Center(child: Text('No help articles are available.'))
        : ListView.builder(
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              return ExpansionTile(
                title: Text(
                  (article['question'] ?? article['title'] ?? 'Help')
                      .toString(),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (article['answer'] ??
                              article['content'] ??
                              article['description'] ??
                              '')
                          .toString(),
                    ),
                  ),
                ],
              );
            },
          ),
  );
}
