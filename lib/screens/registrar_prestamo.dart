import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pantalla_detalle_equipo_prestamo.dart';

class RegistrarPrestamoScreen extends StatefulWidget {
  final int docenteId;

  const RegistrarPrestamoScreen({super.key, required this.docenteId});

  @override
  State<RegistrarPrestamoScreen> createState() =>
      _RegistrarPrestamoScreenState();
}

class _RegistrarPrestamoScreenState extends State<RegistrarPrestamoScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _codigoController = TextEditingController();

  bool isProcessing = false;

  final String inventarioURL =
      "https://apigateway-tesis.azure-api.net/inventario/api/equipos/";

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
    _animationController.dispose();
    cameraController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  // ===========================================================
  // 🔍 Buscar equipo por código
  // ===========================================================
  Future<void> _buscarEquipo(String codigo) async {
    if (codigo.isEmpty) {
      _mostrarMensaje("Ingresa o escanea un código.");
      return;
    }

    try {
      setState(() => isProcessing = true);

      final url = "$inventarioURL?codigo=$codigo";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : [decoded];

        if (data.isEmpty) {
          _mostrarMensaje("No se encontró el equipo con código $codigo");
        } else {
          final equipo = Map<String, dynamic>.from(data.first);

          if (equipo["estado"]?.toLowerCase() == "prestado") {
            _mostrarMensaje("⚠️ El equipo ya está prestado.");
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalleEquipoPrestamoScreen(
                  equipo: equipo,
                  docenteId: widget.docenteId,
                  onRegistrar: (_) {},
                ),
              ),
            );

            cameraController.start(); // 🔄 Reactivar cámara al volver
          }
        }
      } else {
        _mostrarMensaje("Error ${response.statusCode} al buscar equipo");
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===========================================================
  // 📷 PROCESAR CÓDIGO ESCANEADO
  // ===========================================================
  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      isProcessing = true;
      cameraController.stop(); // ⏹️ Detener cámara

      await _buscarEquipo(code);

      isProcessing = false;
    }
  }

  // ===========================================================
  // UI PRINCIPAL
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text("Registrar Préstamo"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===================================================
            // 🔵 SCANNER QR
            // ===================================================
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onDetect,
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) {
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
              "Escanea o ingresa el código del equipo",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            // ===================================================
            // ✏ BÚSQUEDA MANUAL
            // ===================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _codigoController,
                decoration: InputDecoration(
                  labelText: "Código del equipo",
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
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// 🎨 DIBUJA MARCO DEL SCANNER
// ===========================================================
class _QRGuidePainter extends CustomPainter {
  final double progress;

  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final line = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);

    final double y = size.height * progress;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
