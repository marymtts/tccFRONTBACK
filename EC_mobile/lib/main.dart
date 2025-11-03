// ignore_for_file: avoid_print, sort_child_properties_last

import 'dart:convert'; 
import 'package:ec_mobile/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:ec_mobile/theme/app_colors.dart'; 
import 'package:ec_mobile/widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:ec_mobile/screens/proximos_eventos_screen.dart';
import 'package:ec_mobile/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/auth_check_screen.dart';

void main() async {
 
  WidgetsFlutterBinding.ensureInitialized();


  await initializeDateFormatting('pt_BR', null); 

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(), // O seu app agora é "filho" do Provedor
    ),
  ); 

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventos Cotil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background, 
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme), 
        elevatedButtonTheme: ElevatedButtonThemeData( 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primaryText,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthCheckScreen(),//const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { // <--- MUDE AQUI
  const HomeScreen({super.key});

  @override // <-- ADICIONE ESTAS DUAS LINHAS
  State<HomeScreen> createState() => _HomeScreenState(); 
} // <--- A CHAVE QUE VOCÊ MENCIONOU AGORA FECHA AQUI!

class _HomeScreenState extends State<HomeScreen> { // <-- Nova classe de Estado

  // --- MUDANÇA 1: Adicionar variáveis de estado ---
  List<dynamic> _featuredEvents = []; // Lista para guardar os eventos da API
  bool _isLoading = true;
  String _errorMessage = '';
  // --- FIM DA MUDANÇA 1 ---

  // --- MUDANÇA 2: Adicionar initState e a função da API ---
  @override
  void initState() {
    super.initState();
    _fetchFeaturedEvents();
  }

  Future<void> _fetchFeaturedEvents() async {
    // !!! MUDE A URL para o seu endpoint de eventos em destaque !!!
    // Exemplo: 'http://192.168.15.174/EC_back/api/get_eventos_destaque.php'
    // Por enquanto, vou usar o mesmo endpoint de todos os eventos
    final url = Uri.parse('http://192.168.15.174/EC_back/api/eventos.php');

    // (Lembre-se das URLs para Emulador/Celular Físico se precisar)

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // ATENÇÃO: Se você tiver um endpoint que retorna SÓ os destaques,
        // talvez não precise filtrar. Se não, filtre aqui.
        // Exemplo simples: Pegar os 3 primeiros eventos
        final List<dynamic> featured = data.take(3).toList(); 

        setState(() {
          _featuredEvents = featured; // Guarda os eventos filtrados
          _isLoading = false;
        });

      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar eventos (Erro ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique o XAMPP e a URL.';
        _isLoading = false;
      });
    }
  }
  // --- FIM DA MUDANÇA 2 ---


 // Dentro da classe _HomeScreenState

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPage: 'Início'),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
                children: [
                  TextSpan(text: 'Eventos '),
                  TextSpan(
                    text: 'Cotil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: TextButton(
              onPressed: () {},
              child: const Text('Divulgue!'),
              style: TextButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
      // --- AQUI ESTÁ A CORREÇÃO PARA CARREGANDO/ERRO ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra o círculo de carregamento
          : _errorMessage.isNotEmpty
              ? Center( // Mostra a mensagem de erro se ela existir
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : SingleChildScrollView( // Mostra o conteúdo principal se não houver erro e não estiver carregando
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conteúdo com fundo principal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80),
                            _buildHeroSection(),
                            const SizedBox(height: 80),
                            _buildEventsSection(), // Usa os dados da API
                          ],
                        ),
                      ),
                      // Conteúdo com fundo secundário
                      Container(
                        width: double.infinity,
                        color: AppColors.sectionBackground,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 80),
                              _buildAboutUsSection(),
                              const SizedBox(height: 80),
                              _buildCtaSection(),
                              const SizedBox(height: 80),
                              _buildFooter(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      // --- FIM DA CORREÇÃO ---
    );
  }
  // --- FIM DA MUDANÇA 3 ---


  // As funções _buildHeroSection, _buildAboutUsSection, _buildCtaSection, _buildFooter
  // continuam EXATAMENTE IGUAIS.

    Widget _buildHeroSection() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.primaryText, 
            ),
            children: const [
              TextSpan(text: 'Fique por dentro de tudo que acontece no '),
              TextSpan(
                text: 'Cotil.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'O seu guia completo para os eventos, palestras, workshops e atividades que enriquecem sua jornada no colégio.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 16
          ),
        ),
        const SizedBox(height: 30),
        
        TextButton(
          onPressed: () {
            Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProximosEventosScreen()),
        );
          },
          child: const Text('Ver Próximos Eventos', style: TextStyle(fontSize: 16)),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
        ),
      ],
    );
  } 
  Widget _buildAboutUsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quem somos?',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 15),
      const Text(
        'O "Eventos Cotil" é uma iniciativa 100% feita por alunos, para alunos. Nós percebemos que muitas oportunidades incríveis passavam despercebidas por falta de divulgação.\n\nNossa missão é simples: conectar você a todas as experiências que o Cotil oferece, garantindo que ninguém perca a chance de aprender, se divertir e crescer.',
        style: TextStyle(color: AppColors.secondaryText, height: 1.6),
      ),
      const SizedBox(height: 30),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Equipe Eventos Cotil',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
