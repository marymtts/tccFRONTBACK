// lib/screens/criar_evento_screen.dart

import 'dart:convert';
import 'dart:io'; // Para lidar com o File da imagem
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Pacote para pegar imagem
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:flutter/foundation.dart' show kIsWeb;

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
  
  // Variáveis para data e imagem
  DateTime? _selectedDate; // Guarda a data selecionada
  XFile? _selectedImage; // Guarda o arquivo de imagem selecionado
  
  bool _isLoading = false;

  // --- Função para abrir a Galeria/Câmera ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Abre a galeria para o usuário escolher uma imagem
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image; // Armazena a imagem selecionada
      });
    }
  }

  // --- Função para mostrar o DatePicker (Calendário de seleção) ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Só pode criar eventos de hoje em diante
      lastDate: DateTime(2101),
      // TODO: Adicionar um builder de tema escuro se necessário
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Armazena a data selecionada
      });
    }
  }

  // --- Função para ENVIAR o evento para a API ---
  Future<void> _submitEvent() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return; // Se 'título' ou 'descrição' estiverem vazios, para aqui.
    }
    if (_selectedDate == null) {
      _showFeedbackSnackbar('Por favor, selecione uma data para o evento.', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    // 2. URL da API (usando o case 'POST' do eventos.php)
    final url = Uri.parse('http://localhost/EC_back/api/eventos.php');
    // (Lembre-se das URLs de Emulador/Celular Físico)

    try {
      // 3. Cria a Requisição "Multipart"
      // (Necessária para enviar arquivos + texto)
      var request = http.MultipartRequest('POST', url);

      // 4. Adiciona os campos de TEXTO
      // (Os nomes 'titulo', 'descricao', etc. devem bater com o $_POST do PHP)
      request.fields['titulo'] = _tituloController.text;
      request.fields['descricao'] = _descricaoController.text;
      // Formata a data para AAAA-MM-DD, que o MySQL entende
      request.fields['data_evento'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      request.fields['inscricao'] = '1'; // Exemplo: todo evento criado permite inscrição

      // 5. Adiciona o arquivo de IMAGEM (se um foi selecionado)
      if (_selectedImage != null) {
        // 'imagem_evento' DEVE bater com o $_FILES['imagem_evento'] do PHP
        
        if (kIsWeb) {
          // --- LÓGICA PARA WEB ---
          // Lê os bytes da imagem (o navegador faz isso)
          var imageBytes = await _selectedImage!.readAsBytes();
          // Cria o MultipartFile a partir dos bytes
          var multipartFile = http.MultipartFile.fromBytes(
            'imagem_evento', // O nome do campo
            imageBytes,
            // Precisamos dizer ao PHP o nome e tipo do arquivo
            filename: _selectedImage!.name, 
          );
          request.files.add(multipartFile);
        } else {
          // --- LÓGICA PARA MOBILE (A que você já tinha) ---
          request.files.add(
            await http.MultipartFile.fromPath(
              'imagem_evento',
              _selectedImage!.path,
            ),
          );
        }
      }
      // (Se _selectedImage for null, a API salvará NULL no banco, como planejamos)

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
                      maxLines: 5, // Campo maior
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 24),

                    // --- Seletor de Data ---
                    Text('Data do Evento:', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context), // Abre o calendário
                      child: Container(
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

                    // --- Seletor de Imagem ---
                    Text('Imagem do Evento (Opcional):', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage, // Abre a galeria
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondaryText, width: 0.5),
                        ),
                        // Mostra a imagem selecionada ou o placeholder
                        child: _selectedImage != null
                            ? (kIsWeb
                                // --- LÓGICA PARA WEB ---
                                // Usa Image.network com o caminho de memória do picker
                                ? Image.network(
                                    _selectedImage!.path, 
                                    fit: BoxFit.cover,
                                  )
                                // --- LÓGICA PARA MOBILE ---
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}