// lib/widgets/app_drawer.dart
import 'package:ec_mobile/screens/admin_controle_selecionar_screen.dart';
import 'package:ec_mobile/screens/admin_selecionar_evento_screen.dart';
import 'package:ec_mobile/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ec_mobile/models/user.dart'; // Importa o "molde" do usuário
import 'package:ec_mobile/providers/user_provider.dart'; // Para ler quem está logado
import 'package:ec_mobile/theme/app_colors.dart';

// Telas para Navegação
import 'package:ec_mobile/main.dart'; // HomeScreen
import 'package:ec_mobile/screens/calendario_screen.dart';
import 'package:ec_mobile/screens/conta_screen.dart';
import 'package:ec_mobile/screens/meus_eventos_screen.dart';
import 'package:ec_mobile/screens/login_screen.dart'; // Para o Logout
import 'package:shared_preferences/shared_preferences.dart'; // Para o Logout
import 'package:ec_mobile/screens/criar_evento_screen.dart';

// -----------------------------------------------------------------
// CLASSE 1: O CONTAINER (O DRAWER LATERAL ANTIGO)
// -----------------------------------------------------------------
// (Não estamos mais usando, mas é bom manter)
class AppDrawer extends StatelessWidget {
  final String currentPage;

  const AppDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    // O Drawer lateral original
    return Drawer(
      backgroundColor: AppColors.surface,
      // Agora ele só chama o "Conteúdo"
      child: AppDrawerContent(currentPage: currentPage),
    );
  }
}


// -----------------------------------------------------------------
// CLASSE 2: O CONTEÚDO (O QUE VAI APARECER NO MENU DE BAIXO)
// -----------------------------------------------------------------
// (Esta é a classe que tem todo o seu código)
class AppDrawerContent extends StatelessWidget {
  final String currentPage;

  const AppDrawerContent({super.key, required this.currentPage});

  // --- FUNÇÃO DE LOGOUT (Movida para cá) ---
  Future<void> _logout(BuildContext context) async {
    // 1. Apaga o token do "cofre"
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    // 2. Limpa o usuário do "provedor"
    Provider.of<UserProvider>(context, listen: false).clearUser();

    // 3. Garante que estamos com o contexto certo
    if (!context.mounted) return;

    // 4. Navega para o Login e limpa todas as telas
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Remove todas
    );
  }

  // --- Constrói o cabeçalho (Movido para cá) ---
  Widget _buildProfileHeader(User? user) {
    // Se o usuário estiver deslogado
    if (user == null) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppColors.background), 
        child: Center(
          child: Text(
            'Bem-vindo ao Eventos Cotil',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    // Se estiver logado
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 50.0, bottom: 20.0, left: 20.0, right: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent,
            child: Text(
              user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Constrói os itens do menu (COM A MUDANÇA PARA "ROBUSTO") ---
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String pageName,
    required String currentPage,
    required VoidCallback onTap,
  }) {
    final bool isActive = (currentPage == pageName);
    final Color color = isActive ? AppColors.accent : AppColors.secondaryText;
    final Color? tileColor = null;

    // --- 1. AUMENTA O PADDING VERTICAL ---
    const EdgeInsets itemPadding = EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0);

    // --- 2. AUMENTA O TAMANHO DO ÍCONE E DA FONTE ---
    const double iconSize = 28.0;
    const double fontSize = 18.0;

    return ListTile(
      contentPadding: itemPadding, // <-- APLICA O PADDING
      leading: Icon(icon, color: color, size: iconSize), // <-- APLICA O TAMANHO DO ÍCONE
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize, // <-- APLICA O TAMANHO DA FONTE
        ),
      ),
      tileColor: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }


  @override
  Widget build(BuildContext context) {
    // 1. Pega o usuário logado
    final user = Provider.of<UserProvider>(context).user;
    
    // 2. Retorna SÓ o ListView (sem o Drawer)
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildProfileHeader(user), // O cabeçalho do perfil

        // --- Itens Normais (para todos) ---
        _buildNavItem(
            context,
            icon: Icons.home_outlined,
            title: 'Início',
            pageName: 'Início',
            currentPage: currentPage,
            onTap: () {
              Navigator.pop(context); // Fecha o menu de baixo
              if (currentPage != 'Início') {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              }
            },
          ),
          
          _buildNavItem(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'Calendário',
            pageName: 'Calendário',
            currentPage: currentPage,
            onTap: () {
              Navigator.pop(context); // Fecha o menu de baixo
              if (currentPage != 'Calendário') {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const CalendarioScreen()));
              }
            },
          ),

        // --- Seção do Usuário LOGADO ---
        if (user != null) ...[ 
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            title: 'Minha Conta',
            pageName: 'Conta',
            currentPage: currentPage,
            onTap: () {
              Navigator.pop(context); // Fecha o menu de baixo
              if (currentPage != 'Conta') {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ContaScreen()));
              }
            },
          ),

          // --- SEÇÃO DO ALUNO ---
          if (user.role == 'aluno')
            _buildNavItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Meus Eventos',
              pageName: 'MeusEventos',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context); // Fecha o menu de baixo
                if (currentPage != 'MeusEventos') {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const MeusEventosScreen()));
                }
              },
            ),

          // --- SEÇÃO DO ADMIN ---
          if (user.role == 'admin') ...[
            _buildNavItem(
              context,
              icon: Icons.qr_code_scanner,
              title: 'Validar Entradas',
              pageName: 'Scanner',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context); // Fecha o menu de baixo
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const AdminSelecionarEventoScreen()));
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.people_outline,
              title: 'Controle de Eventos',
              pageName: 'ControleEventos',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context); // Fecha o menu de baixo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminControleSelecionarScreen(),
                  ),
                );
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.add_circle_outline, 
              title: 'Criar Evento',
              pageName: 'CriarEvento',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context); // Fecha o menu de baixo
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CriarEventoScreen()),
                );
              },
            ),
          ],
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: AppColors.secondaryText, height: 1),
          ),

          // --- Item "Sair" ---
          _buildNavItem(
            context,
            icon: Icons.logout,
            title: 'Sair',
            pageName: 'Sair',
            currentPage: currentPage,
            onTap: () => _logout(context), // Chama a função de logout
          )
        
        ] else ...[ // Se user == null (deslogado)
          
          // --- Item "Entrar" ---
          _buildNavItem(
            context,
            icon: Icons.login,
            title: 'Entrar',
            pageName: 'Login',
            currentPage: currentPage,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ],
    );
  }
}