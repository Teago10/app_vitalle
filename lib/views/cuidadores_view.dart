import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CuidadoresView extends StatefulWidget {
  final String token;
  const CuidadoresView({super.key, required this.token});

  @override
  State<CuidadoresView> createState() => _CuidadoresViewState();
}

class _CuidadoresViewState extends State<CuidadoresView> {
  static const verdeEscuro = Color(0xFF07311C);
  static const verdeVitalle = Color(0xFF52745C);
  static const fundo = Color(0xFFFCF7F4);

  final TextEditingController buscaController = TextEditingController();
  List<Map<String, dynamic>> cuidadores = [];
  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
    buscaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final resposta = await ApiService.buscarCuidadores(widget.token);
      if (resposta['sucesso'] == false) {
        throw Exception(resposta['mensagem'] ?? 'Não foi possível buscar cuidadores.');
      }
      final lista = resposta['cuidadores'];
      if (lista is! List) throw Exception('Resposta inválida da API.');
      if (!mounted) return;
      setState(() {
        cuidadores = lista.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busca = buscaController.text.trim().toLowerCase();
    final filtrados = cuidadores.where((c) {
      final nome = (c['nome'] ?? '').toString().toLowerCase();
      final qualificacao = (c['qualificacao'] ?? '').toString().toLowerCase();
      return nome.contains(busca) || qualificacao.contains(busca);
    }).toList();

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Cuidadores', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: verdeVitalle,
        onRefresh: carregar,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Encontre quem cuida', style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.w800, color: verdeEscuro)),
            const SizedBox(height: 6),
            const Text('Conheça os cuidadores cadastrados no Vitalle.',
              style: TextStyle(color: verdeVitalle)),
            const SizedBox(height: 22),
            TextField(
              controller: buscaController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou qualificação',
                prefixIcon: const Icon(Icons.search, color: verdeVitalle),
                suffixIcon: buscaController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: buscaController.clear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDCE8DC))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDCE8DC))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: verdeVitalle, width: 2)),
              ),
            ),
            const SizedBox(height: 22),
            if (carregando)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator(color: verdeVitalle)),
              )
            else if (erro != null)
              _mensagem(Icons.error_outline, erro!, botao: true)
            else if (filtrados.isEmpty)
              _mensagem(Icons.person_search_outlined,
                busca.isEmpty ? 'Nenhum cuidador cadastrado.' : 'Nenhum cuidador encontrado.')
            else ...[
              Text('${filtrados.length} ${filtrados.length == 1 ? 'cuidador encontrado' : 'cuidadores encontrados'}',
                style: const TextStyle(color: verdeVitalle, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              for (final cuidador in filtrados) _cartao(cuidador),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mensagem(IconData icone, String texto, {bool botao = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icone, size: 48, color: verdeVitalle),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center,
            style: const TextStyle(color: verdeEscuro)),
          if (botao) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _cartao(Map<String, dynamic> cuidador) {
    final nome = (cuidador['nome'] ?? 'Cuidador').toString();
    final qualificacao = (cuidador['qualificacao'] ?? '').toString().trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: Color(0xFFE1EAE0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFFE6F4E5),
              child: Text(
                nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : 'C',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: verdeEscuro),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700, color: verdeEscuro)),
                const SizedBox(height: 7),
                Text(qualificacao.isEmpty ? 'Qualificação não informada' : qualificacao,
                  style: const TextStyle(fontSize: 14, color: verdeVitalle)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
