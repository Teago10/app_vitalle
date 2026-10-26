import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  
static Future<Map<String, dynamic>> buscarCuidadores(
  String token,
) async {
  final resposta = await http.get(
    Uri.parse('$baseUrl/cuidadores'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

  if (resposta.statusCode == 200) {
    return dados;
  }

  throw Exception(
    dados['mensagem'] ?? 'Erro ao carregar cuidadores.',
  );
}

static Future<void> excluirAvaliacao(
  String token,
  int id,
) async {
  final resposta = await http.delete(
    Uri.parse('$baseUrl/avaliacoes/$id'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (resposta.statusCode == 200) {
    return;
  }

  final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

  throw Exception(
    dados['mensagem'] ?? 'Erro ao excluir avaliação.',
  );
}


  
static Future<Map<String, dynamic>> buscarAvaliacoes(String token) async {
  final resposta = await http.get(
    Uri.parse('$baseUrl/avaliacoes'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

  if (resposta.statusCode == 200) {
    return dados;
  }

  if (resposta.statusCode == 401) {
    throw Exception('Sua sessão expirou. Faça login novamente.');
  }

  throw Exception(
    dados['mensagem'] ?? 'Não foi possível carregar as avaliações.',
  );
}

  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<Map<String, dynamic>> testarConexao() async {
    final url = Uri.parse('$baseUrl/teste');

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      return jsonDecode(resposta.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Erro ao conectar com a API: ${resposta.statusCode}',
      );
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String senha,
  ) async {
    final url = Uri.parse('$baseUrl/login');

    final resposta = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': senha,
      }),
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    } else {
      throw Exception(
        dados['mensagem'] ?? 'Não foi possível realizar o login.',
      );
    }
  }
}
