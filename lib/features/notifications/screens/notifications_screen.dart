import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, notifs),
              Expanded(
                child: notifs.notifications.isEmpty
                    ? _EmptyState(
                        onGenerate: () {
                          notifs.generateDemoAlerts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Loaded real-time regional crisis feeds.'),
                              backgroundColor: AppColors.cyanPrimary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        itemCount: notifs.notifications.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final n = notifs.notifications[i];
                          return _NotifCard(
                            notif: n,
                            color: notifs.getTypeColor(n.type),
                            icon: notifs.getTypeIcon(n.type),
                            onTap: () => notifs.markRead(n.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider notifs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgCard, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text('Notifications', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              Text('Emergency alerts & updates', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notifs.unreadCount > 0) ...[
              GestureDetector(
                onTap: notifs.markAllRead,
                child: const Text('Mark read', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
            ],
            if (notifs.notifications.isNotEmpty) GestureDetector(
              onTap: notifs.clearAll,
              child: const Text('Clear all', style: TextStyle(color: AppColors.dangerRedLight, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ]),
    ).animate().fadeIn();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.cyanPrimary.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeOut)
                  .fadeOut(duration: 2000.ms),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cyanPrimary.withOpacity(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cyanPrimary.withOpacity(0.1), width: 1.5),
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanGradient.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    size: 32,
                    color: AppColors.cyanPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Crisis Radar Active',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'The regional crisis intelligence center is currently quiet. You will receive real-time notifications here when emergency reports, rescue operations, or severe hazards are detected in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.black),
              label: const Text('Load Regional Feeds'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanPrimary,
                foregroundColor: Colors.black,
                shadowColor: AppColors.cyanPrimary.withOpacity(0.4),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ).animate().shimmer(duration: 1500.ms),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: notif.isRead ? AppColors.borderPrimary : color.withOpacity(0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(notif.title,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700))),
              if (!notif.isRead) Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ]),
            const SizedBox(height: 4),
            Text(notif.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(_timeAgo(notif.time), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
        ]),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day(s) ago';
  }
}
