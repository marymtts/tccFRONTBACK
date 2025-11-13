// lib/screens/editar_evento_screen.dart

import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para o token de "Deletar"
import 'package:image_cropper/image_cropper.dart';

class EditarEventoScreen extends StatefulWidget {
  final int eventId; // <-- PASSO 1: Recebe o ID do evento

  const EditarEventoScreen({super.key, required this.eventId});

  @override
  State<EditarEventoScreen> createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores (iguais aos da tela de criar)
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _maxParticipantesController = TextEditingController();
  
  // Variáveis de estado (iguais)
  bool _requerInscricao = true;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  XFile? _selectedImage; // Guarda a *nova* imagem selecionada
  
  // --- NOVAS Variáveis de Estado ---
  bool _isFetching = true; // Para o loading inicial
  bool _isUpdating = false; // Para o loading do "Salvar"
  bool _isDeleting = false; // Para o loading do "Deletar"
  String? _existingImageUrl; // Para guardar a URL da imagem antiga
  bool _removerImagem = false; // Flag para o PHP saber que deve apagar a imagem
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    // --- PASSO 2: Busca os dados do evento assim que a tela abre ---
    _fetchEventoData();
  }

  // --- NOVA FUNÇÃO: Busca os dados do evento ---
  Future<void> _fetchEventoData() async {
    try {
      // (Lembre-se de trocar pelo seu IP/URL: 10.0.2.2 para emulador, 192.168... para celular)
      final url = Uri.parse('https://tccfrontback.onrender.com/api/eventos.php?id=${widget.eventId}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // --- CORREÇÃO AQUI ---
        // Pega a string de data/hora completa (ex: '2025-11-13 19:00:00')
        final DateTime parsedDate = DateTime.parse(data['data_evento']);
        
        // --- Preenche o formulário com os dados do banco ---
        setState(() {
          _tituloController.text = data['titulo'] ?? '';
          _descricaoController.text = data['descricao'] ?? '';
          _selectedDate = DateTime.parse(data['data_evento']);
          _selectedTime = TimeOfDay.fromDateTime(parsedDate);
          _requerInscricao = (data['inscricao'] == '1' || data['inscricao'] == 1);
          _maxParticipantesController.text = data['max_participantes']?.toString() ?? '0';
          _existingImageUrl = data['imagem_url']; // Guarda a URL da imagem atual
          
          _isFetching = false; // Termina o loading
        });
      } else {
        throw Exception('Falha ao carregar dados do evento');
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
      setState(() { _isFetching = false; });
      if (mounted) {
        _showFeedbackSnackbar('Erro ao carregar dados. Tente novamente.', isError: true);
      }
    }
  }
  // --- FIM DA NOVA FUNÇÃO ---

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
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020), // Permite datas passadas para edição
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
    }
  }
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

  // --- FIM DAS FUNÇÕES IDÊNTICAS ---

