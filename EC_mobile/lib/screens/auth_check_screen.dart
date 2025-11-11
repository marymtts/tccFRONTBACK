// lib/screens/auth_check_screen.dart
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ec_mobile/main.dart'; // Para navegar para a HomeScreen
import 'package:ec_mobile/screens/login_screen.dart'; // Para a LoginScreen
import 'package:ec_mobile/providers/user_provider.dart'; // Para salvar o usuário

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {

  @override
  void initState() {
    super.initState();
    // Inicia a verificação assim que a tela for construída
    _checkLoginStatus(); 
  }

  Future<void> _checkLoginStatus() async {
    // Pega a instância do "cofre"
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Tenta ler o "cartão de acesso" (token). Se não existir, retorna null
    final String? token = prefs.getString('jwt_token');

    // Espera um tiquinho (para mostrar uma tela de "splash" se quiséssemos)
    await Future.delayed(const Duration(milliseconds: 500));

    // Garante que a tela ainda existe antes de tentar navegar
    if (!mounted) return;

    if (token != null) {
      // --- Usuário ESTÁ logado ---
      // Se achou o token, decodifica ele e salva no "Provedor"
      // para que o resto do app saiba quem é o usuário
      Provider.of<UserProvider>(context, listen: false).setUserFromToken(token);
      
      // Navega para a Tela Principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // --- Usuário NÃO está logado ---
      // Navega para a Tela de Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esta tela é só um "Carregando..."
    // O usuário nunca vê esta tela por mais de um segundo.
    return const Scaffold(
      backgroundColor: AppColors.background, // Usa a cor de fundo padrão
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}