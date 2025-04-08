
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationExplanationScreen extends StatelessWidget {
  const NotificationExplanationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 80),
              const SizedBox(height: 20),
              const Text(
                'لماذا نحتاج إلى الإشعارات؟',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'نحتاج إلى إرسال إشعارات لإبلاغك بـ:\n\n'
                '• حالة طلباتك\n'
                '• العروض الخاصة\n'
                '• تحديثات مهمة في التطبيق',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.right,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final notificationService = NotificationService();
                  await notificationService.initialize();
                  Navigator.of(context).pop(true);
                },
                child: const Text('تفعيل الإشعارات'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('تخطي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
