import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'avaliacoes_view.dart';
import 'pacientes_view.dart';
import 'atendimentos_view.dart';

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: verdeClaro,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_outlined,
                        size: 43,
                        color: verde,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Bem-vindo ao Vitalle!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: verdeEscuro,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cuidar de quem importa começa aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF607568), fontSize: 15),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE8DED8)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: verde,
                            size: 32,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Seu cuidado, nossa prioridade',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: verdeEscuro,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Uma maneira simples e acolhedora de organizar atendimentos e conectar pessoas ao cuidado que merecem.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF607568),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu, color: verde, size: 20),
                        SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            'Explore as funcionalidades pelo menu',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: verdeEscuro, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
