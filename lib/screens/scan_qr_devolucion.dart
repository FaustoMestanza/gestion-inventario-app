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
  bool isProcessing = false;
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController codigoManualCtrl = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  final String prestamosURL =
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';

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

  Future<void> _buscarPrestamo(String codigo) async {
    if (codigo.trim().isEmpty) {
      _mostrarMensaje('Ingrese o escanee un código válido.');
      return;
    }

    try {
      print('📷 Código detectado o ingresado: $codigo');
      setState(() => isProcessing = true);
      cameraController.stop();

      final url = '$prestamosURL?codigo=$codigo';
      final response = await http.get(Uri.parse(url));

      print('🔹 Respuesta ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final prestamo = data.first;
          final estado = prestamo['estado'];

          print("ESTADO DESDE API: $estado");

          // 🔹 Caso 1: Equipo disponible (ya devuelto)
          if (estado == "Disponible") {
            _mostrarMensaje("⚠️ El equipo ya fue devuelto.");
            cameraController.start();
            setState(() => isProcessing = false);
            return;
          }

          // 🔹 Caso 2: Préstamo cerrado
          if (estado == "Cerrado") {
            _mostrarMensaje("⚠️ El préstamo ya fue cerrado previamente.");
            cameraController.start();
            setState(() => isProcessing = false);
            return;
          }

          // 🔹 Caso 3: Vencido → permitir devolución con sanción
          if (estado == "Vencido") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ScanDevolucionScreen(
                  prestamo: Map<String, dynamic>.from(prestamo),
                  docenteId: widget.docenteId,
                ),
              ),
            );
            return;
          }

          // 🔹 Caso 4: Abierto → validar docente
          if (estado == "Abierto") {
            final registradoPor = prestamo['registrado_por_id'];
            if (registradoPor != widget.docenteId) {
              _mostrarMensaje(
                "⚠️ No puedes registrar la devolución de un préstamo realizado por otro docente.",
              );
              cameraController.start();
              setState(() => isProcessing = false);
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ScanDevolucionScreen(
                  prestamo: Map<String, dynamic>.from(prestamo),
                  docenteId: widget.docenteId,
                ),
              ),
            );
            return;
          }

          // 🔹 Cualquier otro estado
          _mostrarMensaje("⚠️ Estado desconocido del préstamo.");
          cameraController.start();
          setState(() => isProcessing = false);
        } else {
          _mostrarMensaje('No se encontró préstamo activo para ese código.');
          cameraController.start();
          setState(() => isProcessing = false);
        }
      } else {
        _mostrarMensaje('Error ${response.statusCode} al consultar préstamo.');
        cameraController.start();
        setState(() => isProcessing = false);
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
      cameraController.start();
      setState(() => isProcessing = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    codigoManualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Préstamo para Devolución'),
        backgroundColor: const Color(0xFF00B894),
      ),
      body: Stack(
        children: [
          // 📷 Cámara activa
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  _buscarPrestamo(code);
                }
              }
            },
          ),

          // 🟩 Cuadro animado de guía
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

          // 📝 Campo manual de búsqueda
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Escanee el código QR o ingrese el código manualmente',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codigoManualCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ingrese el código del préstamo o equipo',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _buscarPrestamo(codigoManualCtrl.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar Manualmente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRGuidePainter extends CustomPainter {
  final double progress;
  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint border = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint line = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, border);

    final double y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
