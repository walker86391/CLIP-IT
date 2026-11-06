import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../auth_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_submit_tick.dart';
import '../widgets/auth_text_field.dart';

/// Secret Code form — alternate login route without email & password.
///
/// Features:
/// 1. Verifies the entered secret code against Supabase
///    `verify_secret_admin_code` RPC.
/// 2. If valid: signs in as admin and navigates to the app.
/// 3. If expired: displays "Code expired. Sign up / login now" with an
///    immediate link and automatic transition back to the sign-in/sign-up tab.
/// 4. If invalid: shows clear error notification.
class SecretCodeForm extends ConsumerStatefulWidget {
  const SecretCodeForm({
    required this.submitEnabled,
    required this.onSwitchTab,
    super.key,
  });

  /// False when Supabase is not configured — keeps submit disabled.
  final bool submitEnabled;

  /// 0 = Sign Up, 1 = Sign In, 2 = Secret Code.
  final ValueChanged<int> onSwitchTab;

  @override
  ConsumerState<SecretCodeForm> createState() => _SecretCodeFormState();
}

class _SecretCodeFormState extends ConsumerState<SecretCodeForm> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _formError;
  bool _isExpired = false;
  Timer? _redirectTimer;

  bool get _canSubmit =>
      widget.submitEnabled &&
      !_busy &&
      _codeController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _busy || !widget.submitEnabled) return;

    setState(() {
      _busy = true;
      _formError = null;
      _isExpired = false;
    });

    final result = await ref
        .read(authProvider.notifier)
        .signInWithSecretCode(code);

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (authState) {
        if (authState.isAuthenticated) {
          context.go(Routes.home);
        } else {
          setState(() {
            _formError = 'Verification did not complete. Please try again.';
          });
        }
      },
      (error) {
        final isExp = error.code == 'expired' ||
            error.message.toLowerCase().contains('code expired');

        setState(() {
          _isExpired = isExp;
          _formError = isExp
              ? 'Code expired. Sign up / login now'
              : error.message;
        });

        if (isExp) {
          // Allow the user to read the message, then smoothly return to the
          // main auth flow as requested.
          _redirectTimer?.cancel();
          _redirectTimer = Timer(const Duration(milliseconds: 2400), () {
            if (mounted) {
              widget.onSwitchTab(1);
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _codeController,
            label: 'Secret Code',
            hint: 'Enter your admin code',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canSubmit) _submit();
            },
            onChanged: (_) {
              if (_formError != null) {
                _redirectTimer?.cancel();
                setState(() {
                  _formError = null;
                  _isExpired = false;
                });
              } else {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),
          if (_formError != null) ...[
            if (_isExpired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x26EF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x66EF4444),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code expired. Sign up / login now',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _redirectTimer?.cancel();
                          widget.onSwitchTab(1);
                        },
                        child: const Text(
                          'Return to Sign In / Sign Up →',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(_formError!, style: AuthText.errorText),
            const SizedBox(height: 12),
          ],
          AuthSubmitTick(
            onPressed: _canSubmit ? _submit : null,
            enabled: _canSubmit,
            busy: _busy,
            semanticsLabel: 'Verify secret admin code',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }
}