// --- FUNÇÃO MODIFICADA: Envia a ATUALIZAÇÃO para a API ---
  Future<void> _submitUpdateEvent() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      return;
    }
    
    // --- MUDANÇA 1: Validar o horário ---
    if (_selectedTime == null) { 
      _showFeedbackSnackbar('Por favor, selecione um horário.', isError: true);
      return;
    }
    // ------------------------------------

    setState(() { _isUpdating = true; });

    // URL (está correta)
    final url = Uri.parse('https://tccfrontback.onrender.com/api/eventos.php?id=${widget.eventId}');

    try {
      // --- MUDANÇA 2: Combinar data e hora ---
      final DateTime finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour, // <-- Pega a hora
        _selectedTime!.minute, // <-- Pega o minuto
      );
      // ---------------------------------------

      var request = http.MultipartRequest('POST', url); // (Sim, 'POST')

      // Adiciona os campos de TEXTO
      request.fields['titulo'] = _tituloController.text;
      request.fields['descricao'] = _descricaoController.text;
      
      // --- MUDANÇA 3: Enviar a data e hora combinadas ---
      request.fields['data_evento'] = finalDateTime.toIso8601String(); // Formato 'AAAA-MM-DDTHH:MM:SS'
      // ----------------------------------------------------
      
      request.fields['inscricao'] = _requerInscricao.toString();
      request.fields['max_participantes'] = _maxParticipantesController.text.isEmpty 
                                          ? '0' 
                                          : _maxParticipantesController.text;
      request.fields['remover_imagem'] = _removerImagem.toString();

      // ... (O resto da sua lógica de imagem está correta) ...
      if (_selectedImage != null) {
        if (kIsWeb) {
          var imageBytes = await _selectedImage!.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes('imagem_evento', imageBytes, filename: _selectedImage!.name);
          request.files.add(multipartFile);
        } else {
          request.files.add(await http.MultipartFile.fromPath('imagem_evento', _selectedImage!.path));
        }
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) { // 'PUT' retorna 200 OK
        _showFeedbackSnackbar(responseData['message'] ?? 'Evento atualizado com sucesso!', isError: false);
        Navigator.pop(context); // Volta para a tela anterior
      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      print('Erro ao atualizar evento: $e');
      _showFeedbackSnackbar('Erro de conexão. Verifique o Render.', isError: true);
    } finally {
      setState(() { _isUpdating = false; });
    }
  }

  // --- NOVA FUNÇÃO: Deletar o evento ---
  Future<void> _deleteEvent() async {
    setState(() { _isDeleting = true; });

    // Pega o token de admin para autorizar o 'DELETE'
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      _showFeedbackSnackbar('Token de admin não encontrado. Faça login novamente.', isError: true);
      setState(() { _isDeleting = false; });
      return;
    }

    try {
      // Chama o 'case DELETE' do seu eventos.php
      final url = Uri.parse('https://tccfrontback.onrender.com/api/eventos.php?id=${widget.eventId}');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Envia o token de admin
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _showFeedbackSnackbar(responseData['message'] ?? 'Evento deletado com sucesso!', isError: false);
        // Volta 2 telas (sai do "Editar" e volta para a lista de "Próximos Eventos")
        Navigator.pop(context); 
        Navigator.pop(context); 
      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      print('Erro ao deletar evento: $e');
      _showFeedbackSnackbar('Erro de conexão ao deletar.', isError: true);
    } finally {
      setState(() { _isDeleting = false; });
    }
  }

  // --- NOVA FUNÇÃO: Diálogo de confirmação ---
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Você tem certeza que deseja deletar este evento permanentemente? Esta ação não pode ser desfeita.'),
          backgroundColor: AppColors.surface,
          actions: [
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Deletar', style: TextStyle(color: AppColors.accent)),
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
                _deleteEvent(); // Chama a função de deletar
              },
            ),
          ],
        );
      },
    );
  }

  // Função auxiliar para mostrar feedback
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
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _maxParticipantesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Evento'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      // --- MOSTRA O LOADING INICIAL ---
      body: _isFetching
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Campo Título ---
                    TextFormField(
                      controller: _tituloController, // Já vem preenchido
                      decoration: _buildInputDecoration('Título do Evento'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Campo Descrição ---
                    TextFormField(
                      controller: _descricaoController, // Já vem preenchido
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
                                  // Já vem preenchido
                                  : DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!),
                              style: TextStyle(color: _selectedDate == null ? AppColors.secondaryText : Colors.white, fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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

                    // --- Switch "Requer Inscrição" ---
                    SwitchListTile(
                      title: Text(
                        'Requer Inscrição?',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 16),
                      ),
                      subtitle: Text(
                        _requerInscricao ? 'Sim, vagas serão controladas.' : 'Não, evento aberto ao público.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      value: _requerInscricao, // Já vem preenchido
                      activeColor: AppColors.accent,
                      onChanged: (bool newValue) {
                        setState(() { _requerInscricao = newValue; });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16), 

                    // --- Campo "Máximo de Vagas" ---
                    if (_requerInscricao)
                      TextFormField(
                        controller: _maxParticipantesController, // Já vem preenchido
                        decoration: _buildInputDecoration('Número Máximo de Vagas (0 = ilimitado)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                      ),
                    
                    const SizedBox(height: 24),

                    // --- Seletor de Imagem (LÓGICA ATUALIZADA) ---
                    Text('Imagem do Evento:', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondaryText, width: 0.5),
                        ),
                        child: _buildImagePreview(), // <-- Lógica de imagem extraída
                      ),
                    ),
                    
                    // --- NOVO BOTÃO: Remover Imagem ---
                    if (_existingImageUrl != null && !_removerImagem)
                      TextButton.icon(
                        icon: Icon(Icons.delete_outline, color: AppColors.secondaryText),
                        label: Text('Remover Imagem Atual', style: TextStyle(color: AppColors.secondaryText)),
                        onPressed: () {
                          setState(() {
                            _removerImagem = true;
                            _selectedImage = null; // Cancela nova imagem se houver
                          });
                        },
                      ),
                    
                    const SizedBox(height: 40),

                    // --- Botão Salvar Alterações ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Se estiver atualizando ou deletando, desabilita
                        onPressed: (_isUpdating || _isDeleting) ? null : _submitUpdateEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isUpdating 
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Salvar Alterações', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // --- NOVO BOTÃO: Deletar Evento ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.delete_forever_outlined),
                        label: _isDeleting 
                                ? CircularProgressIndicator(color: AppColors.accent)
                                : Text('Deletar Evento'),
                        onPressed: (_isUpdating || _isDeleting) ? null : _showDeleteDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent, // Vermelho
                          side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- NOVA FUNÇÃO AUXILIAR: Lógica de preview da imagem ---
  Widget _buildImagePreview() {
    // 1. Se o usuário acabou de selecionar uma NOVA imagem
    if (_selectedImage != null) {
      if (kIsWeb) {
        return Image.network(_selectedImage!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_selectedImage!.path), fit: BoxFit.cover);
      }
    }
    // 2. Se o usuário marcou "Remover Imagem"
    if (_removerImagem) {
      return _buildImagePlaceholder(); // Mostra o placeholder
    }
    // 3. Se existe uma imagem antiga do banco E o usuário não removeu
    if (_existingImageUrl != null) {
      // O seu PHP salva a URL como '/uploads/eventos/evento_123.png'
      // Precisamos adicionar o IP completo do servidor para o app carregar
      final String fullImageUrl = 'https://tccfrontback.onrender.com$_existingImageUrl';
      
      return Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        // Mostra um erro se a imagem antiga não for encontrada
        errorBuilder: (context, error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            Text('Não foi possível carregar a imagem', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    // 4. Se não houver nada (padrão)
    return _buildImagePlaceholder();
  }

  // Placeholder padrão (o mesmo da tela de criar)
  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, color: AppColors.secondaryText, size: 40),
        SizedBox(height: 8),
        Text('Clique para selecionar uma imagem', style: TextStyle(color: AppColors.secondaryText)),
      ],
    );
  }
  // --- FIM DA LÓGICA DE IMAGEM ---

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