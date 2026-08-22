import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'pill_detail_screen.dart';

/// Live search across the whole pool. Typing filters as you go; the topic
/// chips narrow it further.
class ArchiveScreen extends StatefulWidget {
  final AppState app;
  final VoidCallback onBack;

  const ArchiveScreen({super.key, required this.app, required this.onBack});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _topicFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Pill> get _results {
    var found = searchPills(_query);
    if (_topicFilter != null) {
      final name = kTopics[_topicFilter]!.name;
      found = found.where((p) => p.topic == name).toList();
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackCircle(onPressed: widget.onBack),
                  const SizedBox(height: 16),
                  Text(
                    'Archive',
                    style: AppText.outfit(
                      size: 33,
                      weight: FontWeight.w700,
                      height: 1.05,
                      spacing: -1.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            style: AppText.figtree(
                              size: 15,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Search ${kPillPool.length} pills',
                              hintStyle: AppText.figtree(
                                size: 15,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          Semantics(
                            button: true,
                            label: 'Clear search',
                            child: GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kTopicOrder.map((key) {
                      final style = kTopics[key]!;
                      final on = _topicFilter == key;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _topicFilter = on ? null : key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: on ? AppColors.ink : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: on
                                  ? Colors.transparent
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TopicDot(style.color, size: 7),
                              const SizedBox(width: 7),
                              Text(
                                style.name,
                                style: AppText.figtree(
                                  size: 12.5,
                                  weight: FontWeight.w500,
                                  color: on
                                      ? Colors.white
                                      : Colors.black.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Eyebrow(
                    '${results.length} result${results.length == 1 ? '' : 's'}',
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? _NoResults(query: _query)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                      itemCount: results.length,
                      itemBuilder: (context, i) => _ResultRow(
                        pill: results[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PillDetailScreen(
                              pill: results[i],
                              app: widget.app,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Pill pill;
  final VoidCallback onTap;
  const _ResultRow({required this.pill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: TopicDot(pill.color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.question,
                    style: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w500,
                      height: 1.32,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pill.topic} · ${pill.source}',
                    style: AppText.figtree(
                      size: 11.5,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          query.isEmpty
              ? 'No pills match that filter yet.'
              : 'Nothing for "$query". Try a topic instead.',
          textAlign: TextAlign.center,
          style: AppText.figtree(
            size: 14,
            height: 1.5,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
