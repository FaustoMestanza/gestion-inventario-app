import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'scan_devolucion.dart';

class ScanQRDevolucionScreen extends StatefulWidget {
  final int docenteId;

  const ScanQRDevolucionScreen({super.key, required this.docenteId});

  @override
  State<ScanQRDevolucionScreen> createState() => _ScanQRDevolucionScreenState();
}

class _ScanQRDevolucionScreenState extends State<ScanQRDevolucionScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController codigoManualCtrl = TextEditingController();

  bool isProcessing = false;

  final String prestamosURL =
      "https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/";

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
    cameraController.dispose();
    codigoManualCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // =======================================================
  // 🔍 BUSCAR PRÉSTAMO
  // =======================================================
  Future<void> _buscarPrestamo(String codigo) async {
    if (codigo.trim().isEmpty) {
      _mostrarMensaje("Ingrese o escanee un código válido.");
      return;
    }

    try {
      setState(() => isProcessing = true);
      cameraController.stop();

      final url = "$prestamosURL?codigo=$codigo";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is! List || body.isEmpty) {
          _mostrarMensaje("No se encontró préstamo para ese código.");
          cameraController.start();
          setState(() => isProcessing = false);
          return;
        }

        final prestamo = Map<String, dynamic>.from(body.first);
        final estado = prestamo["estado"];

        // 🔹 Ya devuelto
        if (estado == "Disponible") {
          _mostrarMensaje("⚠️ El equipo ya fue devuelto.");
          cameraController.start();
          setState(() => isProcessing = false);
          return;
        }

        // 🔹 Cerrado
        if (estado == "Cerrado") {
          _mostrarMensaje("⚠️ El préstamo ya está cerrado.");
          cameraController.start();
          setState(() => isProcessing = false);
          return;
        }

        // 🔹 Vencido → procede devolución
        if (estado == "Vencido") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanDevolucionScreen(
                prestamo: prestamo,
                docenteId: widget.docenteId,
              ),
            ),
          );
          return;
        }

        // 🔹 Abierto → Validar docente
        if (estado == "Abierto") {
          if (prestamo["registrado_por_id"] != widget.docenteId) {
            _mostrarMensaje("⚠️ Este préstamo no fue registrado por usted.");
            cameraController.start();
            setState(() => isProcessing = false);
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanDevolucionScreen(
                prestamo: prestamo,
                docenteId: widget.docenteId,
              ),
            ),
          );
          return;
        }

        _mostrarMensaje("Estado desconocido del préstamo.");
        cameraController.start();
      } else {
        _mostrarMensaje("Error ${response.statusCode} al consultar préstamo.");
        cameraController.start();
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión: $e");
      cameraController.start();
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =======================================================
  // 📷 LÓGICA DEL ESCÁNER
  // =======================================================
  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      isProcessing = true;
      await _buscarPrestamo(code);
      isProcessing = false;
    }
  }

  // =======================================================
  // UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar Préstamo para Devolución"),
        backgroundColor: const Color(0xFF00B894),
      ),
      body: Stack(
        children: [
          // 📷 Cámara
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Marco animado
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

          // Formulario inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Escanee un código o ingréselo manualmente",
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codigoManualCtrl,
                    decoration: InputDecoration(
                      hintText: "Código del préstamo o equipo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _buscarPrestamo(codigoManualCtrl.text.trim()),
                    icon: const Icon(Icons.search),
                    label: const Text("Buscar manualmente"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// =======================================================
// 🎨 Pintor del marco
// =======================================================
class _QRGuidePainter extends CustomPainter {
  final double progress;

  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final line = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
