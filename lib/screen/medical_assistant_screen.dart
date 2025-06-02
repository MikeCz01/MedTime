import 'dart:convert';
import 'dart:io'; // Para manejar archivos
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart'; // Importa image_picker
// Importa path_provider

class MedicalAssistantScreen extends StatefulWidget {
  const MedicalAssistantScreen({super.key});

  @override
  _MedicalAssistantScreenState createState() => _MedicalAssistantScreenState();
}

class _MedicalAssistantScreenState extends State<MedicalAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker(); // Instancia de ImagePicker

  final String apiKey = "AIzaSyCLrQ-ZgRfQfQNc2_Is5hfaBo0kIoGdlX4";
  // Usaremos un modelo que soporte multimodal (gemini-pro-vision o gemini-1.5-flash)
  final String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

  File? _selectedImage;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Función para seleccionar una imagen de la galería o cámara
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    ); // Reducir calidad para optimizar
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Opcional: si quieres enviar la imagen sin texto adicional, llama a _sendMessage aquí
      // _sendMessage('');
    }
  }

  Future<void> _sendMessage({String? text, File? image}) async {
    // Si no hay texto ni imagen, no hagas nada
    if ((text == null || text.trim().isEmpty) && image == null) {
      return;
    }

    String? base64Image;
    if (image != null) {
      // Convertir la imagen a Base64
      List<int> imageBytes = await image.readAsBytes();
      base64Image = base64Encode(imageBytes);

      // Añadir la imagen al historial de mensajes
      setState(() {
        _messages.add({
          'role': 'user',
          'imagePath': image.path,
          'content': text,
        });
      });
    } else {
      // Si solo hay texto, añadirlo al historial de mensajes
      setState(() {
        _messages.add({'role': 'user', 'content': text});
      });
    }
    _scrollToBottom();
    _controller.clear(); // Limpiar el campo de texto inmediatamente

    try {
      final List<Map<String, dynamic>> parts = [];

      // Si hay texto, añadirlo como una parte
      if (text != null && text.trim().isNotEmpty) {
        parts.add({"text": text.trim()});
      }

      // Si hay una imagen, añadirla como una parte de imagen
      if (base64Image != null) {
        parts.add({
          "inlineData": {
            "mimeType": "image/jpeg", // O "image/png" dependiendo del formato
            "data": base64Image,
          },
        });
      }

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {"parts": parts},
          ],
          "generationConfig": {
            "temperature": 0.7, // Ajusta la creatividad de la respuesta
            "topP": 0.9,
            "topK": 40,
          },
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content =
            decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Sin respuesta';
        setState(() {
          _messages.add({'role': 'assistant', 'content': content});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Error ${response.statusCode}: ${response.body}',
          });
        });
      }
    } catch (e) {
      print('Error al enviar mensaje: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Error al conectar con el servidor: $e',
        });
      });
    }

    // Limpiar la imagen seleccionada después de enviar el mensaje
    setState(() {
      _selectedImage = null;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:
              Curves
                  .easeOut, // Cambiado a easeOut para un desplazamiento más natural
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['role'] == 'user';
    final content = message['content'] as String? ?? '';
    final imagePath = message['imagePath'] as String?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isUser
                  ? Colors.blue[100]
                  : const Color.fromARGB(255, 100, 173, 223),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.75, // Limita el ancho del mensaje
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (content.isNotEmpty)
              MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
                  h1: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                  h2: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                  h3: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asistente Médico', // Título más descriptivo
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 9, 42, 73),
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          // Mostrar la imagen seleccionada debajo del chat
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey[200]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Imagen seleccionada: ${(_selectedImage!.path.split('/').last.length > 20 ? "..." : "") + _selectedImage!.path.split('/').last.substring(_selectedImage!.path.split('/').last.length > 20 ? _selectedImage!.path.split('/').last.length - 20 : 0)}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null; // Quitar la imagen
                      });
                    },
                  ),
                ],
              ),
            ),
          Divider(height: 1, color: Colors.grey[400]),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 9, 42, 73),
                  child: IconButton(
                    icon: const Icon(Icons.image, color: Colors.white),
                    onPressed: () {
                      // Mostrar un diálogo para elegir entre galería o cámara
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext bc) {
                          return SafeArea(
                            child: Wrap(
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galería'),
                                  onTap: () {
                                    _pickImage(ImageSource.gallery);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_camera),
                                  title: const Text('Cámara'),
                                  onTap: () {
                                    _pickImage(ImageSource.camera);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.lato(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta o describe la imagen...',
                      hintStyle: GoogleFonts.lato(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onSubmitted: (text) {
                      _sendMessage(text: text.trim(), image: _selectedImage);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 9, 42, 73),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _sendMessage(
                        text: _controller.text.trim(),
                        image: _selectedImage,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
