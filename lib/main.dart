import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ¡Importa esto!
import 'package:firstapp/pages/login_page.dart'; // Tu LoginPage
import 'package:firstapp/screen/home_page.dart'; // Tu HomePage (asegúrate de que esta ruta sea correcta)
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que los widgets de Flutter estén inicializados
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inicializa Firebase

  runApp(const MedReminderApp());
}

class MedReminderApp extends StatelessWidget {
  const MedReminderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedReminder',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance
                .authStateChanges(), // Escucha si hay un usuario logueado o si el estado cambia
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error al cargar la aplicación.')),
            );
          }
          if (snapshot.hasData) {
            return const HomePage(); // El usuario está logueado, ve a la pantalla principal
          } else {
            // Si el snapshot no tiene datos (o snapshot.data es null), no hay usuario logueado
            return const LoginPage(); // El usuario no está logueado, ve a la pantalla de inicio de sesión
          }
        },
      ),
      // *** FIN DEL CAMBIO PRINCIPAL ***
    );
  }
}
