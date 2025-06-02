import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Cambiamos a StatefulWidget para poder actualizar la lista tras eliminar un registro
class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  // Creamos un Future para recargar los datos
  late Future<QuerySnapshot> _healthRecordsFuture;

  @override
  void initState() {
    super.initState();
    _healthRecordsFuture = _fetchHealthRecords(); // Inicializamos el Future
  }

  // Función para obtener los registros de salud desde Firestore
  Future<QuerySnapshot> _fetchHealthRecords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Devolver un Future.error si el usuario no está logueado
      return Future.error('Usuario no autenticado');
    }
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('registros_salud')
        .orderBy('fecha', descending: true)
        .get();
  }

  // Función para eliminar un registro
  Future<void> _deleteRecord(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return;
    }

    // Mostrar un diálogo de confirmación antes de eliminar
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                'Confirmar Eliminación',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
              content: Text(
                '¿Estás seguro de que quieres eliminar este registro de salud?',
                style: GoogleFonts.openSans(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false); // No eliminar
                  },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.montserrat(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(true); // Confirmar eliminación
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent, // Color para el botón de eliminar
                  ),
                  child: Text(
                    'Eliminar',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Valor por defecto si el diálogo se cierra sin seleccionar

    if (!confirmDelete) {
      return; // Si el usuario cancela, no hacemos nada
    }

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_salud')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado exitosamente.')),
      );

      // Recargamos los datos para actualizar la UI
      setState(() {
        _healthRecordsFuture = _fetchHealthRecords();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el registro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 9, 42, 73)!;
    final Color accentColor = Colors.lightBlue[500]!;
    final Color textColor = Colors.grey[800]!;
    final Color lightTextColor = Colors.grey[600]!;
    final Color cardColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tu Historial de Salud',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _healthRecordsFuture, // Usamos el Future que se puede recargar
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Ha ocurrido un error al cargar los datos.',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: lightTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Intenta de nuevo más tarde.',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: lightTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: primaryColor,
                    size: 60,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '¡Aún no hay registros de salud!',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Comienza a añadir tu información desde la pantalla de perfil.',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: lightTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot doc =
                  snapshot.data!.docs[index]; // Obtenemos el DocumentSnapshot
              final registro = doc.data() as Map<String, dynamic>;
              final String docId = doc.id; // Obtenemos el ID del documento

              String fechaDisplay = registro['fecha'] ?? 'Fecha desconocida';
              try {
                DateTime parsedDate = DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).parse(fechaDisplay);
                fechaDisplay = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(parsedDate);
              } catch (e) {
                if (registro['fecha'] is Timestamp) {
                  Timestamp ts = registro['fecha'] as Timestamp;
                  fechaDisplay = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(ts.toDate());
                }
              }

              return Card(
                color: cardColor,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween, // Para alinear la fecha y el icono
                        children: [
                          Text(
                            fechaDisplay,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryColor,
                            ),
                          ),
                          // Botón de eliminar
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                            tooltip: 'Eliminar registro',
                            onPressed:
                                () => _deleteRecord(
                                  docId,
                                ), // Llamamos a la función de eliminación
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 0.8),

                      _buildHealthDetail(
                        icon: Icons.sick_outlined,
                        label: 'Síntomas',
                        value: registro['sintomas'],
                        textColor: textColor,
                      ),
                      _buildHealthDetail(
                        icon: Icons.monitor_heart_outlined,
                        label: 'Presión Arterial',
                        value: registro['presion_arterial'],
                        textColor: textColor,
                      ),
                      _buildHealthDetail(
                        icon: Icons.favorite_border,
                        label: 'Ritmo Cardíaco',
                        value: registro['ritmo_cardiaco'],
                        textColor: textColor,
                      ),
                      _buildHealthDetail(
                        icon: Icons.thermostat_outlined,
                        label: 'Temperatura',
                        value: registro['temperatura'],
                        textColor: textColor,
                      ),
                      _buildHealthDetail(
                        icon: Icons.notes_outlined,
                        label: 'Otros Detalles',
                        value: registro['otros'],
                        textColor: textColor,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHealthDetail({
    required IconData icon,
    required String label,
    required dynamic value,
    required Color textColor,
    bool isLast = false,
  }) {
    final String displayValue =
        (value != null && value.isNotEmpty)
            ? value.toString()
            : 'No especificado';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey[700], size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label:',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    displayValue,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) SizedBox(height: 12),
      ],
    );
  }
}
