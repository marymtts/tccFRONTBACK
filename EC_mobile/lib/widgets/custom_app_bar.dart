// lib/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:ec_mobile/theme/app_colors.dart'; // Certifique-se de que este caminho está correto

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerIcon; // Para mostrar ou não o ícone do Drawer
  final List<Widget>? actions; // Para adicionar botões de ação (ex: filtro, busca)

  const CustomAppBar({
    super.key,
    required this.title,
    this.showDrawerIcon = true, // Por padrão, mostra o ícone do drawer
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Altura padrão do AppBar

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // --- 1. Remova o fundo sólido e use um sistema de sobreposição ---
      backgroundColor: Colors.transparent, // Torna o AppBar transparente
      elevation: 0, // Remove a sombra
      
      // --- 2. Adicione o fundo com degradê diretamente ao AppBar ---
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background, // Começa com o fundo normal
              AppColors.surface, // Termina com a cor do card
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      // --- 3. Ícone do Drawer Personalizado (se solicitado) ---
      leading: showDrawerIcon
          ? IconButton(
              icon: Icon(
                Icons.menu,
                color: AppColors.primaryText, // Cor do ícone
                size: 28, // Tamanho um pouco maior
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            )
          : null, // Não mostra o ícone se showDrawerIcon for false

      // --- 4. Título Estilizado ---
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 22, // Título um pouco maior
          fontWeight: FontWeight.bold, // Mais destaque
          letterSpacing: 0.5, // Um pequeno espaçamento para estilo
        ),
      ),

      // --- 5. Ações (botões do lado direito) ---
      actions: actions,
    );
  }
}