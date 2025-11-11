// lib/models/user.dart
class User {
  final int id;     // <-- CORRIGIDO para int
  final String? ra;   // <-- CORRIGIDO para String? (Vamos tratar no fromJson)
  final String nome;
  final String email;
  final String role; 

  User({
    required this.id, 
    this.ra, 
    required this.nome, 
    required this.email, 
    required this.role
  });

  // Factory para criar um User a partir do JSON (do token)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int, // <-- CORRIGIDO: Diz ao Dart que 'id' é um int
      
      // Converte 'ra' (que vem como int 202174) para String
      ra: json['ra']?.toString(), // <-- CORRIGIDO: Converte o número para String
      
      nome: json['nome'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'aluno', // Pega o 'role' ou usa 'aluno'
    );
  }
}