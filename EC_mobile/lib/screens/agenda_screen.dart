import 'package:flutter/material.dart';
import 'package:ec_mobile/theme/app_colors.dart'; // Importe suas cores
import 'package:ec_mobile/widgets/app_drawer.dart'; // Importe seu Drawer


class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Eventos'),
        backgroundColor: AppColors.surface, // Cor da barra de topo
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: 'Agenda'), // Passa a página atual
      
      // O corpo da tela será uma lista rolável
      body: ListView(
        // Adiciona um padding em volta da lista
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEventTile(
            title: 'Semana de Tecnologia 2025',
            date: '18/08/2025',
            description: 'Uma semana inteira dedicada a palestras, workshops e competições sobre as mais novas tecnologias do mercado. Evento aberto para todos os alunos.',
            showButton: true,
            initiallyExpanded: true, // Deixa o primeiro item aberto por padrão
          ),
          const SizedBox(height: 10), // Espaçamento entre os itens
          _buildEventTile(
            title: 'Palestra: IA no Mercado',
            date: '20/08/2025',
            description: 'Descrição completa sobre a palestra de IA no mercado...',
            showButton: true,
          ),
          const SizedBox(height: 10),
          _buildEventTile(
            title: 'Feira de Ciências Anual',
            date: '22/09/2025',
            description: 'Apresentação dos projetos de ciências desenvolvidos pelos alunos ao longo do ano.',
            showButton: false, 
          ),
          const SizedBox(height: 10),
          _buildEventTile(
            title: 'Campeonato de E-Sports',
            date: '05/10/2025',
            description: 'Torneio de League of Legends e CS:GO. Monte sua equipe e participe!',
            showButton: true,
          ),
        ],
      ),
    );
  }

  // Este é o nosso novo componente: o "Painel Expansível"
  // Este é o nosso novo componente: o "Painel Expansível"
  Widget _buildEventTile({
    required String title,
    required String date,
    required String description,
    required bool showButton,
    bool initiallyExpanded = false,
  }) {
    // Usamos o ClipRRect para forçar que o ExpansionTile tenha bordas arredondadas
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),

      // ▼▼▼ CORREÇÃO AQUI ▼▼▼
      // O ExpansionTile deve ir DENTRO da propriedade 'child' do ClipRRect
      child: ExpansionTile( 
        // Título e subtítulo (visíveis quando fechado)
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(date, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
        
        // Cores para combinar com seu design
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: AppColors.surface,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        
        // Define se ele começa aberto
        initiallyExpanded: initiallyExpanded,
        
        // 'children' é o conteúdo que aparece quando expandido
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            description,
            style: const TextStyle(color: AppColors.secondaryText, height: 1.6),
          ),
          // Mostra o botão condicionalmente
          if (showButton) ...[
            const SizedBox(height: 20),
            // Reutilizamos o design do botão de gradiente da HomeScreen
            _buildGradientButton(),
          ]
        ],
      ), // <-- Parêntese do ExpansionTile
      // ▲▲▲ FIM DA CORREÇÃO ▲▲▲

    );
  }

  // Widget para o botão "Inscrever-se" (lógica do gradiente)
  Widget _buildGradientButton() {
    // Usamos 'Align' para o botão não esticar na largura toda
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [AppColors.accentOrange, AppColors.accent], // Gradiente
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: const Text(
            'Inscrever-se',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}