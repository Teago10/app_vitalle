
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AvaliacoesView extends StatefulWidget {
  final String token;

  const AvaliacoesView({
    super.key,
    required this.token,
  });

  @override
  State<AvaliacoesView> createState() => _AvaliacoesViewState();
}

class _AvaliacoesViewState extends State<AvaliacoesView> {
  static const Color verdeEscuro = Color(0xFF07311C);
  static const Color verdeVitalle = Color(0xFF52745C);
  static const Color verdeLimao = Color(0xFFBBF0B9);
  static const Color fundo = Color(0xFFF8F2EE);

  final TextEditingController pesquisaController = TextEditingController();

  List<Map<String, dynamic>> avaliacoes = [];
  List<Map<String, dynamic>> cuidadores = [];

  String textoPesquisa = '';
  String filtroEstrelas = 'Todas';
  int? cuidadorSelecionado;

  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await Future.wait([
        ApiService.buscarAvaliacoes(widget.token),
        ApiService.buscarCuidadores(widget.token),
      ]);

      if (!mounted) return;

      setState(() {
        avaliacoes = List<Map<String, dynamic>>.from(
          resultado[0]['avaliacoes'] ?? [],
        );

        cuidadores = List<Map<String, dynamic>>.from(
          resultado[1]['cuidadores'] ?? [],
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

  List<Map<String, dynamic>> get avaliacoesFiltradas {
    return avaliacoes.where((avaliacao) {
      final nome = (avaliacao['nome_cuidador'] ?? '')
          .toString()
          .toLowerCase();

      final comentario = (avaliacao['comentario'] ?? '')
          .toString()
          .toLowerCase();

      final pesquisa = textoPesquisa.toLowerCase();

      final correspondePesquisa =
          nome.contains(pesquisa) || comentario.contains(pesquisa);

      final correspondeCuidador = cuidadorSelecionado == null ||
          (avaliacao['id_cuidador'] as num?)?.toInt() ==
              cuidadorSelecionado;

      final nota = (avaliacao['nota'] as num?)?.toDouble() ?? 0;

      final correspondeEstrelas = filtroEstrelas == 'Todas' ||
          nota.floor() == int.parse(filtroEstrelas);

      return correspondePesquisa &&
          correspondeCuidador &&
          correspondeEstrelas;
    }).toList();
  }

  double get mediaGeral {
    if (avaliacoes.isEmpty) return 0;

    final soma = avaliacoes.fold<double>(
      0,
      (total, avaliacao) =>
          total + ((avaliacao['nota'] as num?)?.toDouble() ?? 0),
    );

    return soma / avaliacoes.length;
  }

  Widget construirEstrelas(double nota) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final diferenca = nota - index;

        IconData icone;

        if (diferenca >= 1) {
          icone = Icons.star_rounded;
        } else if (diferenca >= 0.5) {
          icone = Icons.star_half_rounded;
        } else {
          icone = Icons.star_border_rounded;
        }

        return Icon(
          icone,
          color: const Color(0xFFE8AC35),
          size: 21,
        );
      }),
    );
  }

  Widget cardResumo({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: verdeVitalle.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Icon(icone, color: verdeVitalle, size: 25),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                color: verdeEscuro,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: verdeVitalle,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmarExclusao(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: const Text(
          'Tem certeza de que deseja excluir sua avaliação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await ApiService.excluirAvaliacao(widget.token, id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação excluída com sucesso!'),
          backgroundColor: verdeVitalle,
        ),
      );

      await carregarDados();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget cardAvaliacao(Map<String, dynamic> avaliacao) {
    final nota = (avaliacao['nota'] as num?)?.toDouble() ?? 0;
    final minhaAvaliacao = avaliacao['minha_avaliacao'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: verdeVitalle.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: verdeLimao,
                child: const Icon(
                  Icons.person_outline,
                  color: verdeEscuro,
                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avaliacao['nome_cuidador']?.toString() ??
                          'Cuidador',
                      style: const TextStyle(
                        color: verdeEscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avaliacao['qualificacao']?.toString() ??
                          'Cuidador de idosos',
                      style: const TextStyle(
                        color: verdeVitalle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (minhaAvaliacao)
                IconButton(
                  tooltip: 'Excluir minha avaliação',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    confirmarExclusao(
                      (avaliacao['id'] as num).toInt(),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              construirEstrelas(nota),
              const SizedBox(width: 8),
              Text(
                nota.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: verdeEscuro,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            avaliacao['comentario']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF45564A),
            ),
          ),

          const SizedBox(height: 15),
          const Divider(),

          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: verdeVitalle,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  avaliacao['autor']?.toString() ?? 'Usuário',
                  style: const TextStyle(
                    color: verdeVitalle,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                avaliacao['data']?.toString() ?? '',
                style: const TextStyle(
                  color: verdeVitalle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
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
          'Avaliações dos Cuidadores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar avaliações',
            onPressed: carregando ? null : carregarDados,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: verdeVitalle,
              ),
            )
          : erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          erro!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: carregarDados,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: carregarDados,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Avaliações dos Cuidadores',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: verdeEscuro,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Confira as experiências compartilhadas '
                        'sobre nossos profissionais.',
                        style: TextStyle(
                          color: verdeVitalle,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          cardResumo(
                            icone: Icons.star_rounded,
                            titulo: 'Média geral',
                            valor: mediaGeral
                                .toStringAsFixed(1)
                                .replaceAll('.', ','),
                          ),
                          const SizedBox(width: 12),
                          cardResumo(
                            icone: Icons.rate_review_outlined,
                            titulo: 'Avaliações',
                            valor: avaliacoes.length.toString(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      TextField(
                        controller: pesquisaController,
                        onChanged: (valor) {
                          setState(() {
                            textoPesquisa = valor;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Pesquisar avaliações...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: textoPesquisa.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    pesquisaController.clear();
                                    setState(() {
                                      textoPesquisa = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Filtrar por cuidador',
                        style: TextStyle(
                          color: verdeEscuro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<int?>(
                        initialValue: cuidadorSelecionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos os cuidadores'),
                          ),
                          ...cuidadores.map((cuidador) {
                            return DropdownMenuItem<int?>(
                              value: (cuidador['id'] as num).toInt(),
                              child: Text(
                                cuidador['nome']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (valor) {
                          setState(() {
                            cuidadorSelecionado = valor;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Filtrar por estrelas',
                        style: TextStyle(
                          color: verdeEscuro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue: filtroEstrelas,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Todas',
                            child: Text('Todas as avaliações'),
                          ),
                          DropdownMenuItem(
                            value: '5',
                            child: Text('5 estrelas'),
                          ),
                          DropdownMenuItem(
                            value: '4',
                            child: Text('4 estrelas'),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text('3 estrelas'),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text('2 estrelas'),
                          ),
                          DropdownMenuItem(
                            value: '1',
                            child: Text('1 estrela'),
                          ),
                        ],
                        onChanged: (valor) {
                          setState(() {
                            filtroEstrelas = valor ?? 'Todas';
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Avaliações',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: verdeEscuro,
                            ),
                          ),
                          Text(
                            '${avaliacoesFiltradas.length} encontradas',
                            style: const TextStyle(
                              color: verdeVitalle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      if (avaliacoesFiltradas.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Nenhuma avaliação encontrada.',
                              style: TextStyle(color: verdeVitalle),
                            ),
                          ),
                        )
                      else
                        ...avaliacoesFiltradas.map(cardAvaliacao),
                    ],
                  ),
                ),
    );
  }
}
