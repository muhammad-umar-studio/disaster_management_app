import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_email.text.trim(), _password.text);
    if (ok && mounted) context.go('/home');
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                  const SizedBox(height: 48),

                  // Logo
                   Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AEGIS', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('CRISIS INTELLIGENCE', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    ]),
                  ]).animate().fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 52),

                  const Text('Welcome back', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8))
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  const Text('Sign in to your AEGIS command center', style: TextStyle(color: AppColors.textSecondary, fontSize: 15))
                    .animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 32),

                  // Error banner
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

                  // Email
                  _label('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDec('Enter your email', Icons.email_outlined),
                    validator: (v) => v!.isEmpty ? 'Email is required' : !v.contains('@') ? 'Invalid email' : null,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // Password
                  _label('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDec('Enter your password', Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Sign In button
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Sign In', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: AppColors.borderPrimary)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text('or continue with', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderPrimary)),
                  ]),

                  const SizedBox(height: 20),

                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: auth.isLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppColors.bgCard,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // Google G logo
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 14, fontWeight: FontWeight.w900, height: 1)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Continue with Google', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 32),
                  Center(child: GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: RichText(text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      children: [TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.w700))],
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

  Widget _label(String text) => Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3));

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
  );
}
