import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts_styles.dart';
import '../../core/constants/services/auth_service.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _linkSent = false;
  String? _errorMessage;
  bool _isCooldown = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _isCooldown = true;
      _cooldownSeconds = 60;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownSeconds <= 1) {
          _isCooldown = false;
          timer.cancel();
        } else {
          _cooldownSeconds--;
        }
      });
    });
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      setState(() {
        _linkSent = true;
      });
      // ADD THIS LINE:
      _startCooldown(); // Starts the 60 second cooldown
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Unable to send reset link. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _linkSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Reset Your Password',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 4),
          Text(
            "Enter the email you use to log in.\nWe'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: AppTextStyles.bodySecondary,
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLoading || _isCooldown)
                  ? null
                  : _handleSendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isCooldown
                          ? 'Wait ${_cooldownSeconds}s'
                          : 'Send Reset Link',
                      style: AppTextStyles.button,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        Icon(Icons.mark_email_read_rounded, size: 72, color: AppColors.primary),
        const SizedBox(height: 20),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to:\n${_emailController.text.trim()}\n\nOpen the link on your phone to set a new password, then come back here and log in.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Log In',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
