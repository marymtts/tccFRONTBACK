// lib/screens/register_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ec_mobile/theme/app_colors.dart'; // Importe suas cores
import 'package:ec_mobile/screens/login_screen.dart'; // Importa a tela de login

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para ler o texto dos campos
  final TextEditingController _raController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>(); // Chave para validar o formulário
  bool _isLoading = false;

  // Função para lidar com o clique no botão "Registrar"
  Future<void> _registerUser() async {
    // Valida o formulário (se os campos não estão vazios, etc.)
    if (!_formKey.currentState!.validate()) {
      return; // Se o formulário for inválido, não faz nada
    }

    setState(() { _isLoading = true; });

    // URL da API que acabamos de criar
    final url = Uri.parse('http://192.168.15.174/EC_back/api/registrar_aluno.php');
    // (Lembre-se das URLs de Emulador/Celular Físico)

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ra': _raController.text,
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
        }),
      );

      // Decodifica a resposta da API (success ou error)
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['status'] == 'success') {
        // Sucesso!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrado com sucesso! Por favor, faça o login.'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de Login (que vamos criar)
        // Por enquanto, vamos só fechar esta tela:
        Navigator.pop(context); 
      } else {
        // Erro (ex: "Email já cadastrado")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Erro desconhecido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Erro de conexão
      print('Erro no registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão. Verifique o XAMPP e a URL.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form( // Usamos um Form para validação
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Campo RA
                TextFormField(
                  controller: _raController,
                  decoration: _buildInputDecoration('RA (Registro do Aluno)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu RA';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: _buildInputDecoration('Nome Completo'),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Senha
                TextFormField(
                  controller: _senhaController,
                  decoration: _buildInputDecoration('Senha'),
                  obscureText: true, // Esconde a senha
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Botão Registrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser, // Desabilita se estiver carregando
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Registrar', style: TextStyle(fontSize: 18)),
                  ),
                ),
                  
                // Botão para ir ao Login
                TextButton(
                  onPressed: () {
                   Navigator.push( // Ou Navigator.pushReplacement
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ); // Por enquanto, só fecha
                  },
                  child: const Text('Já tem uma conta? Faça login!'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar para decorar os campos de texto
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}