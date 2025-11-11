// ignore_for_file: avoid_print, sort_child_properties_last

import 'dart:convert'; 
import 'package:ec_mobile/screens/calendario_screen.dart';
import 'package:ec_mobile/screens/login_screen.dart';
import 'package:ec_mobile/screens/meus_eventos_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:ec_mobile/theme/app_colors.dart'; 
import 'package:ec_mobile/widgets/app_drawer.dart'; // Importa AppDrawer e AppDrawerContent
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
      home: const AuthCheckScreen(), //const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget { 
  const HomeScreen({super.key});

  @override 
  State<HomeScreen> createState() => _HomeScreenState(); 
} 

// --- AQUI COMEÇA A CLASSE DE ESTADO (onde tudo acontece) ---
class _HomeScreenState extends State<HomeScreen> { 

  // --- 1. A FUNÇÃO DO MENU DE BAIXO (NO LUGAR CERTO) ---
  void _showBottomMenu(BuildContext context, String currentPage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Fundo transparente para a borda
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permite controlar a altura
      builder: (BuildContext context) {
        // Define a altura (ex: 85% da tela)
        return FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: 0.85, 
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              color: AppColors.surface, // Cor de fundo do seu menu
              // Aqui chamamos o CONTEÚDO que refatoramos
              child: AppDrawer(currentPage: currentPage), 
            ),
          ),
        );
      },
    );
  }

  // --- 2. SUAS VARIÁVEIS (NO LUGAR CERTO) ---
  List<dynamic> _featuredEvents = []; 
  bool _isLoading = true;
  String _errorMessage = '';

  // --- 3. SEU MÉTODO BUILD (PRINCIPAL) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // --- 4. APPBAR CORRIGIDO (para o menu de baixo) ---
      appBar: AppBar(
        backgroundColor: AppColors.surface, // Sua cor
        elevation: 0,
        title: const Text('Início', style: TextStyle(fontWeight: FontWeight.bold)),
        // O ícone do menu
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.primaryText, size: 28),
            onPressed: () {
              // --- 5. CONECTADO NA FUNÇÃO CERTA ---
              _showBottomMenu(context, 'Início'); 
            },
          ),
        ),
      ),
      
      // --- 6. LINHA DO DRAWER REMOVIDA ---
      // drawer: const AppDrawer(currentPage: 'Início'), // <-- Linha apagada

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- 7. IMAGEM MOVIDA PARA CÁ (PONTA-A-PONTA) ---
            Image.asset(
              'assets/images/echolder.jpg', // O caminho da sua imagem
              width: double.infinity,      // <-- FORÇA A LARGURA TOTAL
              height: 200,                 // <-- Mudei de 300 para 200 (fica mais proporcional)
              fit: BoxFit.cover,           // <-- Faz a imagem cobrir o espaço
            ),
            // --------------------------------------------------
            
            // Seção "Hero" e "Navegação" (fundo principal)
            Padding(
              // O padding agora só afeta o texto e os botões
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40), // Espaço entre a imagem e o texto
                  _buildHeroSection(), // Agora esta função só tem texto e botão
                  const SizedBox(height: 80),
                  _buildNavigationSection(), // <-- A NOVA SEÇÃO DE BOTÕES
                ],
              ),
            ),
            
            // Seção "Quem Somos" e Rodapé (fundo secundário)
            Container(
              width: double.infinity, 
              color: AppColors.sectionBackground, // Use a cor de contraste que você gostou
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    _buildAboutUsSection(), // Continua igual
                    const SizedBox(height: 80),
                    _buildCtaSection(), // Continua igual
                    const SizedBox(height: 80),
                    _buildFooter(), // Continua igual
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- FIM DO MÉTODO BUILD ---

  // --- 8. _buildHeroSection (CORRIGIDA - SEM A IMAGEM) ---
  Widget _buildHeroSection() {
    return Column(
      children: [
        // --- Imagem removida daqui ---

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
          // Corrigi o texto de volta
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
  
  // --- O RESTO DAS SUAS FUNÇÕES (sem mudanças) ---

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

  Widget _buildNavigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por onde você quer começar?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText , 
          ),
        ),
        const SizedBox(height: 20),

        // Botão 1: Próximos Eventos
        _buildNavCard(
          icon: Icons.view_agenda_outlined,
          title: 'Próximos Eventos',
          subtitle: 'Fique por dentro do que está por vir!',
          iconBackgroundColor: const Color.fromRGBO(240, 28, 28, 0.863),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProximosEventosScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        // Botão 2: Calendário
        _buildNavCard(
          icon: Icons.calendar_today,
          title: 'Calendário',
          subtitle: 'Explore e programe suas participações',
          iconBackgroundColor: const Color.fromRGBO(240, 28, 28, 0.863),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarioScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

       _buildNavCard(
          icon: Icons.check_circle, // Ícone sólido
          title: 'Meus Eventos',
          subtitle: 'Eventos em que você está inscrito',
          iconBackgroundColor: const Color.fromRGBO(240, 28, 28, 0.863), // <-- CORRIGI A COR
          onTap: () {
            final user = Provider.of<UserProvider>(context, listen: false).user;
            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MeusEventosScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackgroundColor, // <-- 1. RECEBE A COR
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: iconBackgroundColor.withOpacity(0.2), // Efeito de clique
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Padding "grosso"
          child: Row(
            children: [
              // --- 2. O ÍCONE QUADRADO ---
              Container(
                width: 60,  // Tamanho grande
                height: 60, // Tamanho grande
                decoration: BoxDecoration(
                  color: iconBackgroundColor, // <-- 3. USA A COR SÓLIDA
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconBackgroundColor.withOpacity(0.4), // Sombra da mesma cor
                      blurRadius: 15.0,   // "Esfumaçado" do bloom
                      spreadRadius: 3.0,    // Espalha o brilho
                      offset: const Offset(0, 6), // Deslocamento para baixo
                    ),
                  ], 
                ),
                child: Icon(icon, color: Colors.white, size: 30), // Ícone maior
              ),
              const SizedBox(width: 20),
              
              // Textos (continuam iguais)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

} // --- FIM DA CLASSE _HomeScreenState ---