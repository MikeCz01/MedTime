import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firstapp/screen/health_history_screen.dart';
import 'package:image_picker/image_picker.dart'; // Importamos el paquete image_picker
import 'dart:io'; // Importamos dart:io para trabajar con archivos

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _sintomasController = TextEditingController();
  final _presionArterialController = TextEditingController();
  final _ritmoCardiacoController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _otrosController = TextEditingController();
  File? _profileImage; // Variable para almacenar la imagen seleccionada
  final ImagePicker _picker = ImagePicker();

  Future<void> _guardarInformacion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_salud')
          .add({
            'sintomas': _sintomasController.text,
            'presion_arterial': _presionArterialController.text,
            'ritmo_cardiaco': _ritmoCardiacoController.text,
            'temperatura': _temperaturaController.text,
            'otros': _otrosController.text,
            'fecha': formattedDate,
            // Aquí podrías guardar la ruta local de la imagen o la URL si la cargas a Storage
            'profile_image_path':
                _profileImage?.path, // Solo la ruta local por ahora
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Información guardada')));

      _sintomasController.clear();
      _presionArterialController.clear();
      _ritmoCardiacoController.clear();
      _temperaturaController.clear();
      _otrosController.clear();
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 9, 42, 73)!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 9, 42, 73)!,
              width: 2.0,
            ),
          ),
          prefixIcon:
              prefixIcon != null
                  ? Icon(
                    prefixIcon,
                    color: const Color.fromARGB(255, 9, 42, 73),
                  )
                  : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil de Salud',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 9, 42, 73),
        elevation: 3,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HealthHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildProfileImageSection(), // Nueva sección para la imagen de perfil
            SizedBox(height: 30.0),
            Text(
              'Ingresa tu información de salud del día:',
              style: GoogleFonts.openSans(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 9, 42, 73),
              ),
            ),
            SizedBox(height: 15.0),
            _buildTextField(
              labelText: 'Síntomas del día',
              controller: _sintomasController,
              maxLines: 3,
              prefixIcon: Icons.report_problem_outlined,
            ),
            _buildTextField(
              labelText: 'Presión Arterial (ej: 120/80)',
              controller: _presionArterialController,
              keyboardType: TextInputType.text,
              prefixIcon: Icons.bloodtype_outlined,
            ),
            _buildTextField(
              labelText: 'Ritmo Cardíaco (latidos por minuto)',
              controller: _ritmoCardiacoController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.favorite_border,
            ),
            _buildTextField(
              labelText: 'Temperatura (°C o °F)',
              controller: _temperaturaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.thermostat_outlined,
            ),
            _buildTextField(
              labelText: 'Otros detalles (opcional)',
              controller: _otrosController,
              maxLines: 2,
              prefixIcon: Icons.notes_outlined,
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: _guardarInformacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 9, 42, 73),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              child: Text(
                'Guardar Información',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60.0,
            backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
            backgroundColor: const Color.fromARGB(255, 9, 42, 73),
            child:
                _profileImage == null
                    ? Icon(Icons.person, size: 60.0, color: Colors.white)
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _pickImage,
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 9, 42, 73),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // El CircleAvatar ahora se construye en _buildProfileImageSection()
        SizedBox(width: 20.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tu Perfil',
                style: GoogleFonts.raleway(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 9, 42, 73),
                ),
              ),
              SizedBox(height: 5.0),
              Text(
                'Mantén un registro de tu salud diaria',
                style: GoogleFonts.openSans(
                  fontSize: 14.0,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
