// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ec_mobile/theme/app_colors.dart';
// import 'package:ec_mobile/main.dart'; // Não é mais necessário, vamos para o AuthCheck
import 'package:ec_mobile/screens/register_screen.dart'; // Para navegar para o Registro
import 'package:shared_preferences/shared_preferences.dart'; // Para salvar o token
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
// ADICIONADO: A tela de verificação de login
import 'package:ec_mobile/screens/auth_check_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- SEUS CONTROLLERS E VARIÁVEIS (Mantidos) ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController(); // Nome mantido
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- NOVA VARIÁVEL: Para o erro inline ---
  String? _errorMessage;
  // --- NOVA VARIÁVEL: Para o "olho" da senha ---
  bool _obscureSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // --- SUA FUNÇÃO DE LOGIN (Modificada para usar o erro inline) ---
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { 
      _isLoading = true; 
      _errorMessage = null; // Limpa erros antigos
    });

    // URL da API de Login (Sua URL)
    final url = Uri.parse('https://tccfrontback.onrender.com/api/login.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'senha': _senhaController.text,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // --- SUCESSO! (Sua lógica mantida) ---
        String jwtToken = responseData['jwt'];
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken); 
        
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUserFromToken(jwtToken);
        }

        // --- MUDANÇA: Navega para o AuthCheck em vez da Home ---
        // Isso permite que o AuthCheck decida para onde ir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
        );
      } else {
        // --- MUDANÇA: Mostra o erro na tela (inline) ---
        setState(() {
          _errorMessage = responseData['message'] ?? 'Erro desconhecido.';
        });
      }
    } catch (e) {
      print('Erro no login: $e');
      // --- MUDANÇA: Mostra o erro na tela (inline) ---
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique o XAMPP e a URL.';
      });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- MÉTODO BUILD (Completamente substituído pelo design "Lindo") ---
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      // REMOVEMOS O APPBAR
      body: SafeArea( // SafeArea evita que o conteúdo fique atrás da barra de status
        child: SingleChildScrollView(
          child: Container(
            // Garante que a tela tenha no mínimo a altura do dispositivo
            height: screenSize.height - MediaQuery.of(context).padding.top, 
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2), // Espaço no topo

                  // --- LOGO/IMAGEM DE DESTAQUE ---
                  // Coloque seu logo em 'assets/images/logo.png'
                  // E descomente a linha 'assets/images/' no pubspec.yaml
                  Image.asset(
                    'assets/images/ec-logo.png', // <-- MUDE PARA O CAMINHO DO SEU LOGO
                    height: 120,
                  ),
                  const SizedBox(height: 30),

                  // --- TÍTULO ---
                  Text(
                    'Bem-vindo(a) de volta!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Faça login para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // --- CAMPO DE EMAIL ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.primaryText),
                    decoration: _buildInputDecoration( // Usa a nova função
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, insira um email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- CAMPO DE SENHA (com o "olho") ---
                  TextFormField(
                    controller: _senhaController, // <-- Nome correto
                    obscureText: _obscureSenha, // Usa a variável de estado
                    style: const TextStyle(color: AppColors.primaryText),
                    decoration: _buildInputDecoration( // Usa a nova função
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      isSenha: true,
                      obscure: _obscureSenha,
                      onToggle: () {
                        setState(() { _obscureSenha = !_obscureSenha; });
                      }
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
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

                  // --- BOTÃO ENTRAR (com gradiente e loading) ---
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : Container( // Container para o gradiente e sombra
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
                            onPressed: _loginUser, // <-- Chama sua função
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Entrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 25),

                  // --- TEXTO DE REGISTRO (RichText) ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Não tem uma conta? ',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Registre-se já!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 3), // Espaço na parte de baixo
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNÇÃO DE ESTILO (Substituída pela versão "Lindo") ---
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