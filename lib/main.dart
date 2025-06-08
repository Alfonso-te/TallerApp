import 'package:flutter/material.dart';
import 'package:taller_mecanico/Funcionalidad/notification_service.dart';
import 'package:taller_mecanico/screens/profile_screen.dart';
import 'package:taller_mecanico/screens/vehicle_detail.screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'conexion/firebase_options.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar notificaciones
  await NotificationService().initialize();
  
  runApp(const MyApp()); 
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taller Mecánico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home', // Ruta inicial
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(), 
        '/add-vehicle': (context) => const AddVehicleScreen(),
        '/vehicle_detail':(context) => const VehicleDetailScreen(vehicleId: '',),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}