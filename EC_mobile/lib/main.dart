
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:ec_mobile/theme/app_colors.dart'; 
import 'package:ec_mobile/widgets/app_drawer.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Garante que o Flutter está pronto
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null); 

  runApp(const MyApp());
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});



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
    

    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                
                
                

                
                const SizedBox(height: 80), 
                _buildHeroSection(),
                const SizedBox(height: 80),
                _buildEventsSection(),
              ],
            ),
          ),
          

          
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
  );
}


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
          onPressed: () {},
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

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximos Eventos',
          
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText, 
          ),
        ),
        const SizedBox(height: 20),
        _buildEventCard(
          icon: Icons.biotech,
          iconColor: AppColors.iconBlue,
          date: '15 de Setembro, 19:30',
          title: 'Palestra: IA Generativa',
          description: 'Uma introdução ao mundo das IAs que criam texto e imagem.',
          linkText: 'Saiba Mais',
        ),
        const SizedBox(height: 20),
        _buildEventCard(
          icon: Icons.code,
          iconColor: AppColors.iconPink,
          date: '22 a 24 de Setembro',
          title: 'Hackathon de Inovação',
          description: 'Maratona de programação para criar soluções inovadoras para a cidade.',
          linkText: 'Inscreva-se Agora',
        ),
        
      ],
    );
  }

  Widget _buildEventCard({
    required IconData icon,
    required Color iconColor,
    required String date,
    required String title,
    required String description,
    required String linkText,
  }) {
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
          Row(
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
          )
        ],
      ),
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
}