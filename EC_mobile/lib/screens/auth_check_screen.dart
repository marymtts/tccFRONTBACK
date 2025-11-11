// lib/screens/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/login_screen.dart';
import 'package:ec_mobile/main.dart'; // Importa a HomeScreen
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {

  @override
  void initState() {
    super.initState();
    // Inicia a verificação assim que a tela é construída
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // --- 1. DÁ UM TEMPINHO PARA A ANIMAÇÃO ACONTECER ---
    await Future.delayed(const Duration(milliseconds: 2000)); // 2 segundos

    // --- 2. VERIFICA O TOKEN ---
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (!mounted) return; // Garante que a tela ainda existe

    if (token != null) {
      // Se tem token, tenta configurar o usuário
      try {
        Provider.of<UserProvider>(context, listen: false).setUserFromToken(token);
        // Sucesso: Vai para a Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        // Token inválido/expirado: Limpa e vai para o Login
        await prefs.remove('jwt_token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Sem token: Vai para o Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }


  // --- 3. O BUILD (VISUAL COM FADE-IN que você gostou) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // A mesma cor da splash nativa
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- O LOGO COM ANIMAÇÃO DE FADE-IN ---
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500), // Duração do fade-in
              builder: (context, double opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Image.asset(
                // Use seu logo COMPLETO aqui
                'assets/images/ec-logo.png', // <-- SEU LOGO COMPLETO
                height: 150, // Tamanho do logo
              ),
            ),
            
            const SizedBox(height: 30),

            // --- INDICADOR DE CARREGAMENTO SUTIL ---
            SizedBox(
              width: 150, // Largura do indicador
              child: LinearProgressIndicator(
                color: AppColors.accent, // Sua cor vermelha
                backgroundColor: AppColors.surface, // Fundo do indicador
                minHeight: 2.0, // Espessura
              ),
            ),
          ],
        ),
      ),
    );
  }
}