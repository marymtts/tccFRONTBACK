// lib/models/user.dart
class User {
  final int id;
  final String? ra; // Permite que 'ra' seja nulo (para admins)
  final String nome;
  final String email;
  final String role; // <-- ADICIONE ESTA LINHA

  User({
    required this.id, 
    this.ra, // Não é mais 'required'
    required this.nome, 
    required this.email, 
    required this.role // <-- ADICIONE ESTA LINHA
  });

  // Factory para criar um User a partir do JSON (do token)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      ra: json['ra'], // <-- Já estava OK (aceita nulo)
      nome: json['nome'],
      email: json['email'],
      role: json['role'] ?? 'aluno', // <-- ADICIONE ESTA LINHA
    );
  }
}