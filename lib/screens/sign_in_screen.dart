import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ui.dart';

/// Sign in. There is no account backend: the profile lives on this device
/// only. The provider buttons say so rather than miming a real sign-in, and
/// the e-mail path just names the local profile.
class SignInScreen extends StatefulWidget {
  final void Function(String name) onSignedIn;
  final VoidCallback onBack;

  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onBack,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  String _nameFromEmail() {
    final local = _email.text.trim().split('@').first;
    if (local.isEmpty) return 'You';
    return local[0].toUpperCase() + local.substring(1);
  }

  void _continueLocally(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider sign-in is not connected. Continuing with a profile '
          'kept on this device.',
        ),
      ),
    );
    widget.onSignedIn('You');
  }

  void _sendLink() {
    setState(() => _linkSent = true);
    // Nothing to verify against, so the "link" resolves immediately.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onSignedIn(_nameFromEmail());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BackCircle(onPressed: widget.onBack),
            ),
            const SizedBox(height: 28),
            Text(
              'Welcome back.',
              style: AppText.display(
                size: 32,
                weight: FontWeight.w700,
                height: 1.07,
                spacing: -1.3,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Your streak and your saved pills are waiting.',
              style: AppText.body(
                size: 14.5,
                height: 1.5,
                color: context.p.inkMuted,
              ),
            ),
            const SizedBox(height: 26),
            _ProviderButton(
              label: 'Continue with Apple',
              dark: true,
              leading: Icon(Icons.apple, size: 19, color: context.p.onInverse),
              onTap: () => _continueLocally('Apple'),
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              label: 'Continue with Google',
              dark: false,
              leading: Text(
                'G',
                style: AppText.display(
                  size: 15,
                  weight: FontWeight.w700,
                  color: context.p.link,
                ),
              ),
              onTap: () => _continueLocally('Google'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Container(height: 1, color: context.p.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: AppText.body(size: 11.5, color: context.p.inkFaint),
                  ),
                ),
                Expanded(child: Container(height: 1, color: context.p.line)),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 9),
              decoration: BoxDecoration(
                color: context.p.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.p.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Email'),
                  TextField(
                    controller: _email,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: AppText.body(size: 15, color: context.p.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'marco@studio.it',
                      hintStyle: AppText.body(
                        size: 15,
                        color: context.p.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: _linkSent
                  ? 'Link sent — signing you in'
                  : 'Send me a login link',
              background: _emailValid ? context.p.link : context.p.line,
              foreground: _emailValid ? null : context.p.inkFaint,
              onPressed: _emailValid && !_linkSent ? _sendLink : null,
            ),
            const SizedBox(height: 24),
            Text(
              'No account is created. Your streak and saved pills stay on '
              'this device.',
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
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final bool dark;
  final Widget leading;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.label,
    required this.dark,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: dark ? context.p.inverse : context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: dark ? null : Border.all(color: context.p.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 9),
            Text(
              label,
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w600,
                color: dark ? context.p.onInverse : context.p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
