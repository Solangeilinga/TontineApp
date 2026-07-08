// lib/screens/membre/membre_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class MembreNotificationsScreen extends StatefulWidget {
  const MembreNotificationsScreen({super.key});

  @override
  State<MembreNotificationsScreen> createState() =>
      _MembreNotificationsScreenState();
}

class _MembreNotificationsScreenState
    extends State<MembreNotificationsScreen> {
  final _api = ApiService();
  List<NotificationModel> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final res = await _api.dio.get('/notifications');
      final list = res.data['data']['notifications'] as List;
      setState(() {
        _notifs = list.map((j) => NotificationModel.fromJson(j)).toList();
      });
      // Marquer toutes comme lues
      await _api.dio.patch('/notifications/read-all');
    } catch (_) {
    } finally {
      setState(() { _loading = false; });
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'REMINDER_J1':
      case 'REMINDER_J2': return Icons.alarm;
      case 'CONTRIBUTION_CONFIRMED': return Icons.check_circle_outline;
      case 'MEMBER_JOINED': return Icons.person_add_outlined;
      case 'YOUR_TURN': return Icons.emoji_events_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'REMINDER_J1': return AppColors.error;
      case 'REMINDER_J2': return AppColors.warning;
      case 'CONTRIBUTION_CONFIRMED': return AppColors.success;
      case 'YOUR_TURN': return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return Formatters.date(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/membre/home')),
        title: const Text('Notifications'),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MemberListSkeleton(count: 5),
            )
          : _notifs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 56, color: AppColors.textHint),
                      SizedBox(height: AppSpacing.md),
                      Text('Aucune notification',
                          style: AppTextStyles.h4),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Vos rappels de cotisation apparaîtront ici',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = _notifs[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? AppColors.surface
                              : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: n.isRead
                                ? AppColors.border
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _typeColor(n.type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _typeIcon(n.type),
                              color: _typeColor(n.type),
                              size: 20,
                            ),
                          ),
                          title: Text(n.title,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 14,
                              )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message,
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 2),
                              Text(
                                _timeAgo(n.sentAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                          trailing: !n.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// Import manquant
class Formatters {
  static String date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}