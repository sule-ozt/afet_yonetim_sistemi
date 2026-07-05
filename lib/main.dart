import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/volunteer_home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/education_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/manager_panel.dart';
import 'screens/create_disaster_screen.dart';
import 'screens/disaster_list_screen.dart';
import 'screens/disaster_detail_screen.dart';
import 'screens/map_screen.dart';
import 'screens/user_map_screen.dart';
import 'screens/assign_task_screen.dart';
import 'screens/send_emergency_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'screens/emergency_responses_screen.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 [Arka planda] Bildirim alındı: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Uygulama açıkken gelen bildirimleri yakala
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 [Ön planda] Bildirim geldi!");
      print("🔔 Başlık: ${message.notification?.title}");
      print("📝 İçerik: ${message.notification?.body}");
    });

    // Uygulama kapalıyken bildirime tıklanınca özel ekran aç
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 [Tıklandı] Bildirime tıklandı.");
      if (message.data['type'] == 'emergency') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyAlertScreen(data: message.data),
          ),
        );
      }
    });

    return MaterialApp(
      title: 'Afet Yönetim Sistemi',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/volunteer': (context) => const VolunteerPanel(),
        '/admin': (context) => const AdminDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/education': (context) => const EducationScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/manager': (context) => const ManagerPanel(),
        '/create-disaster': (context) => const CreateDisasterScreen(),
        '/disasters': (context) => const DisasterListScreen(),
        '/disaster-detail': (context) => const DisasterDetailScreen(),
        '/map': (context) => const MapScreen(),
        '/user-map': (context) => const UserMapScreen(),
        '/assign-task': (context) => const AssignTaskScreen(),
        '/volunteerHome': (context) => const VolunteerPanel(),
        '/managerHome': (context) => const ManagerPanel(),
        '/adminHome': (context) => const AdminDashboard(),
        '/send-emergency': (context) => const SendEmergencyScreen(),
        '/emergency-responses': (context) => const EmergencyResponsesScreen(),
      },
    );
  }
}
