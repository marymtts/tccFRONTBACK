// lib/screens/scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart'; // Importa suas cores

class ScannerScreen extends StatefulWidget {
  final int eventoId;
  const ScannerScreen({super.key, required this.eventoId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  
  // O tamanho do "buraco" do scanner
  final double _scannerHoleSize = 250.0;

  Future<void> _validarCheckIn(String alunoId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Token de admin não encontrado.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Lembre-se: 'localhost' para iOS, '10.0.2.2' para Emulador Android
      final response = await http.post(
        Uri.parse('http://192.168.15.174/EC_back/api/validar_checkin.php'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_aluno': alunoId,
          'id_evento': widget.eventoId,
        }),
      );

      if (!context.mounted) return;
      final responseData = json.decode(response.body);
      final bool isError = response.statusCode != 200;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message'] ?? 'Resposta recebida.'),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de rede ao validar: $e')),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isProcessing = false);
  }


  // --- AQUI ESTÁ A MUDANÇA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validar Entrada (Evento ${widget.eventoId})'),
        backgroundColor: AppColors.surface, // Usando sua cor
      ),
      // O body agora é um Stack para sobrepor widgets
      body: Stack(
        children: [
          // --- CAMADA 1: A CÂMERA ---
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? alunoId = barcodes.first.rawValue;
                if (alunoId != null) {
                  _validarCheckIn(alunoId);
                }
              }
            },
          ),

          // --- CAMADA 2: O OVERLAY (O "DIM" ESCURO) ---
          // Isso "corta" um buraco no centro
          ClipPath(
            clipper: ScannerOverlayClipper(holeSize: _scannerHoleSize),
            child: Container(
              color: Colors.black.withOpacity(0.6), // Fundo escuro semi-transparente
            ),
          ),

          // --- CAMADA 3: A BORDA VERMELHA ---
          // (Usando sua identidade visual)
          Center(
            child: Container(
              width: _scannerHoleSize,
              height: _scannerHoleSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.accent, // <-- SUA COR AQUI!
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),

          // --- CAMADA 4: TEXTO DE AJUDA ---
          Center(
            child: Padding(
              // Posiciona o texto abaixo do quadrado
              padding: EdgeInsets.only(top: _scannerHoleSize + 40),
              child: Text(
                "Posicione o QR code no centro",
                style: TextStyle(
                  color: AppColors.primaryText, // Cor branca do seu tema
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLASSE AUXILIAR (COLOQUE NO FINAL DO ARQUIVO) ---
// Esta classe mágica é que "corta o buraco" no overlay
class ScannerOverlayClipper extends CustomClipper<Path> {
  final double holeSize;

  ScannerOverlayClipper({required this.holeSize});

  @override
  Path getClip(Size size) {
    // Pega o centro da tela
    final center = size.center(Offset.zero);
    final halfSize = holeSize / 2;

    // Define o retângulo do "buraco"
    final holeRect = Rect.fromLTRB(
      center.dx - halfSize,
      center.dy - halfSize,
      center.dx + halfSize,
      center.dy + halfSize,
    );

    // Define o retângulo da tela inteira
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Cria a mágica: "Desenhe a tela inteira MENOS o buraco"
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect), // Caminho 1: A tela toda
      Path()..addRect(holeRect), // Caminho 2: O buraco
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}