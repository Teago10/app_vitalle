import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../main.dart';

import 'avaliacoes_view.dart';

import 'pacientes_view.dart';

import 'atendimentos_view.dart';

import 'suporte_view.dart';

import 'cuidadores_view.dart';

import 'configuracoes_view.dart';

class DashboardView extends StatelessWidget {
  final String token;

  final Map<String, dynamic> usuario;

  const DashboardView({super.key, required this.token, required this.usuario});

  static const verdeEscuro = Color(0xFF07311C);

  static const verdeMenu = verdeEscuro;

  static const verdeVitalle = Color(0xFF52745C);

  static const verde = verdeVitalle;

  static const verdeLimao = Color(0xFFBBF0B9);

  static const fundoCard = Color(0xFFFCF7F4);

  static const verdeClaro = Color(0xFFFCF7F4);

  static const fundo = Color(0xFFFCF7F4);

  String get nomeUsuario => usuario['nome']?.toString() ?? 'Usuário';

  String get tipoUsuario {
    switch (usuario['tipo_usuario']?.toString()) {
      case 'responsavel':
        return 'Responsável';

      case 'cuidador':
        return 'Cuidador';

      case 'admin':
        return 'Administrador';

      default:
        return 'Usuário';
    }
  }

  String get iniciaisUsuario {
    final partes = nomeUsuario
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (partes.isEmpty) return 'U';

    if (partes.length == 1) return partes.first[0].toUpperCase();

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  void navegar(BuildContext context, String destino) {
    Navigator.pop(context);

    if (destino == 'Sair') {
      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(builder: (_) => const TelaLogin()),

        (route) => false,
      );

      return;
    }

    if (destino == 'Início') return;

    if (destino == 'Pacientes') {
      Navigator.push(
        context,

        MaterialPageRoute(builder: (_) => PacientesView(token: token)),
      );

      return;
    }

    if (destino == 'Avaliações') {
      Navigator.push(
        context,

        MaterialPageRoute(builder: (_) => AvaliacoesView(token: token)),
      );

      return;
    }

    if (destino == 'Cuidadores') {
      Navigator.push(
        context,

        MaterialPageRoute(builder: (_) => CuidadoresView(token: token)),
      );

      return;
    }

    if (destino == 'Configurações') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfiguracoesView(token: token)),
      );

      return;
    }

    if (destino == 'Suporte') {
      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => SuporteView(token: token, usuario: usuario),
        ),
      );

      return;
    }

    if (destino == 'Atendimentos') {
      Navigator.push(
        context,

        MaterialPageRoute(builder: (_) => AtendimentosView(token: token)),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A tela de $destino será implementada em breve.'),

        backgroundColor: verdeMenu,
      ),
    );
  }

  void navegarPagina(BuildContext context, String destino) {
    if (destino == 'Pacientes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PacientesView(token: token)),
      );
    } else if (destino == 'Cuidadores') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CuidadoresView(token: token)),
      );
    } else if (destino == 'Atendimentos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AtendimentosView(token: token)),
      );
    } else if (destino == 'Avaliações') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AvaliacoesView(token: token)),
      );
    } else if (destino == 'Suporte') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuporteView(token: token, usuario: usuario),
        ),
      );
    } else if (destino == 'Configurações') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfiguracoesView(token: token)),
      );
    }
  }

  Widget atalho(
    BuildContext context,
    String titulo,
    IconData icone,
    double largura,
  ) {
    return SizedBox(
      width: largura,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => navegarPagina(context, titulo),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1EAE0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, size: 29, color: verdeVitalle),
                const SizedBox(height: 17),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: verdeEscuro,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Text(
                      'Acessar',
                      style: TextStyle(fontSize: 12, color: verdeVitalle),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: verdeVitalle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget itemMenu(
    BuildContext context,

    IconData icone,

    String titulo, {

    bool selecionado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),

      child: Material(
        color: selecionado ? verde : Colors.transparent,

        borderRadius: BorderRadius.circular(13),

        child: InkWell(
          borderRadius: BorderRadius.circular(13),

          onTap: () => navegar(context, titulo),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

            child: Row(
              children: [
                Icon(icone, color: Colors.white, size: 22),

                const SizedBox(width: 17),

                Expanded(
                  child: Text(
                    titulo,

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 14.5,

                      fontWeight: selecionado
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),

                if (selecionado)
                  const Icon(Icons.circle, size: 7, color: Color(0xFFBBF0B9)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget construirDrawer(BuildContext context) {
    return Drawer(
      width: 290,

      backgroundColor: verdeMenu,

      surfaceTintColor: Colors.transparent,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),

      child: SafeArea(
        top: true,

        bottom: true,

        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,

                        color: Color(0xFFBBF0B9),

                        size: 35,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Vitalle',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 27,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Cuidado que transforma',

                    style: TextStyle(color: Color(0xFFBBF0B9), fontSize: 12),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFF07311C),

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(
                        color: Colors.white.withValues(alpha: .09),
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            border: Border.all(color: Colors.white, width: 2),
                          ),

                          child: CircleAvatar(
                            radius: 22,

                            backgroundColor: Color(0xFF07311C),

                            child: Text(
                              iniciaisUsuario,

                              style: const TextStyle(
                                color: Colors.white,

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                nomeUsuario,

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,

                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                tipoUsuario,

                                style: const TextStyle(
                                  color: Color(0xFFBBF0B9),

                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.person_outline,

                          color: Color(0xFFBBF0B9),

                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),

              child: Divider(color: Color(0xFF52745C), height: 1),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 15),

                children: [
                  itemMenu(
                    context,

                    Icons.home_outlined,

                    'Início',

                    selecionado: true,
                  ),

                  itemMenu(context, Icons.people_outline_rounded, 'Pacientes'),

                  itemMenu(
                    context,

                    Icons.health_and_safety_outlined,

                    'Cuidadores',
                  ),

                  itemMenu(
                    context,

                    Icons.calendar_month_outlined,

                    'Atendimentos',
                  ),

                  itemMenu(context, Icons.star_outline_rounded, 'Avaliações'),

                  itemMenu(context, Icons.support_agent_outlined, 'Suporte'),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),

              child: Divider(color: Color(0xFF52745C), height: 1),
            ),

            const SizedBox(height: 9),

            itemMenu(context, Icons.settings_outlined, 'Configurações'),

            itemMenu(context, Icons.logout_rounded, 'Sair'),

            const SizedBox(height: 10),
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

        drawer: construirDrawer(context),

        appBar: AppBar(
          backgroundColor: verdeEscuro,

          foregroundColor: Colors.white,

          surfaceTintColor: Colors.transparent,

          elevation: 0,

          titleSpacing: 4,

          title: const Text(
            'Vitalle',

            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
          ),

          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 18),

              child: Icon(
                Icons.volunteer_activism_outlined,

                color: Color(0xFFBBF0B9),
              ),
            ),
          ],
        ),

        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
            children: [
              Text(
                'Olá, ${nomeUsuario.split(' ').first}!',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: verdeEscuro,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'O que você gostaria de fazer hoje?',
                style: TextStyle(fontSize: 14, color: verdeVitalle),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: verdeEscuro,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      color: verdeLimao,
                      size: 35,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cuidar de quem importa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Acesse suas funcionalidades com poucos toques.',
                      style: TextStyle(color: Color(0xFFD8E8DA), height: 1.4),
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: () => navegarPagina(context, 'Atendimentos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: verdeLimao,
                        foregroundColor: verdeEscuro,
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Ver atendimentos'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Acesso rápido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: verdeEscuro,
                ),
              ),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, constraints) {
                  final largura = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      atalho(
                        context,
                        'Pacientes',
                        Icons.people_outline_rounded,
                        largura,
                      ),
                      atalho(
                        context,
                        'Cuidadores',
                        Icons.health_and_safety_outlined,
                        largura,
                      ),
                      atalho(
                        context,
                        'Atendimentos',
                        Icons.calendar_month_outlined,
                        largura,
                      ),
                      atalho(
                        context,
                        'Avaliações',
                        Icons.star_outline_rounded,
                        largura,
                      ),
                      atalho(
                        context,
                        'Suporte',
                        Icons.support_agent_outlined,
                        largura,
                      ),
                      atalho(
                        context,
                        'Configurações',
                        Icons.settings_outlined,
                        largura,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
