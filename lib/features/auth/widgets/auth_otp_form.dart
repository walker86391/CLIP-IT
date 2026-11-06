import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../app/routes.dart';
import '../auth_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_submit_tick.dart';

/// Clean, responsive verification view supporting both Supabase confirm-email
/// links (the default in Supabase) and 6-digit OTP codes, with an active
/// 60-second resend cooldown timer.
///
/// Seamlessly logs the user straight into the app on success without
/// requiring them to re-enter credentials or sign in again.
class AuthOtpForm extends ConsumerStatefulWidget {
  const AuthOtpForm({
    required this.email,
    required this.onBack,
    this.password,
    this.otpType = OtpType.signup,
    this.displayName,
    this.dateOfBirth,
    this.onSuccess,
    super.key,
  });

  final String email;
  final String? password;
  final VoidCallback onBack;
  final OtpType otpType;
  final String? displayName;
  final DateTime? dateOfBirth;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthOtpForm> createState() => _AuthOtpFormState();
}

class _AuthOtpFormState extends ConsumerState<AuthOtpForm> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _busy = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _confirmViaLink() async {
    if (widget.password == null) {
      setState(() => _error = 'Please enter the 6-digit code or sign in again.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final result = await ref.read(authProvider.notifier).signIn(
          email: widget.email,
          password: widget.password!,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (authState) async {
        if (authState.isAuthenticated) {
          if (widget.displayName != null || widget.dateOfBirth != null) {
            unawaited(
              ref.read(authProvider.notifier).updateProfile(
                    displayName: widget.displayName,
                    dateOfBirth: widget.dateOfBirth,
                  ),
            );
          }
          widget.onSuccess?.call();
          if (GoRouter.maybeOf(context) != null) {
            context.go(Routes.ok);
          }
        } else {
          setState(() => _error =
              'Email not confirmed yet. Please click the link in your email first.');
        }
      },
      (err) {
        final msg = err.message.toLowerCase();
        if (msg.contains('not confirmed') ||
            msg.contains('not verified') ||
            msg.contains('email_not_confirmed')) {
          setState(() => _error =
              'Email not confirmed yet. Click the confirmation link in your email and tap below.');
        } else {
          setState(() => _error = err.message);
        }
      },
    );
  }

  Future<void> _verify([String? token]) async {
    final code = (token ?? _otpController.text).trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits of the code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final result = await ref.read(authProvider.notifier).verifyOtp(
          email: widget.email,
          token: code,
          type: widget.otpType,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (authState) async {
        if (authState.isAuthenticated) {
          // If we have profile data from sign-up, save it now
          if (widget.displayName != null || widget.dateOfBirth != null) {
            unawaited(
              ref.read(authProvider.notifier).updateProfile(
                    displayName: widget.displayName,
                    dateOfBirth: widget.dateOfBirth,
                  ),
            );
          }
          // Log user straight into app — no extra sign-in required!
          widget.onSuccess?.call();
          if (GoRouter.maybeOf(context) != null) {
            context.go(Routes.ok);
          }
        } else {
          setState(() => _error = 'Verification failed. Please try again.');
        }
      },
      (err) {
        setState(() => _error = err.message);
      },
    );
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _resending) return;

    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });

    final result = await ref.read(authProvider.notifier).resendOtp(
          email: widget.email,
          type: widget.otpType,
        );

    if (!mounted) return;
    setState(() => _resending = false);

    result.fold(
      (_) {
        setState(() => _info = 'A fresh 6-digit code has been sent!');
        _startCountdown();
      },
      (err) {
        setState(() => _error = err.message);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Envelope icon with glow
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuthColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AuthColors.accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 24,
              color: AuthColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Header
        const Text(
          'Verify your email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AuthColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'We\'ve sent a confirmation link to\n${widget.email}',
          style: AuthText.secondary.copyWith(height: 1.35),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Click the link in the email to activate your account.',
          style: TextStyle(
            fontSize: 12,
            color: AuthColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Action: I've Confirmed My Email (for the default Supabase link)
        if (widget.password != null) ...[
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _busy ? null : _confirmViaLink,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AuthColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF14161B),
                        ),
                      )
                    : const Text(
                        "I've Confirmed My Email →",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14161B),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0x1FFFFFFF))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR ENTER 6-DIGIT CODE',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AuthColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0x1FFFFFFF))),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // OTP Input Box (instant hardware-accelerated rendering)
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AuthColors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _error != null
                  ? AuthColors.error
                  : AuthColors.glassBorder,
              width: 1.2,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AuthColors.textPrimary,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: AuthColors.textSecondary,
                  letterSpacing: 6,
                  fontSize: 18,
                ),
              ),
              onChanged: (val) {
                setState(() => _error = null);
                if (val.trim().length == 6) {
                  _verify();
                }
              },
              onSubmitted: (_) => _verify(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (_error != null) ...[
          Text(
            _error!,
            style: AuthText.errorText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],

        if (_info != null) ...[
          Text(
            _info!,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4ADE80),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],

        // Submit Button for OTP code
        AuthSubmitTick(
          onPressed: _busy ? null : _verify,
          enabled: _otpController.text.trim().length == 6 && !_busy,
          busy: _busy,
          semanticsLabel: 'Verify code and sign in',
        ),

        const SizedBox(height: 16),

        // 60-Second Cooldown Resend Section
        Center(
          child: _secondsRemaining > 0
              ? Text(
                  'Resend code in ${_secondsRemaining}s',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AuthColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _resend,
                    child: Text(
                      _resending ? 'Sending...' : 'Resend code',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AuthColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Back link
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onBack,
              child: const Text(
                '← Use different credentials',
                style: TextStyle(
                  fontSize: 12,
                  color: AuthColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
