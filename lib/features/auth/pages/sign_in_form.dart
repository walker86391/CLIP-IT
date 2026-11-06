import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../app/routes.dart';
import '../auth_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_otp_form.dart';
import '../widgets/auth_submit_tick.dart';
import '../widgets/auth_text_field.dart';

/// Sign In form.
///
/// On success routes to /ok (the router also reacts to the auth state
/// change; the explicit go() keeps the intent obvious).
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({
    required this.onSwitchTab,
    required this.submitEnabled,
    super.key,
  });

  /// 0 = Sign Up, 1 = Sign In, 2 = Secret Code.
  final ValueChanged<int> onSwitchTab;

  /// False when Supabase is not configured — keeps submit disabled.
  final bool submitEnabled;

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitAttempted = false;
  bool _busy = false;
  bool _showOtp = false;
  String? _formError;

  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  // ── Validation ──────────────────────────────────────────────────────────

  // Errors surface as soon as a field has content (not only after a submit
  // attempt), because the submit tick is inert until the form is valid, so
  // pressing it to "reveal" errors is no longer possible.
  String? _emailError() {
    final bool touched = _emailController.text.trim().isNotEmpty;
    if (!_submitAttempted && !touched) return null;
    final value = _emailController.text.trim();
    if (value.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _passwordError() {
    final bool touched = _passwordController.text.isNotEmpty;
    if (!_submitAttempted && !touched) return null;
    if (_passwordController.text.isEmpty) return 'Password is required';
    return null;
  }

  bool get _allValid =>
      _emailRegex.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.isNotEmpty;

  bool get _canSubmit => widget.submitEnabled && !_busy && _allValid;

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _submitAttempted = true;
      _formError = null;
    });
    if (!_canSubmit) return;

    setState(() => _busy = true);

    final result = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (authState) {
        if (authState.isAuthenticated) {
          context.go(Routes.ok);
        } else {
          setState(() => _formError = 'Sign-in did not complete. Try again.');
        }
      },
      (error) {
        final msg = error.message.toLowerCase();
        // ONLY IF NEEDED: Detect unconfirmed / unverified email from Supabase
        if (msg.contains('not confirmed') ||
            msg.contains('not verified') ||
            msg.contains('email_not_confirmed')) {
          // Trigger OTP resend so the code is freshly in the user's inbox
          ref.read(authProvider.notifier).resendOtp(
                email: _emailController.text.trim(),
                type: OtpType.signup,
              );
          setState(() {
            _showOtp = true;
          });
        } else {
          // Standard credential errors (e.g. Invalid login credentials)
          setState(() => _formError = error.message);
        }
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showOtp) {
      return AuthOtpForm(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        otpType: OtpType.signup,
        onBack: () => setState(() => _showOtp = false),
      );
    }

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            errorText: _emailError(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Your password',
            errorText: _passwordError(),
            obscure: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_formError != null) ...[
            Text(_formError!, style: AuthText.errorText),
            const SizedBox(height: 8),
          ],
          AuthSubmitTick(
            // Grey and inert until both fields are valid; live per-field
            // errors (shown as soon as a field has content) explain what is
            // missing, so an inert control is never a silent dead end.
            onPressed: _canSubmit ? _submit : null,
            enabled: _canSubmit,
            busy: _busy,
            semanticsLabel: 'Sign in',
          ),
          const SizedBox(height: 14),
          Center(
            child: _InlineLink(
              prefix: 'New here? ',
              linkLabel: 'Create a new account',
              onTap: () => widget.onSwitchTab(0),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// Small two-part text link used under the forms.
class _InlineLink extends StatefulWidget {
  const _InlineLink({
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
  });

  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  State<_InlineLink> createState() => _InlineLinkState();
}

class _InlineLinkState extends State<_InlineLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Focus(
          canRequestFocus: false,
          child: Text.rich(
            TextSpan(
              text: widget.prefix,
              style: AuthText.secondary,
              children: [
                TextSpan(
                  text: widget.linkLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _hovered
                        ? AuthColors.accentHover
                        : AuthColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
