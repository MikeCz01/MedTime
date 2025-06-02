// register_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ¡Importa GoogleFonts!

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        print('Usuario registrado: ${userCredential.user?.uid}');
        Navigator.pop(context); // Volver a la pantalla de inicio de sesión
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuario registrado exitosamente',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: Colors.green[400], // SnackBar de éxito
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al registrar usuario';
        if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Ya existe una cuenta con ese correo electrónico.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El correo electrónico no es válido.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: Colors.red[400], // SnackBar de error
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ocurrió un error inesperado. Inténtalo de nuevo.',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Colores de la HomePage (MedicalAssistantScreen)
    final Color primaryBlueDark = Colors.lightBlue[900]!; // Color del AppBar
    final Color primaryBlueLight = const Color.fromARGB(
      255,
      100,
      173,
      223,
    ); // Color de los mensajes del asistente
    final Color textColorDark = Colors.grey[800]!;
    final Color hintColorLight = Colors.grey[500]!;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
      appBar: AppBar(
        backgroundColor: primaryBlueDark, // Usar el azul oscuro de la HomePage
        title: Text(
          'Crear Cuenta',
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Color del ícono de retroceso
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Mantengo el Image.asset. Asegúrate que 'lib/images/logo.png' exista y esté configurado
                Image.asset('lib/images/1.jpg', height: size.height * 0.15),
                SizedBox(height: size.height * 0.05),

                // Título "Regístrate" con estilo profesional
                Text(
                  'Regístrate',
                  style: GoogleFonts.raleway(
                    fontSize: size.width * 0.08, // Tamaño responsivo
                    fontWeight: FontWeight.bold,
                    color:
                        primaryBlueDark, // Usar el azul oscuro de la HomePage
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                // Subtítulo
                Text(
                  'Crea tu cuenta para acceder',
                  style: GoogleFonts.lato(
                    fontSize: size.width * 0.04, // Tamaño responsivo
                    color: hintColorLight,
                  ),
                ),
                SizedBox(height: size.height * 0.06),

                // Campo de Correo Electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.lato(fontSize: 16, color: textColorDark),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: GoogleFonts.lato(color: hintColorLight),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: primaryBlueLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: primaryBlueDark,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 12.0,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu correo electrónico';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, introduce un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.03),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.lato(fontSize: 16, color: textColorDark),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.lato(color: hintColorLight),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: primaryBlueLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: primaryBlueDark,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 12.0,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.03),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: GoogleFonts.lato(fontSize: 16, color: textColorDark),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    labelStyle: GoogleFonts.lato(color: hintColorLight),
                    prefixIcon: Icon(
                      Icons
                          .lock_reset_outlined, // Icono para confirmar contraseña
                      color: primaryBlueLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: primaryBlueDark,
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 12.0,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.05),

                // Botón de Crear Cuenta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryBlueDark, // Usar el azul oscuro de la HomePage
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                    ),
                    child: const Text('Crear Cuenta'),
                  ),
                ),
                SizedBox(height: size.height * 0.02), // Margen inferior
              ],
            ),
          ),
        ),
      ),
    );
  }
}
