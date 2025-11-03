// lib/widgets/app_drawer.dart
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

class AppDrawer extends StatelessWidget {
  final String currentPage;

  const AppDrawer({super.key, required this.currentPage});

  // --- FUNÇÃO DE LOGOUT (Centralizada aqui) ---
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

  @override
  Widget build(BuildContext context) {
    // PASSO 1: Lê o usuário logado (do Provider)
    final user = Provider.of<UserProvider>(context).user;

    return Drawer(
      // --- MANTÉM O TEMA ESCURO ---
      backgroundColor: AppColors.surface, // Seu fundo escuro original

      child: ListView(
        padding: EdgeInsets.zero, // Remove o espaço no topo
        children: [
          // --- MUDANÇA: O Novo Cabeçalho do Perfil ---
          // Substitui o DrawerHeader antigo pelo novo
          _buildProfileHeader(user), 

          // --- Itens do Menu (com cores escuras) ---
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            title: 'Início',
            pageName: 'Início',
            currentPage: currentPage,
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
              if (currentPage != 'Calendário') {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const CalendarioScreen()));
              }
            },
          ),

          // --- Itens que dependem do Login ---
          
          if (user != null) // Só mostra se estiver logado
            _buildNavItem(
              context,
              icon: Icons.person_outline,
              title: 'Minha Conta',
              pageName: 'Conta',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Conta') {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const ContaScreen()));
                }
              },
            ),

         // if (user != null && user.role == 'aluno') // Só para alunos
            _buildNavItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Meus Eventos',
              pageName: 'MeusEventos',
              currentPage: currentPage,
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'MeusEventos') {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const MeusEventosScreen()));
                }
              },
            ),

          // --- Item de Admin (Comentado) ---
          
          if (user != null && user.role == 'admin')
            _buildNavItem(
              context,
              icon: Icons.qr_code_scanner,
              title: 'Validar Entradas',
              pageName: 'Validar',
              currentPage: currentPage,
              onTap: () { /* ... */ },
            ),

          // (Linha 152)
             _buildNavItem(
              context,
              icon: Icons.add_circle_outline, // ícone de "adicionar"
              title: 'Criar Evento',
              pageName: 'CriarEvento', // <-- MUDANÇA AQUI
              currentPage: currentPage,  // <-- MUDANÇA AQUI
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CriarEventoScreen()),
                );
              },
            ),
          

          // Linha divisória (agora com cor clara)
          if (user != null)
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 16.0),
               child: Divider(color: AppColors.secondaryText, height: 1),
             ),

          // --- Item de Sair/Entrar ---
          if (user != null) // Se está logado, mostra "Sair"
            _buildNavItem(
              context,
              icon: Icons.logout,
              title: 'Sair',
              pageName: 'Sair',
              currentPage: currentPage,
              onTap: () => _logout(context), // Chama a função de logout
            )
          else // Se está deslogado, mostra "Entrar"
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
      ),
    );
  }

  // --- Constrói o novo cabeçalho com TEMA ESCURO ---
  Widget _buildProfileHeader(User? user) {
    // Se o usuário estiver deslogado, mostra um cabeçalho simples
    if (user == null) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppColors.background), // Cor de fundo mais escura
        child: Center(
          child: Text(
            'Bem-vindo ao Eventos Cotil',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Se estiver logado, mostra o perfil (layout da foto, cores do seu app)
    return Container(
      color: AppColors.background, // Cor de fundo mais escura
      padding: const EdgeInsets.only(top: 50.0, bottom: 20.0, left: 20.0, right: 20.0),
      child: Row(
        children: [
          // Avatar (círculo roxo com a inicial)
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent, // Sua cor vermelha/destaque
            child: Text(
              user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          // Coluna com Nome e Email (ou RA)
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
                  overflow: TextOverflow.ellipsis, // Evita quebrar o nome
                ),
                const SizedBox(height: 5),
                Text(
                  user.email, // Você pode trocar por user.ra se preferir
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


  // --- Ajusta as cores dos itens para o TEMA ESCURO ---
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String pageName,
    required String currentPage,
    required VoidCallback onTap,
  }) {
    // Verifica se este é o item da página ativa
    final bool isActive = (currentPage == pageName);

    // Define as cores baseadas no fundo escuro
    final Color color = isActive ? AppColors.accent : AppColors.secondaryText;
    final Color? tileColor = isActive ? AppColors.accent.withOpacity(0.1) : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      tileColor: tileColor, // Cor de fundo se estiver ativo
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}