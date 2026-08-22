import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

const _perks = [
  (
    title: '5 extra pills every day',
    sub: 'A second set unlocks the moment you finish the first.',
  ),
  (
    title: 'The full archive',
    sub: 'Every pill you have ever read, searchable by topic.',
  ),
  (
    title: 'Share as image',
    sub: 'Export any card as a clean square for stories.',
  ),
  (
    title: 'Pick your own topics',
    sub: 'Weight the mix toward what you actually like.',
  ),
];

/// Knowit+ — the plans are selectable and the copy follows the choice.
/// There is no billing behind the CTA: it reports that checkout is not
/// connected rather than pretending to charge.
class PaywallScreen extends StatefulWidget {
  final AppState app;
  const PaywallScreen({super.key, required this.app});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Plan _plan = widget.app.plan;

  String get _cta => _plan == Plan.year
      ? 'Try 7 days free, then €24,99/yr'
      : 'Try 7 days free, then €3,99/mo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'KNOWIT+',
                  style: AppText.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    spacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              'Ten pills a day, and nothing gets lost.',
              style: AppText.outfit(
                size: 36,
                weight: FontWeight.w700,
                height: 1.06,
                spacing: -1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            ..._perks.map(
              (p) => Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: AppText.figtree(
                              size: 14.5,
                              weight: FontWeight.w600,
                              height: 1.3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.sub,
                            style: AppText.figtree(
                              size: 12.5,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            _PlanTile(
              label: 'Monthly',
              price: '€3,99',
              note: 'billed monthly',
              selected: _plan == Plan.month,
              onTap: () {
                setState(() => _plan = Plan.month);
                widget.app.setPlan(Plan.month);
              },
            ),
            const SizedBox(height: 10),
            _PlanTile(
              label: 'Yearly',
              price: '€24,99',
              note: '€2,08 / month · save 48%',
              selected: _plan == Plan.year,
              onTap: () {
                setState(() => _plan = Plan.year);
                widget.app.setPlan(Plan.year);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Checkout is not connected in this build.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  _cta,
                  style: AppText.figtree(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Cancel any time · Restore purchase',
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 11.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String label;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.label,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Colors.white : AppColors.ink;
    final sub = selected
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.45);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
        decoration: BoxDecoration(
          // The selected tile stays on the dark ground with a lit border;
          // the other one turns to paper so the choice reads instantly.
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.figtree(
                      size: 15.5,
                      weight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(note, style: AppText.figtree(size: 12, color: sub)),
                ],
              ),
            ),
            Text(
              price,
              style: AppText.outfit(
                size: 19,
                weight: FontWeight.w700,
                spacing: -0.5,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