Widget _buildCtaSection() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        const Text(
          'Tem um evento para divulgar?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 15),
        const Text(
          'É organizador de algum centro acadêmico, atlética, ou está planejando algo incrível? Manda pra gente! Teremos o prazer de ajudar na divulgação.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondaryText, height: 1.6),
        ),
        const SizedBox(height: 25),
        
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: const Text(
              'Fale Conosco',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _buildFooter() {
  return const Center(
    child: Text(
      '© 2025 Eventos Cotil. Uma iniciativa de alunos para alunos.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 12,
      ),
    ),
  );
}


  // --- MUDANÇA 4: Modificar _buildEventsSection ---
  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por onde você quer começar?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 20),

        // A MÁGICA: Em vez de chamadas fixas, fazemos um loop
        // sobre a lista _featuredEvents que veio da API.
        Column(
          children: _featuredEvents.map((event) {
            // Para cada 'event' na lista, criamos um Card
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Adiciona espaço entre cards
              child: _buildEventCard(
                // !!! MUDE AQUI para usar as chaves do seu JSON !!!
                icon: _getIconForEvent(event['titulo'] ?? ''), // Função auxiliar para ícone (exemplo)
                iconColor: _getColorForEvent(event['titulo'] ?? ''), // Função auxiliar para cor (exemplo)
                date: _formatApiDate(event['data_evento'] ?? ''), // Função auxiliar para formatar data
                title: event['titulo'] ?? 'Título indisponível',
                description: event['descricao'] ?? 'Descrição indisponível', // Use a descrição curta se tiver
                linkText: (event['inscricao'] ?? 0) == 1 ? 'Inscreva-se Agora' : 'Saiba Mais',
              ),
            );
          }).toList(), // Transforma o resultado do map em uma lista de Widgets
        ),
      ],
    );
  }
  // --- FIM DA MUDANÇA 4 ---


  // A função _buildEventCard continua IGUAL.
  // Ela já recebe os dados como parâmetros.
  Widget _buildEventCard({
    required IconData icon,
    required Color iconColor,
    required String date,
    required String title,
    required String description,
    required String linkText,
  }) {
    /* ... seu código do _buildEventCard ... */
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: AppColors.surface,
         borderRadius: BorderRadius.circular(8),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: iconColor,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Icon(icon, size: 24, color: Colors.white),
           ),
           const SizedBox(height: 15),
           Text(date, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
           const SizedBox(height: 5),
           Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
           const SizedBox(height: 10),
           Text(description, style: const TextStyle(color: AppColors.secondaryText, height: 1.5)),
           const SizedBox(height: 20),
           // Adicionar Navegação ao clicar no link
           InkWell( 
             onTap: () {
               // 
               // Ex: Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheScreen(eventId: event['id'])));
             },
             child: Row(
               children: [
                 Text(
                   linkText,
                   style: const TextStyle(
                     fontWeight: FontWeight.bold,
                     color: AppColors.primaryText, 
                   ),
                 ),
                 const SizedBox(width: 5),
                 const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryText),
               ],
             ),
           )
         ],
       ),
     );
  }


  // --- MUDANÇA 5: Funções Auxiliares (Exemplos) ---
  // Você precisará criar lógicas para escolher ícone/cor e formatar data
  IconData _getIconForEvent(String title) {
    if (title.toLowerCase().contains('palestra')) return Icons.biotech;
    if (title.toLowerCase().contains('hackathon')) return Icons.code;
    return Icons.event; // Ícone padrão
  }

  Color _getColorForEvent(String title) {
    if (title.toLowerCase().contains('palestra')) return AppColors.iconBlue;
    if (title.toLowerCase().contains('hackathon')) return AppColors.iconPink;
    return AppColors.iconGreen; // Cor padrão
  }

  String _formatApiDate(String apiDate) {
    try {
      // Converte 'AAAA-MM-DD' para DateTime
      final DateTime parsedDate = DateTime.parse(apiDate);
      // Formata para 'DD de MMMM, HH:mm' (ou o formato que preferir)
      return DateFormat('dd \'de\' MMMM', 'pt_BR').format(parsedDate); 
    } catch (e) {
      return apiDate; // Retorna a string original se a formatação falhar
    }
  }
  // --- FIM DA MUDANÇA 5 ---

} // Fim da classe _HomeScreenState









  






