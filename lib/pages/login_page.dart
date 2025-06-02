import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/screen/home_page.dart';
import 'register_page.dart';
import 'package:google_fonts/google_fonts.dart';

final Color primaryDarkRed = const Color(0xFFC1101F); // Rojo oscuro intenso
final Color paleSkyBlue = const Color(
  0xFFC3E5F3,
); // Azul muy claro / celeste pálido
final Color mediumGrayishBlue = const Color(0xFF679ABB); // Azul grisáceo medio
final Color veryDarkNavyBlue = const Color(
  0xFF092F49,
); // Azul marino muy oscuro

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        print('Usuario logueado: ${userCredential.user?.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al iniciar sesión';
        if (e.code == 'user-not-found') {
          errorMessage =
              'No se encontró ningún usuario con ese correo electrónico.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'La contraseña es incorrecta.';
        } else if (e.code == 'invalid-email') {
          // Agregado para un mensaje más específico
          errorMessage = 'El formato del correo electrónico es inválido.';
        } else if (e.code == 'invalid-credential') {
          // Agregado para un mensaje más específico
          errorMessage =
              'Credenciales inválidas. Verifica tu correo y contraseña.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: primaryDarkRed, // Usar el nuevo color rojo oscuro
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
            backgroundColor: primaryDarkRed, // Usar el nuevo color rojo oscuro
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

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Colores de la HomePage (MedicalAssistantScreen) actualizados con los nuevos valores
    final Color primaryBlueDark =
        veryDarkNavyBlue; // Usando el azul marino muy oscuro
    final Color primaryBlueLight =
        paleSkyBlue; // Usando el azul muy claro / celeste pálido
    final Color textColorDark = Colors.grey[800]!;
    final Color hintColorLight = Colors.grey[500]!;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
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

                Text(
                  'Bienvenido',
                  style: GoogleFonts.raleway(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.bold,
                    color:
                        primaryBlueDark, // Usar el azul oscuro de la HomePage
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'Inicia sesión para continuar',
                  style: GoogleFonts.lato(
                    fontSize: size.width * 0.04,
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
                    ), // Usar el azul claro de la HomePage
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
                        color:
                            primaryBlueDark, // Usar el azul oscuro para el enfoque
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
                    ), // Usar el azul claro de la HomePage
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
                        color:
                            primaryBlueDark, // Usar el azul oscuro para el enfoque
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
                SizedBox(height: size.height * 0.05),

                // Botón de Iniciar Sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
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
                    child: const Text('Iniciar Sesión'),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                // Botón para Navegar a Registro
                TextButton(
                  onPressed: _navigateToRegister,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        primaryBlueLight, // Usar el azul claro de la HomePage
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('¿No tienes cuenta? Regístrate aquí'),
                ),
                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
