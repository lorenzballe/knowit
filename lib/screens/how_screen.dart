import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// The disclosure screen — says up front that the cards are model-written,
/// and how one reaches the reader.
///
/// Every line here is a claim about how the app works, so each has to stay
/// true: the cards are written ahead into a bank, not the same morning;
/// each names its source and is read by a second model before it ships;
/// the day deals five the reader has not read; enough readers calling one
/// untrue takes it out of the deal until a person has checked it
/// (functions/src/scorecard.ts); and the sources are checked again each
/// month. It used to promise a card drafted on the morning it was read and
/// "the twelve you picked", which stopped being so long ago.
class HowScreen extends StatelessWidget {
  const HowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = [
      (n: '01', title: l.howStep1Title, sub: l.howStep1Line),
      (n: '02', title: l.howStep2Title, sub: l.howStep2Line),
      (n: '03', title: l.howStep3Title, sub: l.howStep3Line),
      (n: '04', title: l.howStep4Title, sub: l.howStep4Line),
    ];
    return ScreenView(
      name: 'how',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackCircle(onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: 22),
              Text(
                l.howTitle,
                style: AppText.display(
                  size: 31,
                  weight: FontWeight.w700,
                  height: 1.07,
                  spacing: -1.2,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.howIntro,
                style: AppText.body(
                  size: 14.5,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 22),
              for (final s in steps)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.p.line)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.n,
                        style: AppText.label(
                          size: 11,
                          height: 1.5,
                          color: context.p.link,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: AppText.body(
                                size: 15,
                                weight: FontWeight.w600,
                                height: 1.3,
                                color: context.p.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.sub,
                              style: AppText.body(
                                size: 13,
                                height: 1.5,
                                color: context.p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: context.p.surfaceRaised,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.howReportTitle,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: context.p.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.howReportLine,
                      style: AppText.body(
                        size: 13,
                        height: 1.45,
                        color: context.p.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l.howFoot,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 11.5,
                  height: 1.5,
                  color: context.p.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
