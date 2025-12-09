import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pantalla_detalle_equipo_prestamo.dart';

class RegistrarPrestamoScreen extends StatefulWidget {
  final int docenteId; // ✅ ID del docente logueado

  const RegistrarPrestamoScreen({super.key, required this.docenteId});

  @override
  State<RegistrarPrestamoScreen> createState() =>
      _RegistrarPrestamoScreenState();
}

class _RegistrarPrestamoScreenState extends State<RegistrarPrestamoScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  final TextEditingController _codigoController = TextEditingController();

  bool isProcessing = false;

  final String inventarioURL =
      //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

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

  Future<void> _buscarEquipo(String codigo) async {
    if (codigo.isEmpty) {
      _mostrarMensaje('Por favor, escanea o ingresa un código.');
      return;
    }

    try {
      setState(() => isProcessing = true);
      final url = '$inventarioURL?codigo=$codigo';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : [decoded];

        if (data.isEmpty) {
          _mostrarMensaje('No se encontró el equipo con código $codigo.');
        } else {
          final equipo = Map<String, dynamic>.from(data.first);

          if (equipo['estado']?.toLowerCase() == 'prestado') {
            _mostrarMensaje('⚠️ Equipo ya prestado, no se puede registrar.');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEquipoPrestamoScreen(
                  equipo: equipo,
                  docenteId: widget.docenteId, // ✅ pasar ID del docente
                  onRegistrar: (String estudianteId) {},
                ),
              ),
            );
          }
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
  void dispose() {
    _cameraController.dispose();
    _animationController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text('Registrar Préstamo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
              'Escanea o ingresa manualmente el código del equipo',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 15),
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
          ],
        ),
      ),
    );
  }
}

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

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, border);

    final double y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
