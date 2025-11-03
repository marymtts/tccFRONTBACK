// lib/screens/conta_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ec_mobile/providers/user_provider.dart'; // Nosso provedor
import 'package:ec_mobile/screens/login_screen.dart'; // Tela de login
import 'package:ec_mobile/theme/app_colors.dart';

class ContaScreen extends StatefulWidget {
  const ContaScreen({super.key});

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  // Controladores para os campos (preparando para a edição futura)
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _raController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pega o usuário do provider e preenche os campos
    // 'listen: false' é importante dentro do initState
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _nomeController.text = user.nome;
      _emailController.text = user.email;
      _raController.text = user.ra!; // Assumindo que seu User model tem 'ra'
    }
  }

  // --- A FUNÇÃO DE LOGOUT ---
  Future<void> _logout() async {
    setState(() { _isLoading = true; });

    // 1. Apaga o token do "cofre" (SharedPreferences)
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    // 2. Limpa o usuário do "provedor" (UserProvider)
    // 'listen: false' é usado dentro de funções
    Provider.of<UserProvider>(context, listen: false).clearUser();

    // 3. Garante que estamos com o contexto certo antes de navegar
    if (!mounted) return;

    // 4. Navega para a tela de Login e LIMPA TODAS as telas anteriores
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Remove todas as rotas
    );
  }

  // TODO: Função para atualizar o nome (próximo passo)
  Future<void> _updateProfile() async {
    // Aqui virá a lógica de chamar a API 'atualizar_aluno.php'
    // ...enviando _nomeController.text, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de salvar ainda não implementada.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Pega o usuário do provider (aqui 'listen: true' é o padrão)
    // final user = Provider.of<UserProvider>(context).user;
    // Se não tiver usuário (algo deu muito errado), volta para o login
    // if (user == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    //   });
    //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra loading (ao deslogar)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Campo RA (desabilitado para edição)
                  TextFormField(
                    controller: _raController,
                    readOnly: true, // Não pode editar o RA
                    decoration: _buildInputDecoration('RA'),
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo Nome (habilitado para edição)
                  TextFormField(
                    controller: _nomeController,
                    decoration: _buildInputDecoration('Nome Completo'),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),

                  // Campo Email (desabilitado para edição)
                  TextFormField(
                    controller: _emailController,
                    readOnly: true, // Não pode editar o email (geralmente)
                    decoration: _buildInputDecoration('Email'),
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 30),

                  // Botão Salvar Alterações
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile, // Chama a função (futura) de salvar
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Salvar Alterações', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão Sair (Logout)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton( // Botão com estilo diferente
                      onPressed: _logout, // Chama a função de logout
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryText,
                        side: const BorderSide(color: AppColors.secondaryText),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Sair (Logout)', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Função auxiliar de estilo (copiada do register_screen)
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
      // Estilo para quando o campo está desabilitado (readOnly)
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}