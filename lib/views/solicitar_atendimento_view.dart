
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SolicitarAtendimentoView extends StatefulWidget {
  final String token;

  const SolicitarAtendimentoView({
    super.key,
    required this.token,
  });

  @override
  State<SolicitarAtendimentoView> createState() =>
      _SolicitarAtendimentoViewState();
}

class _SolicitarAtendimentoViewState
    extends State<SolicitarAtendimentoView> {
  static const verdeEscuro = Color(0xFF07311C);
  static const verdeVitalle = Color(0xFF52745C);
  static const verdeLimao = Color(0xFFBBF0B9);
  static const fundoCard = Color(0xFFFDF9F9);
  static const fundo = Color(0xFFFCF7F4);
  static const textoSecundario = Color(0xFF6D786F);
  static const borda = Color(0xFFE8DED8);

  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _cuidadores = [];

  int? _pacienteSelecionado;
  int? _cuidadorSelecionado;

  DateTime? _dataSelecionada;
  TimeOfDay? _inicioSelecionado;
  TimeOfDay? _fimSelecionado;

  String? _jornadaSelecionada;

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarOpcoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait([
        ApiService.buscarPacientes(widget.token),
        ApiService.buscarCuidadores(widget.token),
      ]);

      List<Map<String, dynamic>> extrairLista(
        Map<String, dynamic> resposta,
        String chave,
      ) {
        final lista = resposta[chave];

        if (lista is List) {
          return lista
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        return [];
      }

      final pacientes = extrairLista(resultados[0], 'pacientes');
      final cuidadores = extrairLista(resultados[1], 'cuidadores');

      if (!mounted) return;

      setState(() {
        _pacientes = pacientes;
        _cuidadores = cuidadores;
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

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? agora,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(agora.year + 5),
      helpText: 'Selecione a data do atendimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: verdeVitalle,
              onPrimary: Colors.white,
              surface: fundoCard,
              onSurface: verdeEscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null && mounted) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHora({required bool inicio}) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: inicio
          ? (_inicioSelecionado ?? const TimeOfDay(hour: 8, minute: 0))
          : (_fimSelecionado ?? const TimeOfDay(hour: 20, minute: 0)),
      helpText: inicio
          ? 'Horário de início'
          : 'Horário de término',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: verdeVitalle,
              onPrimary: Colors.white,
              surface: fundoCard,
              onSurface: verdeEscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null && mounted) {
      setState(() {
        if (inicio) {
          _inicioSelecionado = hora;
        } else {
          _fimSelecionado = hora;
        }
      });
    }
  }

  Future<void> _solicitarAtendimento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataSelecionada == null ||
        _inicioSelecionado == null ||
        _fimSelecionado == null) {
      _mensagem('Selecione a data e os horários do atendimento.');
      return;
    }

    if (_jornadaSelecionada == null) {
      _mensagem('Selecione o tipo de jornada.');
      return;
    }

    final minutosInicio =
        _inicioSelecionado!.hour * 60 + _inicioSelecionado!.minute;

    final minutosFim =
        _fimSelecionado!.hour * 60 + _fimSelecionado!.minute;

    if (minutosInicio == minutosFim) {
      _mensagem('O horário de início e término não pode ser igual.');
      return;
    }

    final data = _dataSelecionada!;
    final dataFormatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';

    final valorTexto = _valorController.text
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final valor = double.tryParse(valorTexto);

    if (valor == null || valor < 0) {
      _mensagem('Informe um valor válido.');
      return;
    }

    setState(() => _salvando = true);

    try {
      await ApiService.salvarAtendimento(
        widget.token,
        {
          'id_paciente': _pacienteSelecionado,
          'id_cuidador': _cuidadorSelecionado,
          'data_atendimento': dataFormatada,
          'horario_inicio': _formatarHora(_inicioSelecionado!),
          'horario_fim': _formatarHora(_fimSelecionado!),
          'tipo_jornada': _jornadaSelecionada,
          'valor': valor,
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _mensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: verdeEscuro,
      ),
    );
  }

  Widget _tituloSecao(String titulo, String descricao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: verdeEscuro,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: const TextStyle(
              color: textoSecundario,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required String titulo,
    required Widget filho,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: verdeEscuro,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        filho,
      ],
    );
  }

  InputDecoration _decoracao(
    String dica, {
    IconData? icone,
  }) {
    return InputDecoration(
      hintText: dica,
      prefixIcon: icone == null
          ? null
          : Icon(icone, color: verdeVitalle, size: 21),
      filled: true,
      fillColor: fundo,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: verdeVitalle,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _campoData() {
    return InkWell(
      onTap: _selecionarData,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: _decoracao(
          'Selecione a data',
          icone: Icons.calendar_month_outlined,
        ),
        child: Text(
          _dataSelecionada == null
              ? 'Escolher data'
              : _formatarData(_dataSelecionada!),
          style: TextStyle(
            color: _dataSelecionada == null
                ? textoSecundario
                : verdeEscuro,
          ),
        ),
      ),
    );
  }

  Widget _campoHora({required bool inicio}) {
    final hora = inicio ? _inicioSelecionado : _fimSelecionado;

    return InkWell(
      onTap: () => _selecionarHora(inicio: inicio),
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: _decoracao(
          inicio ? 'Horário inicial' : 'Horário final',
          icone: Icons.schedule_rounded,
        ),
        child: Text(
          hora == null ? '--:--' : _formatarHora(hora),
          style: TextStyle(
            color: hora == null ? textoSecundario : verdeEscuro,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
        title: const Text(
          'Solicitar atendimento',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: verdeVitalle),
            )
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 45,
                          color: verdeVitalle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: verdeEscuro),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _carregarOpcoes,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pacientes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline_rounded,
                              size: 45,
                              color: verdeVitalle,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Nenhum paciente disponível',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: verdeEscuro,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cadastre um paciente antes de solicitar um atendimento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textoSecundario),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _carregarOpcoes,
                              child: const Text('Atualizar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(19),
                            decoration: BoxDecoration(
                              color: verdeEscuro,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: verdeLimao,
                                  size: 34,
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vamos organizar seu atendimento',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Preencha os dados abaixo para registrar a solicitação.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          _tituloSecao(
                            '1. Quem precisa de cuidado?',
                            'Selecione o paciente e, se desejar, um cuidador.',
                          ),
                          _campo(
                            titulo: 'Paciente *',
                            filho: DropdownButtonFormField<int>(
                              value: _pacienteSelecionado,
                              isExpanded: true,
                              decoration: _decoracao(
                                'Selecione o paciente',
                                icone: Icons.person_outline_rounded,
                              ),
                              items: _pacientes.map((paciente) {
                                final id = int.tryParse(
                                  paciente['id']?.toString() ?? '',
                                );

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(
                                    paciente['nome']?.toString() ??
                                        'Paciente sem nome',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).where((item) => item.value != null).toList(),
                              validator: (valor) => valor == null
                                  ? 'Selecione um paciente.'
                                  : null,
                              onChanged: (valor) {
                                setState(() => _pacienteSelecionado = valor);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _campo(
                            titulo: 'Cuidador (opcional)',
                            filho: DropdownButtonFormField<int?>(
                              value: _cuidadorSelecionado,
                              isExpanded: true,
                              decoration: _decoracao(
                                'Definir depois',
                                icone: Icons.health_and_safety_outlined,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Sem cuidador definido'),
                                ),
                                ..._cuidadores.map((cuidador) {
                                  final id = int.tryParse(
                                    cuidador['id']?.toString() ?? '',
                                  );

                                  return DropdownMenuItem<int?>(
                                    value: id,
                                    child: Text(
                                      cuidador['nome']?.toString() ??
                                          'Cuidador sem nome',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).where((item) => item.value != null ||
                                    item.child is Text),
                              ],
                              onChanged: (valor) {
                                setState(() => _cuidadorSelecionado = valor);
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                          _tituloSecao(
                            '2. Quando será?',
                            'Informe a data e o período de atendimento.',
                          ),
                          _campo(
                            titulo: 'Data do atendimento *',
                            filho: _campoData(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _campo(
                                  titulo: 'Início *',
                                  filho: _campoHora(inicio: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _campo(
                                  titulo: 'Término *',
                                  filho: _campoHora(inicio: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          _tituloSecao(
                            '3. Tipo de atendimento',
                            'Escolha a jornada desejada.',
                          ),
                          _campo(
                            titulo: 'Jornada *',
                            filho: DropdownButtonFormField<String>(
                              value: _jornadaSelecionada,
                              isExpanded: true,
                              decoration: _decoracao(
                                'Selecione a jornada',
                                icone: Icons.access_time_rounded,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '12h_dia',
                                  child: Text('12 horas - Dia'),
                                ),
                                DropdownMenuItem(
                                  value: '12h_noite',
                                  child: Text('12 horas - Noite'),
                                ),
                                DropdownMenuItem(
                                  value: '6h',
                                  child: Text('6 horas'),
                                ),
                                DropdownMenuItem(
                                  value: 'cuidado_avulso',
                                  child: Text('Cuidado avulso'),
                                ),
                              ],
                              validator: (valor) => valor == null
                                  ? 'Selecione o tipo de jornada.'
                                  : null,
                              onChanged: (valor) {
                                setState(() => _jornadaSelecionada = valor);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _campo(
                            titulo: 'Valor do atendimento (R\$) *',
                            filho: TextFormField(
                              controller: _valorController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _decoracao(
                                'Ex.: 180,00',
                                icone: Icons.payments_outlined,
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Informe o valor.';
                                }

                                final texto = valor
                                    .replaceAll('R\$', '')
                                    .replaceAll(' ', '')
                                    .replaceAll('.', '')
                                    .replaceAll(',', '.');

                                final numero = double.tryParse(texto);

                                if (numero == null || numero < 0) {
                                  return 'Informe um valor válido.';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: verdeLimao.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borda,
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: verdeEscuro,
                                  size: 21,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'A solicitação será registrada como aberta. O atendimento poderá ser acompanhado na tela de Atendimentos.',
                                    style: TextStyle(
                                      color: verdeEscuro,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _salvando
                                  ? null
                                  : _solicitarAtendimento,
                              style: FilledButton.styleFrom(
                                backgroundColor: verdeVitalle,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: _salvando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _salvando
                                    ? 'Enviando solicitação...'
                                    : 'Solicitar atendimento',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _salvando
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: verdeEscuro,
                                side: const BorderSide(color: borda),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text('Voltar'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}
