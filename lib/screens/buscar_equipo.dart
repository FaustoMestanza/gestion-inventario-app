import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'formulario_equipo.dart';

class BuscarEquipoScreen extends StatefulWidget {
  // final int directorId; // ✅ recibe el ID del director logueado

  const BuscarEquipoScreen({super.key});

  @override
  State<BuscarEquipoScreen> createState() => _BuscarEquipoScreenState();
}

class _BuscarEquipoScreenState extends State<BuscarEquipoScreen>
    with SingleTickerProviderStateMixin {
  bool isProcessing = false;
  final TextEditingController _codigoController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _animationController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  /// 🔍 Buscar equipo en el microservicio
  Future<void> _buscarEquipo(String codigo) async {
    if (codigo.isEmpty) {
      _mostrarMensaje('Por favor ingresa o escanea un código.');
      return;
    }

    try {
      setState(() => isProcessing = true);

      final url =
          //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/?codigo=$codigo';
          'https://apigateway-tesis.azure-api.net/inventario/api/equipos/?codigo=$codigo';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.isNotEmpty) {
          data = [decoded];
        }

        if (data.isNotEmpty) {
          final equipo =
              Map<String, dynamic>.from(data.first); // ✅ paréntesis corregido

          // ✅ Aquí pasamos el ID del director
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioEquipoScreen(
                equipo: equipo,
                //directorId: widget.directorId,
              ),
            ),
          );

          // 🔄 al volver, reactivar la cámara
          _cameraController.start();
        } else {
          _mostrarMensaje('No se encontró el equipo con código $codigo.');
        }
      } else {
        _mostrarMensaje('Error ${response.statusCode} al buscar el equipo.');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7F32),
        title: const Text('Buscar Equipo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔶 Escáner de QR
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    onDetect: (capture) {
                      if (isProcessing) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final code = barcodes.first.rawValue;
                        if (code != null && code.isNotEmpty) {
                          _cameraController.stop();
                          _buscarEquipo(code);
                        }
                      }
                    },
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(250, 250),
                          painter: _QRGuidePainter(_animation.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Escanea un código QR o ingresa el código manualmente',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),

            // 🟣 Campo manual de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _codigoController,
                decoration: InputDecoration(
                  labelText: 'Código del equipo (ej: EQP-0001)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        _buscarEquipo(_codigoController.text.trim()),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 Botón de búsqueda manual
            ElevatedButton.icon(
              onPressed: () =>
                  _buscarEquipo(_codigoController.text.trim().toUpperCase()),
              icon: const Icon(Icons.manage_search),
              label: const Text('Buscar Equipo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Dibuja el marco y la línea animada del escáner
class _QRGuidePainter extends CustomPainter {
  final double progress;

  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final line = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, border);

    final double y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
