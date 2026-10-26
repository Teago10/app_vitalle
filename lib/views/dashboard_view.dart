import 'package:flutter/material.dart';
import 'avaliacoes_view.dart';

class DashboardView extends StatelessWidget {
  final String token;

  const DashboardView({
    super.key,
    required this.token,
  });

  // Paleta de cores do Vitalle
  static const Color verdeEscuro = Color.fromARGB(255, 7, 49, 28);
  static const Color verdeVitalle = Color(0xFF52745C);
  static const Color verdeLimao = Color.fromARGB(255, 187, 240, 185);
  static const Color fundo = Color(0xFFF8F2EE);
  static const Color fundoCard = Color(0xFFF0EEE7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      // Menu lateral
      drawer: Drawer(
        backgroundColor: fundo,
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho do menu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: verdeEscuro,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.volunteer_activism, color: verdeLimao, size: 42),
                    SizedBox(height: 12),
                    Text(
                      'Vitalle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cuidado que transforma',
                      style: TextStyle(color: Color(0xFFD1E0D1), fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              itemMenu(
                context,
                Icons.home_outlined,
                'Início',
                selecionado: true,
              ),

              const Divider(indent: 20, endIndent: 20),

              // Cadastros
              itemMenu(context, Icons.people_outline, 'Pacientes'),

              itemMenu(context, Icons.health_and_safety_outlined, 'Cuidadores'),

              // Atendimentos
              itemMenu(context, Icons.calendar_month_outlined, 'Atendimentos'),

              // Avaliações
              itemMenu(context, Icons.star_outline, 'Avaliações'),

              // Suporte
              itemMenu(context, Icons.support_agent_outlined, 'Suporte'),

              const Spacer(),

              const Divider(indent: 20, endIndent: 20),

              // Configurações
              itemMenu(context, Icons.settings_outlined, 'Configurações'),

              // Sair
              itemMenu(context, Icons.logout, 'Sair'),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // Barra superior
      appBar: AppBar(
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Vitalle',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.volunteer_activism_outlined, color: verdeLimao),
          ),
        ],
      ),

      // Conteúdo principal
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),

                  // Ícone de boas-vindas
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: verdeVitalle.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: verdeVitalle,
                      size: 46,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Título principal
                  const Text(
                    'Bem-vindo ao Vitalle!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: verdeEscuro,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtítulo
                  const Text(
                    'Cuidar de quem importa começa aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF53645A),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Card de apresentação
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: fundoCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: verdeVitalle.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          color: verdeVitalle,
                          size: 30,
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
                          'Uma maneira simples e acolhedora de '
                          'organizar atendimentos e conectar '
                          'pessoas ao cuidado que merecem.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF607066),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Orientação de navegação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu, color: verdeVitalle, size: 20),

                      const SizedBox(width: 10),

                      Flexible(
                        child: Text(
                          'Explore as funcionalidades pelo menu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: verdeEscuro.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Componente dos itens do menu lateral
  Widget itemMenu(
    BuildContext context,
    IconData icone,
    String titulo, {
    bool selecionado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: Icon(icone, color: selecionado ? verdeVitalle : verdeEscuro),
        title: Text(
          titulo,
          style: TextStyle(
            color: verdeEscuro,
            fontSize: 15,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        tileColor: selecionado
            ? verdeVitalle.withValues(alpha: 0.10)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);

          if (titulo == 'Avaliações') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AvaliacoesView(
        token: token,
      ),
    ),
  );
} else if (titulo != 'Início') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A tela de $titulo será implementada em breve.'),
                backgroundColor: verdeEscuro,
              ),
            );
          }
        },
      ),
    );
  }
}
