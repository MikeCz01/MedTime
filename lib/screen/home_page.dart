import 'package:flutter/material.dart';
import 'package:firstapp/pages/login_page.dart'; // Asegúrate de importar tu LoginPage
import '/screen/history_screen.dart'; // Asumiendo que esta es la ruta correcta para AdherenceScreen
import '/screen/medical_assistant_screen.dart';
import '/screen/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<DocumentSnapshot> medicationDocs = [];

  // Colores de la HomePage (MedicalAssistantScreen)
  final Color primaryBlueDark = const Color.fromARGB(
    255,
    9,
    42,
    73,
  ); // Color del AppBar
  final Color primaryBlueLight = const Color.fromARGB(
    255,
    24,
    91,
    135,
  ); // Color de los mensajes del asistente
  final Color accentGreen = Colors.green[400]!; // Para acciones positivas
  final Color errorRed = Colors.red[400]!; // Para acciones de eliminar/error
  final Color textColorDark = Colors.grey[800]!;
  final Color hintColorLight = Colors.grey[500]!;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true; // Activar indicador de carga antes de la operación
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .collection('medicamentos')
                .orderBy(
                  'time',
                  descending: false,
                ) // Opcional: ordenar por hora
                .get();
        if (mounted) {
          // Check if the widget is still mounted before setState
          setState(() {
            medicationDocs = snapshot.docs; // Almacena los documentos completos
          });
        }
      } catch (e) {
        print('Error loading medications: $e');
        if (mounted) {
          // Check if the widget is still mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al cargar medicamentos: $e',
                style: GoogleFonts.roboto(color: Colors.white),
              ),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          // Always check before setState in async operations
          setState(() {
            _isLoading = false; // Desactivar indicador de carga al finalizar
          });
        }
      }
    } else {
      if (mounted) {
        // Also check here
        setState(() {
          _isLoading = false; // También desactivar si no hay usuario
        });
      }
    }
  }

  Future<void> _addMedicationToFirebase(String name, String time) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('medicamentos')
          .add({'name': name, 'time': time});
      await _loadMedications(); // Recargar la lista después de añadir
      if (mounted) {
        // Check before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento agregado exitosamente',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: accentGreen,
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

  Future<void> _editMedicationInFirebase(
    String docId, // Usamos directamente el docId
    String newName,
    String newTime,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(docId)
          .update({'name': newName, 'time': newTime});
      await _loadMedications(); // Recargar la lista después de editar
      if (mounted) {
        // Check before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento actualizado exitosamente',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: accentGreen,
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

  Future<void> _deleteMedicationFromFirebase(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(docId)
          .delete();
      await _loadMedications(); // Recargar la lista después de eliminar
      if (mounted) {
        // Check before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento eliminado',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: errorRed,
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

  void _addMedication() {
    _showAddMedicationDialog(
      onSave: (newName, newTime) {
        _addMedicationToFirebase(newName, newTime);
      },
    );
  }

  void _editMedication(int index) {
    if (index < medicationDocs.length) {
      final doc = medicationDocs[index];
      final docId = doc.id;
      final medicationData =
          doc.data() as Map<String, dynamic>; // Castear a Map<String, dynamic>
      _showEditMedicationDialog(
        medication: medicationData,
        onSave: (newName, newTime) {
          _editMedicationInFirebase(docId, newName, newTime);
        },
      );
    }
  }

  void _deleteMedication(int index) {
    if (index < medicationDocs.length) {
      final docId = medicationDocs[index].id;
      _showDeleteConfirmationDialog(docId);
    }
  }

  void _showTimePicker(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        // Aplicar tema al TimePicker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlueDark, // Color del header y botones
              onPrimary: Colors.white, // Color del texto en el header
              onSurface: textColorDark, // Color del texto en el calendario
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    primaryBlueDark, // Color de los botones (CANCELAR, OK)
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = picked.format(context);
      controller.text = formatted;
    }
  }

  void _showAddMedicationDialog({
    required Function(String name, String time) onSave,
  }) {
    final nameController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => // Use a different context variable for the dialog
              AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Text(
              'Agregar Medicamento',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: primaryBlueDark,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.lato(color: textColorDark),
                  decoration: InputDecoration(
                    labelText: 'Nombre del medicamento',
                    labelStyle: GoogleFonts.lato(color: hintColorLight),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryBlueDark,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTimePicker(timeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeController,
                      style: GoogleFonts.lato(color: textColorDark),
                      decoration: InputDecoration(
                        labelText: 'Hora',
                        labelStyle: GoogleFonts.lato(color: hintColorLight),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryBlueDark,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(dialogContext).pop(), // Use dialogContext
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.lato(color: primaryBlueLight),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      timeController.text.isNotEmpty) {
                    onSave(nameController.text, timeController.text);
                    Navigator.of(dialogContext).pop(); // Use dialogContext
                  } else {
                    if (mounted) {
                      // Check before showing SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Por favor, llena ambos campos.',
                            style: GoogleFonts.roboto(color: Colors.white),
                          ),
                          backgroundColor: errorRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Agregar',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditMedicationDialog({
    required Map<String, dynamic> medication,
    required Function(String name, String time) onSave,
  }) {
    final nameController = TextEditingController(text: medication['name']);
    final timeController = TextEditingController(text: medication['time']);

    showDialog(
      context: context,
      builder:
          (dialogContext) => // Use a different context variable for the dialog
              AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Text(
              'Editar Medicamento',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: primaryBlueDark,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.lato(color: textColorDark),
                  decoration: InputDecoration(
                    labelText: 'Nombre del medicamento',
                    labelStyle: GoogleFonts.lato(color: hintColorLight),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryBlueDark,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTimePicker(timeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeController,
                      style: GoogleFonts.lato(color: textColorDark),
                      decoration: InputDecoration(
                        labelText: 'Hora',
                        labelStyle: GoogleFonts.lato(color: hintColorLight),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryBlueDark,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(dialogContext).pop(), // Use dialogContext
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.lato(color: primaryBlueLight),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      timeController.text.isNotEmpty) {
                    onSave(nameController.text, timeController.text);
                    Navigator.of(dialogContext).pop(); // Use dialogContext
                  } else {
                    if (mounted) {
                      // Check before showing SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Por favor, llena ambos campos.',
                            style: GoogleFonts.roboto(color: Colors.white),
                          ),
                          backgroundColor: errorRed,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Guardar',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use a different context variable for the dialog
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Confirmar Eliminación',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: primaryBlueDark,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar este medicamento?',
            style: GoogleFonts.lato(color: textColorDark),
          ),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => Navigator.of(dialogContext).pop(), // Use dialogContext
              child: Text(
                'Cancelar',
                style: GoogleFonts.lato(color: primaryBlueLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteMedicationFromFirebase(docId);
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, // Rojo para eliminar
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Eliminar',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAdherenceScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const AdherenceScreen(), // <--- ¡Sin el parámetro 'medications'!
      ),
    );
  }

  void _navigateToMedicalAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicalAssistantScreen()),
    );
  }

  void _navigateToProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Después de cerrar sesión, navega a la LoginPage y elimina todas las rutas anteriores
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cerrar sesión. Inténtalo de nuevo. Detalles: $e',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: errorRed,
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
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
      appBar: AppBar(
        backgroundColor: primaryBlueDark, // Color oscuro de la HomePage
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.account_circle, color: Colors.white),
              onPressed: _navigateToProfileScreen,
              tooltip: 'Perfil',
            ),
            SizedBox(width: 8.0),
            Text(
              'Mis Medicamentos',
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.medical_services, color: Colors.white),
            onPressed: _navigateToMedicalAssistant,
            tooltip: 'Asistente Médico',
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: _navigateToAdherenceScreen,
            tooltip: 'Historial', // Añadir tooltip
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.logout, color: Colors.white),
            onSelected: (String result) {
              if (result == 'logout') {
                _logout(); // Llama a la función de cerrar sesión
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      // Usar un Row para el icono y el texto
                      children: [
                        Icon(
                          Icons.logout, // Icono de cerrar sesión
                          color: errorRed, // Color del icono (rojo para salida)
                        ),
                        SizedBox(width: 10), // Espacio entre icono y texto
                        Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.lato(
                            color:
                                errorRed, // Color del texto (rojo para salida)
                            fontWeight:
                                FontWeight
                                    .w600, // Hacer el texto un poco más audaz
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Agrega más PopupMenuItem si necesitas otras opciones de ajuste
                ],
            tooltip: 'Ajustes',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        backgroundColor: primaryBlueDark, // Color del FAB
        foregroundColor: Colors.white, // Color del icono del FAB
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ), // Forma circular
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: primaryBlueDark, // Color del BottomAppBar
        child: Container(height: 50.0),
      ),
      body: Container(
        color: const Color.fromARGB(255, 195, 229, 243),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Próximas dosis',
                    style: GoogleFonts.raleway(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryBlueDark, // Color del título de sección
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryBlueDark,
                          ), // Color del indicador de carga
                        ),
                      )
                      : medicationDocs
                          .isEmpty // Comprobar si no hay medicamentos después de la carga
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 60,
                              color: hintColorLight,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tienes medicamentos registrados.',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                color: hintColorLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Presiona "+" para agregar uno.',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                color: hintColorLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: medicationDocs.length,
                        itemBuilder: (context, index) {
                          final medicationData =
                              medicationDocs[index].data()
                                  as Map<String, dynamic>;
                          return MedCard(
                            medName: medicationData['name']!,
                            time: medicationData['time']!,
                            onEdit: () => _editMedication(index),
                            onDelete: () => _deleteMedication(index),
                            primaryBlueLight:
                                primaryBlueLight, // Pasar color al MedCard
                            errorRed: errorRed, // Pasar color al MedCard
                            textColorDark: textColorDark,
                            hintColorLight: hintColorLight,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedCard extends StatelessWidget {
  final String medName;
  final String time;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryBlueLight;
  final Color errorRed;
  final Color textColorDark;
  final Color hintColorLight;

  const MedCard({
    super.key,
    required this.medName,
    required this.time,
    required this.onEdit,
    required this.onDelete,
    required this.primaryBlueLight,
    required this.errorRed,
    required this.textColorDark,
    required this.hintColorLight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4, // Sombra para el efecto de tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Bordes redondeados
      color: Colors.white, // Fondo blanco para la tarjeta
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.medication_outlined,
          color: primaryBlueLight,
          size: 30,
        ), // Icono más moderno
        title: Text(
          medName,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColorDark,
          ),
        ),
        subtitle: Text(
          'Tomar a las $time',
          style: GoogleFonts.lato(fontSize: 15, color: hintColorLight),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: primaryBlueLight,
              ), // Color de los iconos de acción
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: errorRed,
              ), // Color rojo para eliminar
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
