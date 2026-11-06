import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../../app/routes.dart';
import '../auth_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_checkbox.dart';
import '../widgets/auth_otp_form.dart';
import '../widgets/auth_submit_tick.dart';
import '../widgets/auth_text_field.dart';

/// Sign Up form (default tab).
///
/// All fields + both agreements are required to enable "Continue".
/// On submit: authProvider.signUp →
///   - session active: best-effort profile update (display_name,
///     date_of_birth) then route to /ok.
///   - no session (email confirmation enabled): inline "check your email"
///     note, then switch to the Sign In tab.
class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({
    required this.onSwitchTab,
    required this.submitEnabled,
    super.key,
  });

  /// Called to switch tabs (0 = Sign Up, 1 = Sign In, 2 = Secret Code).
  final ValueChanged<int> onSwitchTab;

  /// False when Supabase is not configured — keeps submit disabled.
  final bool submitEnabled;

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _dateOfBirth;

  /// True once the user has interacted with the Date of Birth picker at
  /// all. The DOB field has no text to "touch", so without this flag its
  /// error could never appear (the submit tick is inert until the date is
  /// chosen, and a cancelled picker leaves it unset).
  bool _dobTouched = false;
  bool _agreePrivacy = false;
  bool _agreeTerms = false;

  bool _submitAttempted = false;
  bool _busy = false;
  bool _showOtp = false;
  String? _formError;
  String? _infoNote;

  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  // ── Validation ──────────────────────────────────────────────────────────

  // Validation errors now surface as soon as a field is TOUCHED (has
  // content), not only after a submit attempt.
  //
  // Why this changed: the submit control is now a tick that is genuinely
  // disabled until the form is complete (per design: grey and inert until
  // everything is filled and both boxes are ticked). That means
  // `_submitAttempted` can never flip by pressing it — the old rule would
  // leave a user who mistyped their email with a permanently grey tick and
  // no explanation. Showing the error as soon as they type (or submit) keeps
  // the "tell me what's wrong" behaviour the earlier dead-button fix was
  // about, without needing a pressable dead button.
  String? _nameError() {
    final bool touched = _nameController.text.trim().isNotEmpty;
    if (!_submitAttempted && !touched) return null;
    if (_nameController.text.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _dobError() {
    if (!_submitAttempted && !_dobTouched) return null;
    if (_dateOfBirth == null) return 'Date of birth is required';
    return null;
  }

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
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _confirmError() {
    final bool touched = _confirmController.text.isNotEmpty;
    if (!_submitAttempted && !touched) return null;
    if (_confirmController.text.isEmpty) {
      return 'Confirm your password';
    }
    if (_confirmController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool get _allValid =>
      _nameController.text.trim().isNotEmpty &&
      _dateOfBirth != null &&
      _emailRegex.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _confirmController.text == _passwordController.text &&
      _agreePrivacy &&
      _agreeTerms;

  bool get _canSubmit => widget.submitEnabled && !_busy && _allValid;

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _submitAttempted = true;
      _formError = null;
      _infoNote = null;
    });
    if (!_canSubmit) return;

    setState(() => _busy = true);

    final result = await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          dateOfBirth: _dateOfBirth,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (authState) {
        if (authState.isAuthenticated) {
          final name = _nameController.text.trim();
          final dob = _dateOfBirth;
          unawaited(
            ref.read(authProvider.notifier).updateProfile(
                  displayName: name,
                  dateOfBirth: dob,
                ),
          );
          context.go(Routes.ok);
        } else {
          // Email confirmation is required by Supabase — seamlessly switch
          // to OTP verification with the 60s cooldown timer.
          setState(() {
            _showOtp = true;
          });
        }
      },
      (error) {
        setState(() => _formError = error.message);
      },
    );
  }

  Future<void> _pickDate() async {
    // Mark as touched immediately: if the user cancels the picker, the
    // "Date of birth is required" message should appear, since they clearly
    // intended to set it.
    setState(() => _dobTouched = true);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return RepaintBoundary(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AuthColors.accent,
                onPrimary: Color(0xFF14161B),
                surface: Color(0xFF1A1D24),
                onSurface: AuthColors.textPrimary,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF1A1D24),
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  side: BorderSide(color: AuthColors.glassBorder, width: 1),
                ),
              ),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showOtp) {
      return AuthOtpForm(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        otpType: OtpType.signup,
        onBack: () => setState(() => _showOtp = false),
      );
    }

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Your name',
            errorText: _nameError(),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _dobController,
            label: 'Date of Birth',
            hint: 'YYYY-MM-DD',
            errorText: _dobError(),
            readOnly: true,
            suffixIcon: Icons.calendar_today_outlined,
            onSuffixTap: _pickDate,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
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
            hint: 'Minimum 8 characters',
            errorText: _passwordError(),
            obscure: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _confirmController,
            label: 'Confirm Password',
            hint: 'Repeat your password',
            errorText: _confirmError(),
            obscure: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AuthCheckboxRow(
            label: 'I agree to the Privacy Policy',
            value: _agreePrivacy,
            onChanged: (v) => setState(() => _agreePrivacy = v),
          ),
          AuthCheckboxRow(
            label: 'I agree to the Terms & Conditions',
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v),
          ),
          // TODO(user): link both agreement labels to hosted docs pages.
          const SizedBox(height: 16),
          if (_formError != null) ...[
            Text(_formError!, style: AuthText.errorText),
            const SizedBox(height: 8),
          ],
          if (_infoNote != null) ...[
            Text(_infoNote!, style: const TextStyle(
              fontSize: 12.5,
              color: AuthColors.accent,
            )),
            const SizedBox(height: 8),
          ],
          AuthSubmitTick(
            // The tick stays grey and completely inert until everything is
            // filled in AND both agreement boxes are ticked — that is the
            // requested behaviour. Live per-field errors (see the error
            // getters) are what tell the user what is still missing, so the
            // inert control never becomes a silent dead end.
            onPressed: _canSubmit ? _submit : null,
            enabled: _canSubmit,
            busy: _busy,
            semanticsLabel: 'Create account',
          ),
          const SizedBox(height: 14),
          Center(
            child: _InlineLink(
              prefix: 'Already have an account? ',
              linkLabel: 'Sign In',
              onTap: () => widget.onSwitchTab(1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _dobController.dispose();
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
