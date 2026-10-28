import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'cadastro_paciente_view.dart';

class PacientesView extends StatefulWidget {
  final String token;
  const PacientesView({super.key, required this.token});
  @override
  State<PacientesView> createState() => _PacientesViewState();
}

class _PacientesViewState extends State<PacientesView> {
  static const verdeEscuro = Color(0xFF07311C);
  static const verdeVitalle = Color(0xFF52745C);
  static const verde = verdeVitalle;
  static const verdeLimao = Color(0xFFBBF0B9);
  static const fundoCard = Color(0xFFFDF9F9);
  static const verdeClaro = Color(0xFFF8F2EE);
  static const fundo = Color(0xFFFCF7F4);
  static const textoSecundario = Color(0xFF6D786F);
  static const borda = Color(0xFFE8DED8);
  
  final pesquisaController = TextEditingController();
  List<Map<String, dynamic>> pacientes = [];
  bool carregando = true;
  int? excluindoId;
  int? expandidoId;
  String? erro;
  String pesquisa = '';

  @override
  void initState() {
    super.initState();
    carregarPacientes();
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  Future<void> carregarPacientes() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final resposta = await ApiService.buscarPacientes(widget.token);
      if (!mounted) return;
      setState(() {
        pacientes = List<Map<String, dynamic>>.from(
          resposta['pacientes'] ?? [],
        );
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = e.toString().replaceFirst('Exception: ', '');
        carregando = false;
      });
    }
  }

  List<Map<String, dynamic>> get pacientesFiltrados {
    final termo = pesquisa.trim().toLowerCase();
    if (termo.isEmpty) return pacientes;
    return pacientes
        .where(
          (p) =>
              texto(p['nome']).toLowerCase().contains(termo) ||
              texto(p['email']).toLowerCase().contains(termo),
        )
        .toList();
  }

  String texto(dynamic valor, {String vazio = 'Não informado'}) {
    final s = valor?.toString().trim() ?? '';
    return s.isEmpty ? vazio : s;
  }

  String formatarData(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return 'Não informada';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  int? calcularIdade(dynamic valor) {
    final nascimento = DateTime.tryParse(valor?.toString() ?? '');
    if (nascimento == null) return null;
    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day))
      idade--;
    return idade >= 0 ? idade : null;
  }

  String iniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'P';
    return (partes.length == 1
            ? partes.first[0]
            : '${partes.first[0]}${partes.last[0]}')
        .toUpperCase();
  }

  bool usaFraldas(Map<String, dynamic> p) =>
      p['usa_fraldas'] == true ||
      p['usa_fraldas'] == 1 ||
      p['usa_fraldas'] == '1';

  Future<void> abrirFormulario({Map<String, dynamic>? paciente}) async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CadastroPacienteView(token: widget.token, paciente: paciente),
      ),
    );
    if (atualizado == true && mounted) await carregarPacientes();
  }

  Future<void> excluirPaciente(Map<String, dynamic> paciente) async {
    final id = int.tryParse('${paciente['id']}');
    if (id == null || excluindoId != null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFC64D4D)),
            SizedBox(width: 10),
            Text('Excluir paciente'),
          ],
        ),
        content: Text(
          'Deseja excluir ${texto(paciente['nome'])}?\n\nEssa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC64D4D),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => excluindoId = id);
    try {
      await ApiService.excluirPaciente(widget.token, id);
      if (!mounted) return;
      setState(() => expandidoId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente excluído com sucesso!'),
          backgroundColor: verde,
        ),
      );
      await carregarPacientes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFC64D4D),
        ),
      );
    } finally {
      if (mounted) setState(() => excluindoId = null);
    }
  }

  Widget etiqueta(
    String titulo, {
    IconData? icone,
    Color cor = verde,
    Color fundoEtiqueta = verdeClaro,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fundoEtiqueta,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: cor),
            const SizedBox(width: 5),
          ],
          Text(
            titulo,
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget detalhe(String titulo, dynamic valor, {IconData? icone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icone, size: 18, color: textoSecundario),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto(valor),
                  style: const TextStyle(
                    color: verdeEscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget secaoDetalhes(String titulo, IconData icone, List<Widget> filhos) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 3),
      decoration: BoxDecoration(
        color: fundoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: verdeClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, size: 18, color: verde),
                ),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: verdeEscuro,
                  ),
                ),
              ],
            ),
          ),
          ...filhos,
        ],
      ),
    );
  }

  Widget cardPaciente(Map<String, dynamic> paciente) {
    final nome = texto(paciente['nome'], vazio: 'Paciente');
    final id = int.tryParse('${paciente['id']}');
    final expandido = id != null && expandidoId == id;
    final excluindo = id != null && excluindoId == id;
    final idade = calcularIdade(paciente['data_nascimento']);
    String responsavel = 'Não informado';
    if (paciente['responsavel'] is Map)
      responsavel = texto(paciente['responsavel']['nome']);
    final enderecoLinha1 = [
      paciente['rua'],
      paciente['numero'],
    ].where((v) => v != null && v.toString().trim().isNotEmpty).join(', ');
    final enderecoLinha2 = [
      paciente['bairro'],
      paciente['cidade'],
      paciente['estado'],
    ].where((v) => v != null && v.toString().trim().isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: expandido ? verde.withValues(alpha: .4) : borda,
        ),
        boxShadow: [
          BoxShadow(
            color: verdeEscuro.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => expandidoId = expandido ? null : id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: verdeClaro,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Center(
                        child: Text(
                          iniciais(nome),
                          style: const TextStyle(
                            color: verde,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: verdeEscuro,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (idade != null)
                                etiqueta(
                                  '$idade anos',
                                  icone: Icons.cake_outlined,
                                ),
                              etiqueta(
                                'Paciente',
                                icone: Icons.person_outline,
                                cor: textoSecundario,
                                fundoEtiqueta: const Color(0xFFF8F2EE),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expandido ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: verde,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expandido
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: borda, height: 22),
                        secaoDetalhes('Dados pessoais', Icons.badge_outlined, [
                          detalhe(
                            'Data de nascimento',
                            formatarData(paciente['data_nascimento']),
                            icone: Icons.calendar_today_outlined,
                          ),
                          detalhe(
                            'E-mail',
                            paciente['email'],
                            icone: Icons.mail_outline,
                          ),
                          detalhe(
                            'Responsável',
                            responsavel,
                            icone: Icons.supervisor_account_outlined,
                          ),
                        ]),
                        secaoDetalhes(
                          'Informações de saúde',
                          Icons.favorite_border,
                          [
                            detalhe(
                              'Comorbidades',
                              paciente['comorbidade'],
                              icone: Icons.medical_information_outlined,
                            ),
                            detalhe(
                              'Condição física',
                              paciente['condicao_fisica'],
                              icone: Icons.accessibility_new_outlined,
                            ),
                            detalhe(
                              'Medicação',
                              paciente['medicacao'],
                              icone: Icons.medication_outlined,
                            ),
                            detalhe(
                              'Horário da medicação',
                              paciente['horario_medicacao'],
                              icone: Icons.schedule_outlined,
                            ),
                            detalhe(
                              'Uso de fraldas',
                              usaFraldas(paciente) ? 'Sim' : 'Não',
                              icone: Icons.check_circle_outline,
                            ),
                          ],
                        ),
                        secaoDetalhes('Endereço', Icons.location_on_outlined, [
                          detalhe(
                            'Rua e número',
                            enderecoLinha1,
                            icone: Icons.home_outlined,
                          ),
                          detalhe(
                            'Bairro, cidade e estado',
                            enderecoLinha2,
                            icone: Icons.map_outlined,
                          ),
                          if (texto(
                            paciente['complemento'],
                            vazio: '',
                          ).isNotEmpty)
                            detalhe(
                              'Complemento',
                              paciente['complemento'],
                              icone: Icons.apartment_outlined,
                            ),
                          detalhe(
                            'CEP',
                            paciente['cep'],
                            icone: Icons.pin_drop_outlined,
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: FilledButton.icon(
                                  onPressed: excluindo
                                      ? null
                                      : () =>
                                            abrirFormulario(paciente: paciente),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: verde,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: excluindo
                                      ? null
                                      : () => excluirPaciente(paciente),
                                  icon: excluindo
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                  label: Text(
                                    excluindo ? 'Excluindo' : 'Excluir',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC64D4D),
                                    side: const BorderSide(
                                      color: Color(0xFFF0CCCC),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget cabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 25),
      decoration: const BoxDecoration(
        color: verdeClaro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GERENCIAMENTO',
            style: TextStyle(
              color: verde,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Meus pacientes',
            style: TextStyle(
              color: verdeEscuro,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Organize e acompanhe os dados de quem você cuida.',
            style: TextStyle(
              color: Color(0xFF52745C),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: pesquisaController,
            onChanged: (valor) => setState(() => pesquisa = valor),
            decoration: InputDecoration(
              hintText: 'Buscar paciente...',
              hintStyle: const TextStyle(color: textoSecundario, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: verde),
              suffixIcon: pesquisa.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        pesquisaController.clear();
                        setState(() => pesquisa = '');
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget estadoVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: verdeClaro,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 38,
                color: verde,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              pesquisa.isEmpty
                  ? 'Nenhum paciente cadastrado'
                  : 'Nenhum resultado encontrado',
              style: const TextStyle(
                color: verdeEscuro,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pesquisa.isEmpty
                  ? 'Cadastre seu primeiro paciente para começar.'
                  : 'Tente pesquisar por outro nome ou e-mail.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: verdeEscuro,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: fundo,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: fundo,
        appBar: AppBar(
          backgroundColor: verdeEscuro,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Pacientes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: carregando ? null : carregarPacientes,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => abrirFormulario(),
          backgroundColor: verde,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Novo paciente',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: carregando
            ? const Center(child: CircularProgressIndicator(color: verde))
            : erro != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 44,
                        color: Color(0xFFC64D4D),
                      ),
                      const SizedBox(height: 14),
                      Text(erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: carregarPacientes,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: verde,
                onRefresh: carregarPacientes,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: cabecalho()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Pacientes cadastrados',
                                  style: TextStyle(
                                    color: verdeEscuro,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              etiqueta('${pacientesFiltrados.length} total'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (pacientesFiltrados.isEmpty)
                            estadoVazio()
                          else
                            ...pacientesFiltrados.map(cardPaciente),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
