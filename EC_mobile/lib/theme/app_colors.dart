// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // --- MUDANÇA: Fundos mais escuros/pretos ---
  static const Color background = Color(0xFF0C0C0C); // Quase preto
  static const Color surface = Color(0xFF1A1A1A); // Cinza-carvão para cards
  static const Color surfaceLight = Color(0xFF252C41); // Mantido (ou pode mudar)
  static const Color sectionBackground = Color(0xFF0C0C0C); // Igual ao fundo
  // ------------------------------------------

  // --- Textos (Sem mudança) ---
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF94A3B8);

  // --- Destaque Dourado (Sem mudança) ---
  static const Color accent = Color(0xFFEAB308);     
  static const Color accentOrange = Color(0xFFF59E0B);
  
  // Cores dos ícones da Home
  static const Color iconBgProximos = Color(0xFFEAB308); 
  static const Color iconBgCalendario = Color(0xFFF59E0B); 
  static const Color iconBgMeusEventos = Color(0xFFD97706);
}