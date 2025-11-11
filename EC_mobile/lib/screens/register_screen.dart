// lib/screens/register_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:ec_mobile/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:ec_mobile/config.dart'; // <-- LINHA REMOVIDA (O ERRO ESTAVA AQUI)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers e Chave do Formulário (como na sua tela de Login)
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _raController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage; // Para mostrar erros na tela, igual ao Login
  bool _obscureSenha = true; // Para o "olho" da senha

  @override
  void dispose() {
    _raController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Limpa erros antigos
    });

    try {
      // 2. USA A SUA URL CORRETA (sem o Config.apiUrl)
      final response = await http.post(
        Uri.parse('https://tccfrontback.onrender.com/api/registrar_aluno.php'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ra': _raController.text.trim(),
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'senha': _passwordController.text.trim(), // 'senha' (como no seu login)
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) { // 201 Created (do seu registrar_aluno.php)
        // Sucesso!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Conta criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Manda o usuário para a tela de Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Erro (ex: "Email ou RA já cadastrado")
        setState(() {
          _errorMessage = responseData['message'] ?? 'Ocorreu um erro. Tente novamente.';
        });
      }
    } catch (e) {
      print('Erro no registro: $e');
      setState(() {
        _errorMessage = 'Erro de Conexão. Verifique sua internet e o XAMPP.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // --- O NOVO MÉTODO BUILD (baseado no design do Login) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar para ter o botão "Voltar"
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // --- SEU LOGO ---
                  Center(
                    child: Image.asset(
                      'assets/images/ec-logo.png', // <-- VERIFIQUE SE O CAMINHO ESTÁ CERTO
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- TÍTULO ---
                  Text(
                    'Crie sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'É rápido e fácil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- CAMPO DE RA ---
                  TextFormField(
                    controller: _raController,
                    decoration: _buildInputDecoration(
                      label: 'RA (Registro do Aluno)',
                      icon: Icons.badge_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.primaryText),
                    validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO DE NOME ---
                  TextFormField(
                    controller: _nomeController,
                    decoration: _buildInputDecoration(
                      label: 'Nome Completo',
                      icon: Icons.person_outline,
                    ),
                    keyboardType: TextInputType.name,
                    style: const TextStyle(color: AppColors.primaryText),
                    validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO DE EMAIL ---
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.primaryText),
                    validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO DE SENHA ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureSenha,
                    decoration: _buildInputDecoration(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      isSenha: true,
                      obscure: _obscureSenha,
                      onToggle: () {
                        setState(() { _obscureSenha = !_obscureSenha; });
                      }
                    ),
                    style: const TextStyle(color: AppColors.primaryText),
                    validator: (value) => (value == null || value.length < 6) ? 'Senha deve ter min. 6 caracteres' : null,
                  ),
                  const SizedBox(height: 30),

                  // --- MENSAGEM DE ERRO (inline) ---
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                    ),

                  // --- BOTÃO REGISTRAR (com gradiente) ---
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : Container( 
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentOrange, AppColors.accent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Registrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 25),

                  // --- LINK DE LOGIN (RichText) ---
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Já tem uma conta? ',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Faça login!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Espaço extra
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNÇÃO DE ESTILO (Idêntica à da tela de Login) ---
  InputDecoration _buildInputDecoration(
    {
      required String label, 
      required IconData icon, 
      bool isSenha = false, 
      bool obscure = false, 
      VoidCallback? onToggle
    }
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      prefixIcon: Icon(icon, color: AppColors.secondaryText, size: 20),
      suffixIcon: isSenha 
        ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.secondaryText,
            ),
            onPressed: onToggle,
          )
        : null,
      filled: true,
      fillColor: AppColors.surface, // Usei a cor 'surface' do seu app
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0), // Padding maior
    );
  }
}