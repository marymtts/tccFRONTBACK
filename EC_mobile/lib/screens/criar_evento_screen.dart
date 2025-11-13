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
import 'package:image_cropper/image_cropper.dart';

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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime; // Guarda a data selecionada
  XFile? _selectedImage; // Guarda o arquivo de imagem selecionado
  
  bool _isLoading = false;

  // --- Função para abrir a Galeria/Câmera E CORTAR ---
Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  // 1. Pega a imagem da galeria (como antes)
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  // Se o usuário cancelou a seleção, não faz nada
  if (image == null) return;

  // --- 2. CHAMA A TELA DE RECORTE ---
  final CroppedFile? croppedImage = await ImageCropper().cropImage(
    sourcePath: image.path,

    // Define a proporção (ex: 16:9 para um banner)
    // Se quiser um quadrado, use: CropAspectRatio(ratioX: 1, ratioY: 1)
    aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),

    // --- Deixa o cropper com a sua identidade visual ---
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recortar Imagem',
        toolbarColor: AppColors.surface, // Sua cor
        toolbarWidgetColor: Colors.white, // Cor do texto e ícones
        initAspectRatio: CropAspectRatioPreset.ratio16x9, // Começa em 16:9
        lockAspectRatio: true, // Força o usuário a usar 16:9
        backgroundColor: AppColors.background,
        activeControlsWidgetColor: AppColors.accent, // Controles em vermelho
      ),
      IOSUiSettings(
        title: 'Recortar Imagem',
        aspectRatioLockEnabled: true,
        doneButtonTitle: 'Concluir',
        cancelButtonTitle: 'Cancelar',
      ),
    ],
  );
  // --- FIM DA TELA DE RECORTE ---

  // 3. Salva a imagem CORTADA
  if (croppedImage != null) {
    setState(() {
      // O _selectedImage agora é o ARQUIVO CORTADO
      _selectedImage = XFile(croppedImage.path);
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
  

  // --- Função para mostrar o TimePicker (Relógio) ---
  Future<void> _pickTime(BuildContext context) async {
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked; // Armazena a hora selecionada
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
    
    // --- MUDANÇA 1: Validar o horário ---
    if (_selectedTime == null) { 
      _showFeedbackSnackbar('Por favor, selecione um horário para o evento.', isError: true);
      return;
    }
    // ------------------------------------

    setState(() { _isLoading = true; });

    // 2. URL da API (está correta)
    final url = Uri.parse('https://tccfrontback.onrender.com/api/eventos.php');

    try {
      // --- MUDANÇA 2: Combinar data e hora ---
      final DateTime finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      // ---------------------------------------

      // 3. Cria a Requisição "Multipart"
      var request = http.MultipartRequest('POST', url);

      // 4. Adiciona os campos de TEXTO
      request.fields['titulo'] = _tituloController.text;
      request.fields['descricao'] = _descricaoController.text;
      
      // --- MUDANÇA 3: Enviar a data e hora combinadas ---
      request.fields['data_evento'] = finalDateTime.toIso8601String(); // Formato 'AAAA-MM-DD HH:MM:SS'
      // ----------------------------------------------------
      
      // (O resto do seu código está perfeito)
      request.fields['inscricao'] = _requerInscricao.toString(); 
      request.fields['max_participantes'] = _maxParticipantesController.text.isEmpty
                                          ? '0' 
                                          : _maxParticipantesController.text;

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
      _showFeedbackSnackbar('Erro de conexão. Verifique o Render.', isError: true); // Atualizei a msg de erro
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
                    const SizedBox(height: 16),

                    // --- NOVO SELETOR DE HORÁRIO ---
                    InkWell(
                      onTap: () => _pickTime(context), // Chama a nova função
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
                              _selectedTime == null
                                  ? 'Selecione um horário'
                                  : _selectedTime!.format(context), // Formata ex: "19:00"
                              style: TextStyle(color: _selectedTime == null ? AppColors.secondaryText : Colors.white, fontSize: 16),
                            ),
                            const Icon(Icons.access_time, color: AppColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    // ---------------------------
                    const SizedBox(height: 24),
                    
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