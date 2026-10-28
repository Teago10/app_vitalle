import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'solicitar_atendimento_view.dart';

class AtendimentosView extends StatefulWidget {
  final String token;

  const AtendimentosView({super.key, required this.token});

  @override
  State<AtendimentosView> createState() => _AtendimentosViewState();
}

class _AtendimentosViewState extends State<AtendimentosView> {
  static const verdeEscuro = Color(0xFF07311C);
  static const verdeVitalle = Color(0xFF52745C);
  static const verdeLimao = Color(0xFFBBF0B9);
  static const fundoCard = Color(0xFFFDF9F9);
  static const fundo = Color(0xFFFCF7F4);
  static const textoSecundario = Color(0xFF6D786F);
  static const borda = Color(0xFFE8DED8);

  final TextEditingController _pesquisaController = TextEditingController();

  List<Map<String, dynamic>> _atendimentos = [];
  bool _carregando = true;
  String _filtroStatus = 'TODOS';
  String _pesquisa = '';
  String? _erro;

  @override
  void initState() {
    super.initState();
    carregarAtendimentos();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> carregarAtendimentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.buscarAtendimentos(widget.token);

      final lista = resposta['atendimentos'];

      if (lista is! List) {
        throw Exception('A API retornou uma lista inválida.');
      }

      if (!mounted) return;

      setState(() {
        _atendimentos = lista
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _listaFiltrada {
    return _atendimentos.where((atendimento) {
      final status = atendimento['status']?.toString().toUpperCase() ?? '';

      final paciente = _nomeRelacionado(atendimento['paciente']);
      final cuidador = _nomeRelacionado(atendimento['cuidador']);

      final correspondePesquisa =
          '$paciente $cuidador ${atendimento['tipo_jornada'] ?? ''}'
              .toLowerCase()
              .contains(_pesquisa.toLowerCase());

      final correspondeStatus =
          _filtroStatus == 'TODOS' || status == _filtroStatus;

      return correspondePesquisa && correspondeStatus;
    }).toList();
  }

  String _nomeRelacionado(dynamic relacionado) {
    if (relacionado is Map) {
      return relacionado['nome']?.toString() ?? 'Não informado';
    }

    return 'Não informado';
  }

  String _data(String? valor) {
    if (valor == null || valor.isEmpty) return 'Data não informada';

    final partes = valor.split('-');

    if (partes.length == 3) {
      return '${partes[2].split('T').first}/${partes[1]}/${partes[0]}';
    }

    return valor;
  }

  String _hora(String? valor) {
    if (valor == null || valor.isEmpty) return '--:--';
    return valor.length >= 5 ? valor.substring(0, 5) : valor;
  }

  String _jornada(String? valor) {
    switch (valor) {
      case '12h_dia':
        return '12 horas - Dia';
      case '12h_noite':
        return '12 horas - Noite';
      case '6h':
        return '6 horas';
      case 'cuidado_avulso':
        return 'Cuidado avulso';
      default:
        return valor ?? 'Não informado';
    }
  }

  String _statusLegivel(String? status) {
    switch (status?.toUpperCase()) {
      case 'ABERTO':
        return 'Aberto';
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status ?? 'Não informado';
    }
  }

  Color _corStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ABERTO':
        return const Color(0xFF52745C);
      case 'EM_ANDAMENTO':
        return const Color(0xFF8A681B);
      case 'CONCLUIDO':
        return const Color(0xFF2E6D45);
      case 'CANCELADO':
        return const Color(0xFFAC4A42);
      default:
        return textoSecundario;
    }
  }

  String _valor(dynamic valor) {
    final numero = double.tryParse(valor?.toString() ?? '');

    if (numero == null) return 'Não informado';

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _executarAcao(
    Map<String, dynamic> atendimento,
    String acao,
  ) async {
    final id = int.tryParse(atendimento['id']?.toString() ?? '');

    if (id == null) {
      _mensagem('Não foi possível identificar o atendimento.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: fundoCard,
        title: const Text('Confirmar ação'),
        content: Text(
          'Deseja realmente ${acao == 'cancelar'
              ? 'cancelar'
              : acao == 'iniciar'
              ? 'iniciar'
              : 'concluir'} este atendimento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: verdeVitalle),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await ApiService.atualizarStatusAtendimento(widget.token, id, acao);

      if (!mounted) return;

      _mensagem('Atendimento atualizado com sucesso.');
      await carregarAtendimentos();
    } catch (e) {
      if (!mounted) return;

      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: verdeEscuro),
    );
  }

  Widget _filtro(String valor, String titulo) {
    final selecionado = _filtroStatus == valor;

    return ChoiceChip(
      label: Text(titulo),
      selected: selecionado,
      onSelected: (_) {
        setState(() => _filtroStatus = valor);
      },
      selectedColor: verdeLimao,
      backgroundColor: fundoCard,
      side: BorderSide(color: selecionado ? verdeVitalle : borda),
      labelStyle: TextStyle(
        color: verdeEscuro,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
      ),
      showCheckmark: false,
    );
  }

  Widget _cartaoAtendimento(Map<String, dynamic> atendimento) {
    final status = atendimento['status']?.toString().toUpperCase() ?? '';

    final paciente = _nomeRelacionado(atendimento['paciente']);
    final cuidador = _nomeRelacionado(atendimento['cuidador']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: fundoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: verdeLimao.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: verdeEscuro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: verdeEscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _data(atendimento['data_atendimento']?.toString()),
                      style: const TextStyle(
                        color: textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _corStatus(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLegivel(status),
                  style: TextStyle(
                    color: _corStatus(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(color: borda, height: 1),
          const SizedBox(height: 14),
          _linhaInfo(Icons.person_outline_rounded, 'Cuidador', cuidador),
          const SizedBox(height: 10),
          _linhaInfo(
            Icons.schedule_rounded,
            'Horário',
            '${_hora(atendimento['horario_inicio']?.toString())} às ${_hora(atendimento['horario_fim']?.toString())}',
          ),
          const SizedBox(height: 10),
          _linhaInfo(
            Icons.access_time_rounded,
            'Jornada',
            _jornada(atendimento['tipo_jornada']?.toString()),
          ),
          const SizedBox(height: 10),
          _linhaInfo(
            Icons.payments_outlined,
            'Valor',
            _valor(atendimento['valor']),
          ),
          if (status == 'ABERTO' || status == 'EM_ANDAMENTO') ...[
            const SizedBox(height: 16),
            const Divider(color: borda, height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'ABERTO')
                  OutlinedButton.icon(
                    onPressed: () => _executarAcao(atendimento, 'cancelar'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAC4A42),
                      side: const BorderSide(color: Color(0xFFDFC2BE)),
                    ),
                  ),
                if (status == 'ABERTO')
                  FilledButton.icon(
                    onPressed: () => _executarAcao(atendimento, 'iniciar'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Iniciar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: verdeVitalle,
                    ),
                  ),
                if (status == 'EM_ANDAMENTO')
                  FilledButton.icon(
                    onPressed: () => _executarAcao(atendimento, 'concluir'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Concluir'),
                    style: FilledButton.styleFrom(backgroundColor: verdeEscuro),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String titulo, String valor) {
    return Row(
      children: [
        Icon(icone, size: 19, color: verdeVitalle),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            titulo,
            style: const TextStyle(color: textoSecundario, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: verdeEscuro,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final abertos = _atendimentos.where((a) => a['status'] == 'ABERTO').length;

    final andamento = _atendimentos
        .where((a) => a['status'] == 'EM_ANDAMENTO')
        .length;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
        title: const Text(
          'Atendimentos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: carregarAtendimentos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      // Botão de Solicitação de atendimento
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => SolicitarAtendimentoView(token: widget.token),
            ),
          );

          if (resultado == true && mounted) {
            await carregarAtendimentos();
          }
        },
        backgroundColor: verdeVitalle,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Solicitar atendimento',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: carregarAtendimentos,
        color: verdeVitalle,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Acompanhamento',
              style: TextStyle(
                color: verdeEscuro,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Consulte e acompanhe os atendimentos.',
              style: TextStyle(color: textoSecundario, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _resumo(
                    'Total',
                    _atendimentos.length.toString(),
                    Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _resumo(
                    'Abertos',
                    abertos.toString(),
                    Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _resumo(
                    'Em andamento',
                    andamento.toString(),
                    Icons.play_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pesquisaController,
              onChanged: (valor) {
                setState(() => _pesquisa = valor.trim());
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar paciente ou cuidador',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: verdeVitalle,
                ),
                filled: true,
                fillColor: fundoCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: borda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: borda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: verdeVitalle, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filtro('TODOS', 'Todos'),
                  const SizedBox(width: 8),
                  _filtro('ABERTO', 'Abertos'),
                  const SizedBox(width: 8),
                  _filtro('EM_ANDAMENTO', 'Em andamento'),
                  const SizedBox(width: 8),
                  _filtro('CONCLUIDO', 'Concluídos'),
                  const SizedBox(width: 8),
                  _filtro('CANCELADO', 'Cancelados'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: verdeVitalle),
                ),
              )
            else if (_erro != null)
              _estadoVazio(
                Icons.cloud_off_outlined,
                'Não foi possível carregar',
                _erro!,
                mostrarBotao: true,
              )
            else if (_listaFiltrada.isEmpty)
              _estadoVazio(
                Icons.calendar_today_outlined,
                'Nenhum atendimento encontrado',
                'Tente mudar os filtros ou atualizar a lista.',
              )
            else
              ..._listaFiltrada.map(_cartaoAtendimento),
          ],
        ),
      ),
    );
  }

  Widget _resumo(String titulo, String valor, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: fundoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        children: [
          Icon(icone, color: verdeVitalle, size: 22),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: verdeEscuro,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textoSecundario, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _estadoVazio(
    IconData icone,
    String titulo,
    String descricao, {
    bool mostrarBotao = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          Icon(icone, size: 48, color: verdeVitalle),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: verdeEscuro,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textoSecundario, fontSize: 13),
          ),
          if (mostrarBotao) ...[
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: carregarAtendimentos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}
