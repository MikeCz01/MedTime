import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear fechas, añade al pubspec.yaml: intl: ^0.19.0

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key});

  @override
  _AdherenceScreenState createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  final Color primaryBlueDark = const Color.fromARGB(255, 9, 42, 73);
  final Color primaryBlueLight = const Color.fromARGB(255, 100, 173, 223);
  final Color textColorDark = Colors.grey[800]!;
  final Color hintColorLight = Colors.grey[500]!;
  final Color accentGreen = Colors.green[500]!;
  final Color warningRed = Colors.red[500]!;

  DateTime _selectedDate = DateTime.now(); // La fecha actualmente seleccionada
  bool _isLoading = true;
  List<DocumentSnapshot> _medicationDocs = []; // Documentos de los medicamentos
  Map<String, bool> _adherenceStatus =
      {}; // Estado de adherencia por medicamento ID para la fecha seleccionada
  Map<String, String> _medicationTimes =
      {}; // Para guardar las horas de los medicamentos

  @override
  void initState() {
    super.initState();
    _loadDataForSelectedDate(_selectedDate);
  }

  // Carga los medicamentos del usuario y el estado de adherencia para la fecha seleccionada
  Future<void> _loadDataForSelectedDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _adherenceStatus =
          {}; // Limpiar el estado de adherencia para la nueva fecha
      _medicationTimes = {};
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Cargar todos los medicamentos del usuario
      final medicationSnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .collection('medicamentos')
              .orderBy('time', descending: false) // Ordenar por hora
              .get();

      _medicationDocs = medicationSnapshot.docs;
      for (var doc in _medicationDocs) {
        _medicationTimes[doc.id] =
            (doc.data() as Map<String, dynamic>)['time'] ?? 'N/A';
      }

      // 2. Para cada medicamento, cargar su estado de adherencia para la fecha específica
      final String dateId = DateFormat('yyyy-MM-dd').format(date);
      for (var doc in _medicationDocs) {
        final adherenceDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .collection('medicamentos')
                .doc(doc.id)
                .collection('adherencia')
                .doc(dateId)
                .get();

        setState(() {
          _adherenceStatus[doc.id] =
              adherenceDoc.exists
                  ? (adherenceDoc.data()?['taken'] ?? false)
                  : false;
        });
      }
    } catch (e) {
      print('Error loading data for adherence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar datos: $e',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: warningRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Actualiza el estado 'taken' para un medicamento y una fecha específica en Firestore
  Future<void> _updateAdherenceStatus(String medicationId, bool isTaken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String dateId = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medicationId)
          .collection('adherencia')
          .doc(dateId);

      await docRef.set(
        {
          'taken': isTaken,
          'timestamp':
              FieldValue.serverTimestamp(), // Para registrar cuándo se marcó
        },
        SetOptions(merge: true),
      ); // Usa merge para no sobrescribir otros campos si los hubiera

      setState(() {
        _adherenceStatus[medicationId] = isTaken;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado de adherencia actualizado para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
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
    } catch (e) {
      print('Error updating adherence status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar: $e',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: warningRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1), // Puedes ajustar el rango de fechas
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Hasta un año en el futuro
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlueDark, // Color principal del calendario
              onPrimary: Colors.white, // Color del texto en el color principal
              onSurface:
                  textColorDark, // Color del texto en la superficie del calendario
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    primaryBlueDark, // Color de los botones "CANCEL" y "OK"
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDataForSelectedDate(
        _selectedDate,
      ); // Recargar datos para la nueva fecha
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlueDark,
        title: Text(
          'Historial de Adherencia',
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Selector de fecha
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: primaryBlueLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlueLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: textColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: primaryBlueDark),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryBlueDark,
                        ),
                      ),
                    )
                    : _medicationDocs.isEmpty
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
                            'Aún no tienes medicamentos registrados.',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              color: hintColorLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Agrega medicamentos desde la pantalla principal para ver su historial.',
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
                      itemCount: _medicationDocs.length,
                      itemBuilder: (context, index) {
                        var doc = _medicationDocs[index];
                        var medicationName =
                            (doc.data() as Map<String, dynamic>)['name'] ??
                            'Medicamento sin nombre';
                        var medicationTime = _medicationTimes[doc.id] ?? 'N/A';
                        bool isTaken =
                            _adherenceStatus[doc.id] ??
                            false; // Obtener el estado de adherencia para el ID del medicamento

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              medicationName,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColorDark,
                              ),
                            ),
                            subtitle: Text(
                              'Hora: $medicationTime - Estado: ${isTaken ? 'Tomado' : 'Pendiente'}',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: hintColorLight,
                              ),
                            ),
                            value: isTaken,
                            onChanged: (bool value) {
                              // Solo permitir cambios si la fecha seleccionada es hoy o en el pasado
                              if (_selectedDate.day == DateTime.now().day &&
                                  _selectedDate.month == DateTime.now().month &&
                                  _selectedDate.year == DateTime.now().year) {
                                _updateAdherenceStatus(doc.id, value);
                              } else if (_selectedDate.isBefore(
                                DateTime.now(),
                              )) {
                                _updateAdherenceStatus(
                                  doc.id,
                                  value,
                                ); // Permitir actualizar el pasado
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No puedes marcar medicamentos para fechas futuras.',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: warningRed,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              }
                            },
                            activeColor: accentGreen,
                            inactiveThumbColor: primaryBlueLight,
                            inactiveTrackColor: primaryBlueLight.withOpacity(
                              0.5,
                            ),
                            activeTrackColor: accentGreen.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
