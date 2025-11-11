// lib/screens/criar_evento_screen.dart

import 'dart:convert';
import 'dart:io'; // Para lidar com o File da imagem
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Pacote para pegar imagem
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // <-- ADICIONADO: Para o InputFormatter de números

class CriarEventoScreen extends StatefulWidget {
  const CriarEventoScreen({super.key});

  @override
  State<CriarEventoScreen> createState() => _CriarEventoScreenState();
}

class _CriarEventoScreenState extends State<CriarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para os campos
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  
  // --- ADICIONADO (PASSO 1): Novos controladores e variáveis de estado ---
  final TextEditingController _maxParticipantesController = TextEditingController();
  bool _requerInscricao = true; // Começa como "sim" por padrão
  // -----------------------------------------------------------------

  // Variáveis para data e imagem
  DateTime? _selectedDate; // Guarda a data selecionada
  XFile? _selectedImage; // Guarda o arquivo de imagem selecionado
  
  bool _isLoading = false;

  // --- Função para abrir a Galeria/Câmera ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // --- Função para mostrar o DatePicker ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Função para ENVIAR o evento para a API ---
  Future<void> _submitEvent() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null) {
      _showFeedbackSnackbar('Por favor, selecione uma data para o evento.', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    // 2. URL da API (use o IP da sua rede, não 'localhost' ou '10.0.2.2' se for celular fisico)
    final url = Uri.parse('https://tccfrontback.onrender.com/api/eventos.php');

    try {
      // 3. Cria a Requisição "Multipart"
      var request = http.MultipartRequest('POST', url);

      // 4. Adiciona os campos de TEXTO
      request.fields['titulo'] = _tituloController.text;
      request.fields['descricao'] = _descricaoController.text;
      request.fields['data_evento'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      
      // --- MODIFICADO (PASSO 3): Envia os novos dados ---
      // Envia "true" ou "false" como string, que o PHP vai ler
      request.fields['inscricao'] = _requerInscricao.toString(); 
      
      // Envia o valor do controller. Se estiver vazio, envia '0'
      // A API PHP (que já corrigimos) entende '0' ou NULL como ilimitado.
      request.fields['max_participantes'] = _maxParticipantesController.text.isEmpty
                                            ? '0' 
                                            : _maxParticipantesController.text;
      // -------------------------------------------------

      // 5. Adiciona o arquivo de IMAGEM
      if (_selectedImage != null) {
        if (kIsWeb) {
          // --- LÓGICA PARA WEB ---
          var imageBytes = await _selectedImage!.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'imagem_evento', 
            imageBytes,
            filename: _selectedImage!.name, 
          );
          request.files.add(multipartFile);
        } else {
          // --- LÓGICA PARA MOBILE ---
          request.files.add(
            await http.MultipartFile.fromPath(
              'imagem_evento',
              _selectedImage!.path,
            ),
          );
        }
      }

      // 6. Envia a requisição
      var streamedResponse = await request.send();
      
      // 7. Lê a resposta
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) { // 201 Created
        _showFeedbackSnackbar(responseData['message'] ?? 'Evento criado com sucesso!', isError: false);
        Navigator.pop(context); // Volta para a tela anterior
      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      print('Erro ao criar evento: $e');
      _showFeedbackSnackbar('Erro de conexão. Verifique o XAMPP e a URL.', isError: true);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Função auxiliar para mostrar feedback
  void _showFeedbackSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- ADICIONADO: Dispose para o novo controller ---
  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _maxParticipantesController.dispose(); // <-- Limpa o novo controller
    super.dispose();
  }
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Evento'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Campo Título ---
                    TextFormField(
                      controller: _tituloController,
                      decoration: _buildInputDecoration('Título do Evento'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Campo Descrição ---
                    TextFormField(
                      controller: _descricaoController,
                      decoration: _buildInputDecoration('Descrição Completa'),
                      maxLines: 5,
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 24),

                    // --- Seletor de Data ---
                    Text('Data do Evento:', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context),
                      child: Container(
                        // ... (seu container de data, sem mudanças) ...
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Selecione uma data'
                                  : DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!),
                              style: TextStyle(color: _selectedDate == null ? AppColors.secondaryText : Colors.white, fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ADICIONADO (PASSO 2): Novos campos do formulário ---
                    // --- CAMPO 1: REQUER INSCRIÇÃO (Switch) ---
                    SwitchListTile(
                      title: Text(
                        'Requer Inscrição?',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                      ),
                      subtitle: Text(
                        _requerInscricao ? 'Sim, vagas serão controladas.' : 'Não, evento aberto ao público.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      value: _requerInscricao,
                      activeColor: AppColors.accent, // Sua cor vermelha
                      onChanged: (bool newValue) {
                        setState(() {
                          _requerInscricao = newValue;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16), 

                    // --- CAMPO 2: MÁXIMO DE PARTICIPANTES (Condicional) ---
                    // Só mostra este campo se o switch de cima estiver ATIVADO
                    if (_requerInscricao)
                      TextFormField(
                        controller: _maxParticipantesController,
                        decoration: _buildInputDecoration('Número Máximo de Vagas (0 = ilimitado)'),
                        keyboardType: TextInputType.number, // Teclado numérico
                        // Filtra para aceitar apenas números
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                      ),
                    // ----------------------------------------------------
                    
                    const SizedBox(height: 24),

                    // --- Seletor de Imagem ---
                    Text('Imagem do Evento (Opcional):', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        // ... (seu container de imagem, sem mudanças) ...
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondaryText, width: 0.5),
                        ),
                        child: _selectedImage != null
                            ? (kIsWeb
                                ? Image.network(
                                    _selectedImage!.path, 
                                    fit: BoxFit.cover,
                                  )
                                : Image.file( 
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                  )
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.secondaryText, size: 40),
                                  SizedBox(height: 8),
                                  Text('Clique para selecionar uma imagem', style: TextStyle(color: AppColors.secondaryText)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Botão Criar Evento ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Criar Evento', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Função auxiliar de estilo (sem mudanças)
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