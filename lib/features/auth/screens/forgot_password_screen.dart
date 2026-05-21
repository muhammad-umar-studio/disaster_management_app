import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_email.text.isEmpty) return;
    final ok = await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderPrimary)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 40),

                if (!_sent) ...[
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.cyanGlow,
                      border: Border.all(color: AppColors.borderCyan),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppColors.cyanPrimary, size: 32),
                  ).animate().scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 28),
                  const Text('Reset Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8))
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  const Text('Enter your email to receive a secure reset link', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5))
                    .animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 36),

                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'Enter your email address', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20)),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _send,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Send Reset Link', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                ] else ...[
                  // Success state
                  Center(child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.safeGreen.withOpacity(0.1),
                          border: Border.all(color: AppColors.safeGreen.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: AppColors.safeGreen, size: 40),
                      ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 24),
                      const Text('Check your inbox!', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(
                        'Reset link sent to\n${_email.text}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('Back to Sign In', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
