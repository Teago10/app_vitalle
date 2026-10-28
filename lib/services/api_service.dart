import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');

    if (cepLimpo.length != 8) {
      throw Exception('O CEP deve conter 8 números.');
    }

    try {
      final resposta = await http
          .get(
            Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) {
        throw Exception('Não foi possível consultar o CEP.');
      }

      final dados = jsonDecode(resposta.body);

      if (dados is! Map<String, dynamic>) {
        throw Exception('Resposta inválida do serviço de CEP.');
      }

      if (dados['erro'] == true) {
        throw Exception('CEP não encontrado.');
      }

      return dados;
    } on TimeoutException {
      throw Exception('A consulta demorou muito. Tente novamente.');
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on FormatException {
      throw Exception('Resposta inválida do serviço de CEP.');
    }
  }

  static Future<Map<String, dynamic>> buscarPacientes(String token) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/pacientes'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    }

    if (resposta.statusCode == 401) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (resposta.statusCode == 403) {
      throw Exception(
        dados['mensagem'] ??
            'Você não tem permissão para visualizar pacientes.',
      );
    }

    throw Exception(dados['mensagem'] ?? 'Erro ao carregar pacientes.');
  }

  static Future<Map<String, dynamic>> buscarCuidadores(String token) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/cuidadores'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    }

    throw Exception(dados['mensagem'] ?? 'Erro ao carregar cuidadores.');
  }

  static Future<void> excluirAvaliacao(String token, int id) async {
    final resposta = await http.delete(
      Uri.parse('$baseUrl/avaliacoes/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resposta.statusCode == 200) {
      return;
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    throw Exception(dados['mensagem'] ?? 'Erro ao excluir avaliação.');
  }

  static Future<Map<String, dynamic>> buscarAvaliacoes(String token) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/avaliacoes'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
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
      throw Exception('Erro ao conectar com a API: ${resposta.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/login');

    final resposta = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': senha}),
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

  static Future<Map<String, dynamic>> cadastrarPaciente(
    String token,
    Map<String, dynamic> dadosPaciente,
  ) async {
    try {
      final resposta = await http.post(
        Uri.parse('$baseUrl/pacientes'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dadosPaciente),
      );

      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

      if (resposta.statusCode == 201) {
        return dados;
      }

      if (resposta.statusCode == 422) {
        final erros = dados['errors'];

        if (erros is Map && erros.isNotEmpty) {
          final primeiroErro = erros.values.first;

          if (primeiroErro is List && primeiroErro.isNotEmpty) {
            throw Exception(primeiroErro.first.toString());
          }
        }

        throw Exception(dados['message'] ?? 'Verifique os dados informados.');
      }

      if (resposta.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      if (resposta.statusCode == 403) {
        throw Exception(
          dados['mensagem'] ??
              'Você não tem permissão para cadastrar pacientes.',
        );
      }

      throw Exception(
        dados['mensagem'] ??
            dados['message'] ??
            'Não foi possível cadastrar o paciente.',
      );
    } catch (e) {
      if (e is FormatException) {
        throw Exception('O servidor retornou uma resposta inválida.');
      }

      rethrow;
    }
  }

  static Future<Map<String, dynamic>> editarPaciente(
    String token,
    int id,
    Map<String, dynamic> dadosPaciente,
  ) async {
    final resposta = await http.put(
      Uri.parse('$baseUrl/pacientes/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dadosPaciente),
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    }

    if (resposta.statusCode == 422) {
      final erros = dados['errors'];

      if (erros is Map && erros.isNotEmpty) {
        final primeiroErro = erros.values.first;

        if (primeiroErro is List && primeiroErro.isNotEmpty) {
          throw Exception(primeiroErro.first.toString());
        }
      }
    }

    throw Exception(
      dados['mensagem'] ??
          dados['message'] ??
          'Não foi possível atualizar o paciente.',
    );
  }

  static Future<Map<String, dynamic>> excluirPaciente(
    String token,
    int id,
  ) async {
    final resposta = await http.delete(
      Uri.parse('$baseUrl/pacientes/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    }

    throw Exception(
      dados['mensagem'] ??
          dados['message'] ??
          'Não foi possível excluir o paciente.',
    );
  }

  static Future<Map<String, dynamic>> buscarAtendimentos(String token) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/atendimentos'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    }

    if (resposta.statusCode == 401) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    throw Exception(
      dados['mensagem'] ??
          dados['message'] ??
          'Não foi possível carregar os atendimentos.',
    );
  }

  static Future<Map<String, dynamic>> salvarAtendimento(
    String token,
    Map<String, dynamic> dadosAtendimento, {
    int? id,
  }) async {
    final uri = Uri.parse(
      id == null ? '$baseUrl/atendimentos' : '$baseUrl/atendimentos/$id',
    );

    final resposta = id == null
        ? await http.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(dadosAtendimento),
          )
        : await http.put(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(dadosAtendimento),
          );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200 || resposta.statusCode == 201) {
      return dados;
    }

    if (resposta.statusCode == 422) {
      final erros = dados['errors'];

      if (erros is Map && erros.isNotEmpty) {
        final primeiroErro = erros.values.first;

        if (primeiroErro is List && primeiroErro.isNotEmpty) {
          throw Exception(primeiroErro.first.toString());
        }
      }
    }

    throw Exception(
      dados['mensagem'] ??
          dados['message'] ??
          'Não foi possível salvar o atendimento.',
    );
  }

  static Future<void> atualizarStatusAtendimento(
    String token,
    int id,
    String acao,
  ) async {
    const acoesPermitidas = {'cancelar', 'iniciar', 'concluir'};

    if (!acoesPermitidas.contains(acao)) {
      throw Exception('Ação de atendimento inválida.');
    }

    final resposta = await http.patch(
      Uri.parse('$baseUrl/atendimentos/$id/$acao'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (resposta.statusCode == 200) {
      return;
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    throw Exception(
      dados['mensagem'] ??
          dados['message'] ??
          'Não foi possível atualizar o atendimento.',
    );
  }
}
