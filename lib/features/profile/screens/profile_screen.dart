import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/providers/sos_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth    = context.read<AuthProvider>();
      final profile = context.read<ProfileProvider>();
      if (auth.user != null) {
        profile.loadProfile(auth.user!.id);
      }
    });
  }

  Future<void> _dialPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make calls from this device'), backgroundColor: Colors.orange));
    }
  }

  void _showAddContactDialog(BuildContext ctx) {
    final nameCtrl     = TextEditingController();
    final phoneCtrl    = TextEditingController();
    final relationCtrl = TextEditingController();
    final formKey      = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(dctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: AppColors.borderPrimary, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Add Emergency Contact',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _dialogField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _dialogField(relationCtrl, 'Relation (e.g. Spouse)', Icons.group_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(dctx);
                        final auth = ctx.read<AuthProvider>();
                        await ctx.read<ProfileProvider>().addContact(
                          userId:   auth.user!.id,
                          name:     nameCtrl.text.trim(),
                          phone:    phoneCtrl.text.trim(),
                          relation: relationCtrl.text.trim().isEmpty
                              ? 'Contact' : relationCtrl.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyanPrimary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Add Contact',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: profile.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyanPrimary, strokeWidth: 2))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(auth, profile)),
                  SliverToBoxAdapter(child: _buildHealthProfile(profile)),
                  SliverToBoxAdapter(child: _buildContacts(context, auth, profile)),
                  SliverToBoxAdapter(child: _buildSettings(context, profile)),
                  SliverToBoxAdapter(child: _buildEventHistory(profile)),
                  SliverToBoxAdapter(child: _buildLogout(context, auth)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          const Text(
                            'v1.0.0 · Developed by NextGen Coders',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🛡️ AEGIS CRISIS INTELLIGENCE PLATFORM',
                            style: TextStyle(
                              color: AppColors.cyanPrimary.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, ProfileProvider profile) {
    final p    = profile.profile;
    final name = p?.name ?? auth.displayName;
    final email = p?.email ?? auth.email;
    final score = p?.safetyScore ?? 85;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(children: [
        Row(children: [
          const Text('Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.3), blurRadius: 10)],
            ),
            child: Text('Safety $score', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF141C30), Color(0xFF0A0E1A)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: Row(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.cyanGradient,
                boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.4), blurRadius: 16)],
              ),
              child: Center(child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900),
              )),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (p?.phone != null && p!.phone.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(p.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.cyanGlow, borderRadius: BorderRadius.circular(6)),
                  child: const Text('✓ Verified', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                if (p?.location != null && p!.location.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 11),
                  Text(p.location, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ]),
            ])),
          ]),
        ),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildHealthProfile(ProfileProvider profile) {
    final p = profile.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.favorite_rounded, color: AppColors.dangerRed, size: 18),
            SizedBox(width: 8),
            Text('Health Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          _infoRow('Blood Type', p?.bloodType ?? 'Not set', AppColors.dangerRed),
          _infoRow('Conditions', p?.medicalConditions.isNotEmpty == true ? p!.medicalConditions.join(', ') : 'None recorded', AppColors.warningOrange),
          _infoRow('Safety Score', '${p?.safetyScore ?? 85}/100', AppColors.safeGreen),
        ]),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _infoRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
      Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _buildContacts(BuildContext ctx, AuthProvider auth, ProfileProvider profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.contacts_rounded, color: AppColors.cyanPrimary, size: 18),
            const SizedBox(width: 8),
            const Text('Emergency Contacts', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddContactDialog(ctx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.black, size: 14),
                  SizedBox(width: 3),
                  Text('Add', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          if (profile.contacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No emergency contacts yet.\nTap "Add" to add your first contact.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5))),
            )
          else
            ...profile.contacts.map((c) => Dismissible(
              key: Key(c.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => profile.deleteContact(c.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: AppColors.dangerRed.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_rounded, color: AppColors.dangerRed),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.cyanGradient),
                    child: Center(child: Text(c.avatarInitial, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${c.relation} · ${c.phone}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ])),
                  GestureDetector(
                    onTap: () => _dialPhone(c.phone),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.safeGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.call_rounded, color: AppColors.safeGreen, size: 16),
                    ),
                  ),
                ]),
              ),
            )),
        ]),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildSettings(BuildContext ctx, ProfileProvider profile) {
    final sos = ctx.watch<SosProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.settings_rounded, color: AppColors.aiPurple, size: 18),
            SizedBox(width: 8),
            Text('Settings', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          _toggle('Emergency Notifications', profile.notificationsEnabled, AppColors.cyanPrimary, profile.toggleNotifications),
          _toggle('Location Sharing', profile.locationEnabled, AppColors.safeGreen, profile.toggleLocation),
          _toggle('SOS Auto-Call 911', profile.sosAutoCall, AppColors.dangerRed, profile.toggleSosAutoCall),
          _toggle('Send Alerts via WhatsApp', sos.sendViaWhatsApp, AppColors.aiPurple, sos.toggleSendViaWhatsApp),
        ]),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _toggle(String label, bool val, Color color, Function(bool) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      Switch(
        value: val,
        onChanged: onChanged,
        activeColor: color,
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? color.withOpacity(0.3) : AppColors.bgSurface),
      ),
    ]),
  );

  Widget _buildEventHistory(ProfileProvider profile) {
    final events = profile.events;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.history_rounded, color: AppColors.warningOrange, size: 18),
            SizedBox(width: 8),
            Text('Event History', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),

          if (events.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No events recorded yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ))
          else
            ...events.map((e) {
              final color = e.severity == 'CRITICAL' ? AppColors.dangerRed
                  : e.severity == 'HIGH' ? AppColors.warningOrange : AppColors.textMuted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withOpacity(0.3))),
                    child: Text(e.type, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (e.location.isNotEmpty)
                      Text(e.location, style: const TextStyle(color: AppColors.textDim, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Text(DateFormat('d MMM y').format(e.date), style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                ]),
              );
            }),
        ]),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildLogout(BuildContext ctx, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: OutlinedButton.icon(
          onPressed: () async {
            await auth.logout();
            if (ctx.mounted) ctx.go('/login');
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.dangerRed, size: 18),
          label: const Text('Sign Out', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderRed), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}
