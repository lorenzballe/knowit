import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/daily.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../sync/account.dart';
import '../sync/board.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

/// Friends: a code to give, a code to type, and what those codes show.
///
/// What a friend sees is the shape of a habit — the streak, the weeks, how
/// far off the confidence runs, today's five as squares — and never a
/// question or an answer. Two readers comparing boards are comparing how
/// they think, which is the one comparison this app is for.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.app,
    required this.account,
    required this.onBack,
  });

  final AppState app;
  final Account account;
  final VoidCallback onBack;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _typed = TextEditingController();

  /// One read per code per visit. A friend's board does not change while
  /// the reader is looking at it, and a list that re-reads on every frame
  /// of a snackbar is a list that flickers.
  final Map<String, Future<Board?>> _boards = {};

  AppState get app => widget.app;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<Board?> _boardOf(String code) =>
      _boards.putIfAbsent(code, () => widget.account.board(code));

  Future<void> _copyCode(String code) async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.codeCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _add() async {
    final l = context.l10n;
    final String? code = parseFriendCode(_typed.text);
    if (code == null) return;
    if (code == widget.account.friendCode) {
      _say(l.thatsYourOwnCode);
      return;
    }
    _typed.clear();
    await app.addFriend(code);
    if (mounted) setState(() {});
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String? mine = widget.account.friendCode;
    final Color ink = context.p.ink;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            Row(
              children: [
                BackCircle(onPressed: widget.onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.friends,
                    style: AppText.display(
                      size: 27,
                      weight: FontWeight.w600,
                      height: 1,
                      spacing: -0.8,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // The reader's own code, big enough to read across a table.
            Eyebrow(l.yourFriendCode),
            const SizedBox(height: 10),
            _CodeCard(
              code: mine,
              onCopy: mine == null ? null : () => _copyCode(mine),
            ),
            if (!widget.account.canCompare) ...[
              const SizedBox(height: 10),
              Text(
                l.friendsNeedAnAccount,
                style: AppText.body(
                  size: 13,
                  height: 1.45,
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Eyebrow(l.addAFriend),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('friend-code'),
                    controller: _typed,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 7,
                    onSubmitted: (_) => _add(),
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w600,
                      spacing: 2,
                      color: ink,
                    ),
                    decoration: InputDecoration(
                      hintText: l.theirCode,
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.p.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.p.line),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // A width of its own: the chunky button fills what it is
                // given, and a row gives it nothing.
                SizedBox(
                  width: 96,
                  child: PrimaryButton(
                    label: l.add,
                    height: 46,
                    onPressed: _add,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            if (app.friendCodes.isEmpty)
              Text(
                l.noFriendsYet,
                style: AppText.body(
                  size: 14,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              )
            else ...[
              for (var i = 0; i < app.friendCodes.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                RiseIn.staggered(
                  i,
                  child: FutureBuilder<Board?>(
                    future: _boardOf(app.friendCodes[i]),
                    builder: (context, snap) => _FriendRow(
                      code: app.friendCodes[i],
                      board: snap.data,
                      waiting: snap.connectionState != ConnectionState.done,
                      today: editionOf(app.today),
                      onRemove: () async {
                        await app.removeFriend(app.friendCodes[i]);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              // The week, side by side: not who read the most, but whose
              // confidence is closest to their record — the one race in
              // this app worth running against a friend.
              Eyebrow(l.thisWeekByCalibration),
              const SizedBox(height: 10),
              _League(app: app, account: widget.account, boards: _boards),
            ],
          ],
        ),
      ),
    );
  }
}

/// The code, set large, and copied with a tap.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onCopy});

  final String? code;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      button: onCopy != null,
      label: code == null ? null : context.l10n.yourFriendCode,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCopy,
        child: PaperCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code ?? '—',
                  key: const ValueKey('my-code'),
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w600,
                    spacing: 4,
                    color: ink,
                  ),
                ),
              ),
              if (onCopy != null)
                Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: ink.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One friend: who, the streak, the weeks, the gap, today's squares.
class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.code,
    required this.board,
    required this.waiting,
    required this.today,
    required this.onRemove,
  });

  final String code;
  final Board? board;
  final bool waiting;
  final int today;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Board? b = board;
    final String line = b == null
        ? (waiting ? '…' : l.noReaderWithCode)
        : [
            '\u{1f525}${b.streak}',
            l.nWeeksKept(b.weeks),
            b.gap == null ? l.notMeasuredYet : l.pointsOff(b.gap!.round()),
          ].join(' · ');
    final String squares = b == null
        ? ''
        : (b.edition == today && b.squares.isNotEmpty
              ? b.squares
              : l.notYetToday);
    // The one card in common, said plainly: this is what two friends can
    // actually compare.
    final String? question = b != null && b.edition == today
        ? _questionLine(l, b.questionRight, b.questionSure)
        : null;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b?.name ?? code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ),
                    Text(
                      code,
                      style: AppText.label(
                        size: 10.5,
                        spacing: 1.2,
                        color: context.p.inkFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  line,
                  style: AppText.body(
                    size: 13,
                    height: 1.35,
                    color: ink.withValues(alpha: 0.6),
                  ),
                ),
                if (squares.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    question == null
                        ? squares
                        : '$squares \u00b7 ${l.todaysQuestion}: $question',
                    style: AppText.body(
                      size: 13,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: l.cancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: context.p.inkFaint,
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

String? _questionLine(AppLocalizations l, bool? right, int? sure) {
  if (right == null) return null;
  if (sure == null) return right ? l.right : l.wrong;
  return right ? l.rightAtSure(sure) : l.wrongAtSure(sure);
}

/// The reader and their friends, ordered by how close their confidence
/// runs to their record — closest first, and the unmeasured at the foot.
class _League extends StatelessWidget {
  const _League({
    required this.app,
    required this.account,
    required this.boards,
  });

  final AppState app;
  final Account account;
  final Map<String, Future<Board?>> boards;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<List<Board?>>(
      future: Future.wait(app.friendCodes.map((c) => boards[c]!)),
      builder: (context, snap) {
        final me = app.board(account.uid ?? 'me');
        final rows =
            <(String, Board)>[
              (l.you, me),
              for (final b in snap.data ?? const <Board?>[])
                if (b != null) (b.name, b),
            ]..sort((a, b) {
              final double ga = a.$2.gap ?? double.infinity;
              final double gb = b.$2.gap ?? double.infinity;
              final int byGap = ga.compareTo(gb);
              if (byGap != 0) return byGap;
              return b.$2.days.compareTo(a.$2.days);
            });
        final Color ink = context.p.ink;
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        style: AppText.label(
                          size: 11,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ),
                    Text(
                      l.nOfSeven(rows[i].$2.days),
                      style: AppText.body(
                        size: 13,
                        color: ink.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 118,
                      child: Text(
                        rows[i].$2.gap == null
                            ? l.notMeasuredYet
                            : l.pointsOff(rows[i].$2.gap!.round()),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 13,
                          color: ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
