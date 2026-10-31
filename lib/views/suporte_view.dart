import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuporteView extends StatefulWidget {
  final String token;
  final Map<String, dynamic> usuario;

  const SuporteView({super.key, required this.token, required this.usuario});

  @override
  State<SuporteView> createState() => _SuporteViewState();
}

class _SuporteViewState extends State<SuporteView> {
  static const verdeEscuro = Color(0xFF07311C);
  static const verdeVitalle = Color(0xFF52745C);
  static const verdeLimao = Color(0xFFBBF0B9);
  static const fundo = Color(0xFFFCF7F4);

  final formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final assuntoController = TextEditingController();
  final mensagemController = TextEditingController();
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    nomeController.text = widget.usuario['nome']?.toString() ?? '';
  }

  @override
  void dispose() {
    nomeController.dispose();
    assuntoController.dispose();
    mensagemController.dispose();
    super.dispose();
  }

  InputDecoration decoracao(String dica, IconData icone) {
    return InputDecoration(
      hintText: dica,
      prefixIcon: Icon(icone, color: verdeVitalle),
      filled: true,
      fillColor: fundo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: verdeVitalle, width: 2),
      ),
    );
  }

  Widget campoTitulo(String titulo) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(titulo, style: const TextStyle(
      fontWeight: FontWeight.w600, color: verdeEscuro, fontSize: 14,
    )),
  );

  Future<void> enviar() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => enviando = true);
    try {
      await ApiService.enviarSolicitacaoSuporte(
        widget.token,
        nome: nomeController.text.trim(),
        assunto: assuntoController.text.trim(),
        mensagem: mensagemController.text.trim(),
      );
      if (!mounted) return;
      assuntoController.clear();
      mensagemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Solicitação enviada com sucesso!'),
        backgroundColor: verdeVitalle,
      ));
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erro.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(title: const Text('Central de Suporte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: verdeEscuro,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.support_agent_outlined, color: verdeLimao, size: 38),
                        SizedBox(height: 16),
                        Text('Como podemos ajudar?', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24,
                        )),
                        SizedBox(height: 10),
                        Text('Envie sua dúvida ou conte para nós se encontrou algum problema.',
                          style: TextStyle(color: Colors.white70, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8DED8)),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Envie sua solicitação', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: verdeEscuro,
                          )),
                          const SizedBox(height: 6),
                          const Text('Preencha os campos para entrar em contato com nossa equipe.',
                            style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 24),
                          campoTitulo('Nome completo'),
                          TextFormField(
                            controller: nomeController,
                            maxLength: 150,
                            textCapitalization: TextCapitalization.words,
                            decoration: decoracao('Digite seu nome completo', Icons.person_outline),
                            validator: (valor) => (valor?.trim().isEmpty ?? true)
                                ? 'Informe seu nome completo.' : null,
                          ),
                          const SizedBox(height: 10),
                          campoTitulo('Assunto'),
                          TextFormField(
                            controller: assuntoController,
                            maxLength: 200,
                            decoration: decoracao('Ex.: Problema no cadastro', Icons.subject_outlined),
                            validator: (valor) => (valor?.trim().isEmpty ?? true)
                                ? 'Informe o assunto.' : null,
                          ),
                          const SizedBox(height: 10),
                          campoTitulo('Descrição da solicitação'),
                          TextFormField(
                            controller: mensagemController,
                            maxLines: 6,
                            minLines: 4,
                            decoration: decoracao('Conte o que aconteceu e quais dificuldades encontrou...',
                                Icons.edit_note_outlined),
                            validator: (valor) => (valor?.trim().isEmpty ?? true)
                                ? 'Descreva sua solicitação.' : null,
                          ),
                          const SizedBox(height: 10),
                          const Text('Quanto mais detalhes você fornecer, mais fácil será compreender sua solicitação.',
                            style: TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: enviando ? null : enviar,
                              icon: enviando
                                  ? const SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: verdeLimao))
                                  : const Icon(Icons.send_outlined),
                              label: Text(enviando ? 'Enviando...' : 'Enviar solicitação'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: verdeEscuro,
                                foregroundColor: verdeLimao,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
