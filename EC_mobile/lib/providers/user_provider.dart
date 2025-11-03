// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:ec_mobile/models/user.dart'; // Importa o molde
import 'package:jwt_decoder/jwt_decoder.dart'; // Importa o decodificador

class UserProvider extends ChangeNotifier {
  User? _user; // Variável privada para guardar o usuário logado

  User? get user => _user; // Getter para ler o usuário

  // Função para definir o usuário (ex: após o login)
  void setUser(User user) {
    _user = user;
    notifyListeners(); // Avisa a todos
  }

  // Função para definir o usuário a partir do token salvo
  void setUserFromToken(String token) {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // O seu PHP (login.php) salva os dados dentro de uma chave "data"
      Map<String, dynamic> userData = decodedToken['data'];

      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      print("Erro ao decodificar token: $e");
      _user = null;
      notifyListeners();
    }
  }

  // Função para deslogar
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}