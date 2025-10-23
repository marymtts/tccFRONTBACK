import 'package:flutter/material.dart';
import 'package:mobilegemini2/main.dart';
import 'package:mobilegemini2/theme/app_colors.dart'; // Importe suas cores
import 'package:mobilegemini2/screens/agenda_screen.dart';
import 'package:mobilegemini2/screens/calendario_screen.dart'; // <-- ADICIONE ESTA LINHA

class AppDrawer extends StatelessWidget {
  final String currentPage;

  // Recebemos a página atual para saber qual item destacar
  const AppDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Cor de fundo do menu
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero, // Remove o padding do topo
        children: [
          // Cabeçalho do Menu (com o logo)
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.background, // Cor de fundo do cabeçalho
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.accent, size: 32),
                const SizedBox(width: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 20,
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
          ),

          // O novo código
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            title: 'Início',
            isActive: currentPage == 'Início',
            onTap: () {
              Navigator.pop(context); // 1. Primeiro, fecha o drawer

              // 2. Verifica se já não estamos na página 'Início'
              if (currentPage != 'Início') {
                
                // 3. Navega para a HomeScreen usando 'pushReplacement'
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.event_note_outlined,
            title: 'Agenda',
            isActive: currentPage == 'Agenda',
            onTap: () {
              Navigator.pop(context); // Primeiro, fecha o drawer

              // Evita recarregar a página se já estivermos nela
              if (currentPage != 'Agenda') { 
                // 'pushReplacement' substitui a tela atual pela nova,
                // o que é melhor para navegação de menu principal
                // pois não empilha telas infinitamente.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AgendaScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.notifications_none_outlined,
            title: 'Avisos',
            isActive: currentPage == 'Avisos',
            onTap: () {
              // TODO: Navegar para a Tela de Avisos
              Navigator.pop(context); // Fecha o drawer
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'Calendário',
            isActive: currentPage == 'Calendário',
            onTap: () {
              // TODO: Navegar para a Tela de Calendário
              Navigator.pop(context); // Fecha o drawer

              // Evita recarregar a página se já estivermos nela
              if (currentPage != 'Calendário') { 
                // 'pushReplacement' substitui a tela atual pela nova,
                // o que é melhor para navegação de menu principal
                // pois não empilha telas infinitamente.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarioScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para criar cada item do menu (evita repetição)
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // Define as cores baseadas no estado 'ativo'
    final Color color = isActive ? Colors.white : AppColors.secondaryText;
    final Color? tileColor = isActive ? AppColors.accent : null;

    return Padding(
      // Adiciona um espaçamento horizontal para o item destacado
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16
          ),
        ),
        tileColor: tileColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }
}