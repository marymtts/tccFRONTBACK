import 'dart:convert';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditarContaScreen extends StatefulWidget {
  const EditarContaScreen({super.key});

  @override
  State<EditarContaScreen> createState() => _EditarContaScreenState();
}

class _EditarContaScreenState extends State<EditarContaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  final TextEditingController _senhaAnteriorController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  // Foco para pular campos
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _senhaAnteriorFocus = FocusNode();
  final FocusNode _novaSenhaFocus = FocusNode();
  final FocusNode _confirmarSenhaFocus = FocusNode();

  bool _obscureSenhaAnterior = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  @override
  void initState() {
    super.initState();
    // Preenche os campos com os dados do usuário logado
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nomeController = TextEditingController(text: user?.nome ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    // Limpa todos os controllers
    _nomeController.dispose();
    _emailController.dispose();
    _senhaAnteriorController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    _emailFocus.dispose();
    _senhaAnteriorFocus.dispose();
    _novaSenhaFocus.dispose();
    _confirmarSenhaFocus.dispose();
    super.dispose();
  }

  Future<void> _atualizarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      _showFeedbackSnackbar('Por favor, corrija os erros no formulário.', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    // Pegar token
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    if (token == null) {
      _showFeedbackSnackbar('Erro: Token não encontrado. Faça login novamente.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // Chamar a NOVA API
      final url = Uri.parse('http://192.168.15.174/EC_back/api/atualizar_perfil.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Envia o token
        },
        body: json.encode({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha_anterior': _senhaAnteriorController.text,
          'nova_senha': _novaSenhaController.text,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // --- ATUALIZAÇÃO IMPORTANTE ---
        // O servidor nos deu um NOVO token com os dados atualizados
        final String novoToken = responseData['novo_jwt'];
        // 1. Salva o novo token no "cofre"
        await prefs.setString('jwt_token', novoToken);
        // 2. Atualiza o UserProvider com o novo token
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUserFromToken(novoToken);
          _showFeedbackSnackbar(responseData['message'] ?? 'Perfil atualizado!', isError: false);
          Navigator.pop(context); // Volta para a tela "Minha Conta"
        }
      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showFeedbackSnackbar('Erro de conexão. Verifique sua rede e o XAMPP.', isError: true);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showFeedbackSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dados Pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 16),
              // --- Nome ---
              TextFormField(
                controller: _nomeController,
                decoration: _buildInputDecoration('Nome Completo'),
                validator: (value) => (value == null || value.isEmpty) ? 'Nome não pode ficar vazio' : null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
              ),
              const SizedBox(height: 16),
              // --- Email ---
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: _buildInputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_senhaAnteriorFocus),
              ),
              const SizedBox(height: 30),
              // --- Mudar Senha ---
              Text(
                'Alterar Senha',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              Text(
                'Deixe os campos abaixo em branco se não quiser alterar a senha.',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              // --- Senha Anterior ---
              TextFormField(
                controller: _senhaAnteriorController,
                focusNode: _senhaAnteriorFocus,
                decoration: _buildInputDecoration('Senha Anterior', isSenha: true, onToggle: () {
                  setState(() { _obscureSenhaAnterior = !_obscureSenhaAnterior; });
                }, obscure: _obscureSenhaAnterior),
                obscureText: _obscureSenhaAnterior,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_novaSenhaFocus),
                validator: (value) {
                  // Só é obrigatório se o campo "nova senha" estiver preenchido
                  if (_novaSenhaController.text.isNotEmpty && (value == null || value.isEmpty)) {
                    return 'Senha anterior obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- Nova Senha ---
              TextFormField(
                controller: _novaSenhaController,
                focusNode: _novaSenhaFocus,
                decoration: _buildInputDecoration('Nova Senha', isSenha: true, onToggle: () {
                  setState(() { _obscureNovaSenha = !_obscureNovaSenha; });
                }, obscure: _obscureNovaSenha),
                obscureText: _obscureNovaSenha,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmarSenhaFocus),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'A senha deve ter min. 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- Confirmar Nova Senha ---
              TextFormField(
                controller: _confirmarSenhaController,
                focusNode: _confirmarSenhaFocus,
                decoration: _buildInputDecoration('Confirmar Nova Senha', isSenha: true, onToggle: () {
                  setState(() { _obscureConfirmarSenha = !_obscureConfirmarSenha; });
                }, obscure: _obscureConfirmarSenha),
                obscureText: _obscureConfirmarSenha,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (_novaSenhaController.text.isNotEmpty && value != _novaSenhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // --- Botão Salvar ---
              ElevatedButton(
                onPressed: _isLoading ? null : _atualizarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Alterações', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função auxiliar de estilo (copiada da tela de criar evento)
  InputDecoration _buildInputDecoration(String label, {bool isSenha = false, bool obscure = false, VoidCallback? onToggle}) {
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
      suffixIcon: isSenha 
        ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.secondaryText,
            ),
            onPressed: onToggle,
          )
        : null,
    );
  }
}