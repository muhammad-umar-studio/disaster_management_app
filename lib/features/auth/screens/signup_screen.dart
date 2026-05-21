import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;
  bool _agreed    = false;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue'), backgroundColor: Colors.orange));
      return;
    }
    final auth   = context.read<AuthProvider>();
    final result = await auth.signUp(_name.text.trim(), _email.text.trim(), _password.text);
    if (!mounted) return;

    switch (result) {
      case SignUpResult.success:
        context.go('/home');
        break;
      case SignUpResult.confirmEmail:
        // Show email confirmation screen — already handled by needsEmailConfirmation flag
        setState(() {});
        break;
      case SignUpResult.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show confirmation screen if email confirmation is needed
    if (auth.needsEmailConfirmation) {
      return _buildConfirmEmailScreen(auth);
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: 32),
                  const Text('Create Account', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8))
                    .animate().fadeIn().slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  const Text('Join AEGIS — protect yourself and your community', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
                    .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 32),

                  // Error display
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderRed),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.dangerRed, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.dangerRedLight, fontSize: 13))),
                      ]),
                    ).animate().fadeIn().shake(),

                  _label('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDec('Your full name', Icons.person_outline_rounded),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),
                  _label('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDec('Enter your email', Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),
                  _label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDec('Min 6 characters', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),
                  // Terms checkbox
                  Row(children: [
                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _agreed ? AppColors.cyanPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _agreed ? AppColors.cyanPrimary : AppColors.borderPrimary, width: 1.5),
                        ),
                        child: _agreed ? const Icon(Icons.check_rounded, color: Colors.black, size: 14) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text.rich(TextSpan(
                      text: 'I agree to AEGIS ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      children: [
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.w600)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ))),
                  ]).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _agreed ? AppColors.cyanGradient : const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _agreed ? [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))] : [],
                      ),
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text('Create Account', style: TextStyle(color: _agreed ? Colors.black : AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 28),
                  Center(child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      children: [TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.w700))],
                    )),
                  )).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when Supabase requires email confirmation
  Widget _buildConfirmEmailScreen(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyanGlow,
                    border: Border.all(color: AppColors.borderCyan, width: 2),
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.cyanPrimary, size: 44),
                ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),
                const Text('Check your email!', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800))
                  .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  'We sent a confirmation link to\n${auth.pendingEmail}\n\nClick the link to activate your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.tips_and_updates_rounded, color: AppColors.warningOrange, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Tip: Also check your Spam/Junk folder if you don\'t see it.',
                      style: TextStyle(color: AppColors.warningOrange, fontSize: 12),
                    )),
                  ]),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.3), blurRadius: 16)]),
                    child: ElevatedButton(
                      onPressed: () {
                        auth.resetConfirmationState();
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Go to Sign In', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    auth.resetConfirmationState();
                    setState(() {});
                  },
                  child: const Text('← Back to Sign Up', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ).animate().fadeIn(delay: 550.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20));
}
