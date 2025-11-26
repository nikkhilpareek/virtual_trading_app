import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create 15 mock notifications with some read and some unread
    final notifications = List.generate(15, (i) {
      return {
        'title': 'Notification ${i + 1}',
        'message': i % 3 == 0
            ? 'Your order executed successfully.'
            : 'New market insight available.',
        'time': '${(i % 12) + 1}h ago',
        'isRead': i % 4 == 0, // some read, some unread
      };
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            for (var n in notifications)
              _buildNotificationTile(
                context: context,
                title: n['title'] as String,
                message: n['message'] as String,
                time: n['time'] as String,
                isRead: n['isRead'] as bool,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required BuildContext context,
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isRead
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications,
              color: isRead
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha((0.6 * 255).round()),
                ),
              ),
              const SizedBox(height: 8),
              if (!isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
