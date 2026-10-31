import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConfiguracoesView extends StatefulWidget {
  final String token;
  const ConfiguracoesView({super.key, required this.token});

  @override
  State<ConfiguracoesView> createState() => _ConfiguracoesViewState();
}

class _ConfiguracoesViewState extends State<ConfiguracoesView> {
  static const escuro = Color(0xFF07311C);
  static const verde = Color(0xFF52745C);
  static const fundo = Color(0xFFFCF7F4);
  final _perfilKey = GlobalKey<FormState>();
  final _senhaKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final email = TextEditingController();
  final senhaAtual = TextEditingController();
  final senhaNova = TextEditingController();
  final senhaConfirmacao = TextEditingController();
  bool carregando = true;
  bool salvandoPerfil = false;
  bool salvandoSenha = false;
  bool mostrarSenhas = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senhaAtual.dispose();
    senhaNova.dispose();
    senhaConfirmacao.dispose();
    super.dispose();
  }

  void aviso(String mensagem, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: sucesso ? verde : Colors.red.shade700,
    ));
  }

  Future<void> carregarPerfil() async {
    setState(() { carregando = true; erro = null; });
    try {
      final dados = await ApiService.buscarPerfil(widget.token);
      final usuario = dados['usuario'] as Map<String, dynamic>;
      if (!mounted) return;
      nome.text = (usuario['nome'] ?? '').toString();
      email.text = (usuario['email'] ?? '').toString();
    } catch (e) {
      if (mounted) setState(() => erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> salvarPerfil() async {
    if (!_perfilKey.currentState!.validate() || salvandoPerfil) return;
    FocusScope.of(context).unfocus();
    setState(() => salvandoPerfil = true);
    try {
      await ApiService.atualizarPerfil(widget.token, nome.text.trim(), email.text.trim());
      if (mounted) aviso('Informações atualizadas com sucesso!', sucesso: true);
    } catch (e) {
      if (mounted) aviso(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => salvandoPerfil = false);
    }
  }

  Future<void> salvarSenha() async {
    if (!_senhaKey.currentState!.validate() || salvandoSenha) return;
    FocusScope.of(context).unfocus();
    setState(() => salvandoSenha = true);
    try {
      await ApiService.atualizarSenha(widget.token, senhaAtual.text,
        senhaNova.text, senhaConfirmacao.text);
      senhaAtual.clear();
      senhaNova.clear();
      senhaConfirmacao.clear();
      if (mounted) aviso('Senha atualizada com sucesso!', sucesso: true);
    } catch (e) {
      if (mounted) aviso(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => salvandoSenha = false);
    }
  }

  InputDecoration decoracao(String dica, IconData icone) => InputDecoration(
    hintText: dica,
    prefixIcon: Icon(icone, color: verde),
    filled: true,
    fillColor: fundo,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD9E2DA))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: verde, width: 2)),
  );

  Widget secao(IconData icone, String titulo, String subtitulo, Widget conteudo) =>
    Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EAE0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
            child: Icon(icone, color: verde)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: escuro, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(subtitulo, style: const TextStyle(color: verde, fontSize: 12)),
          ])),
        ]),
        const Divider(height: 32),
        conteudo,
      ]),
    );

  Widget campo(String titulo, TextEditingController controle, String dica, IconData icone,
      {bool emailCampo = false, bool senha = false, String? Function(String?)? validar}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, color: escuro)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controle,
          obscureText: senha && !mostrarSenhas,
          keyboardType: emailCampo ? TextInputType.emailAddress : TextInputType.text,
          textInputAction: TextInputAction.next,
          autofillHints: emailCampo ? const [AutofillHints.email] : null,
          decoration: decoracao(dica, icone),
          validator: validar ?? (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
        ),
      ]),
    );

  Widget botao(String titulo, bool ocupado, VoidCallback acao, IconData icone) =>
    SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: ocupado ? null : acao,
        icon: ocupado ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icone),
        label: Text(titulo),
        style: ElevatedButton.styleFrom(backgroundColor: escuro, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: fundo,
    appBar: AppBar(title: const Text('Configurações'),
      backgroundColor: escuro, foregroundColor: Colors.white),
    body: carregando
      ? const Center(child: CircularProgressIndicator(color: verde))
      : erro != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(erro!, textAlign: TextAlign.center),
            TextButton(onPressed: carregarPerfil, child: const Text('Tentar novamente')),
          ]))
        : ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Meu Perfil', style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w800, color: escuro)),
            const SizedBox(height: 5),
            const Text('Gerencie suas informações pessoais e a segurança da sua conta.',
              style: TextStyle(color: verde)),
            const SizedBox(height: 24),
            secao(Icons.manage_accounts_outlined, 'Informações pessoais',
              'Atualize seu nome e endereço de e-mail.',
              Form(key: _perfilKey, child: Column(children: [
                campo('Nome completo', nome, 'Digite seu nome completo', Icons.person_outline),
                campo('Endereço de e-mail', email, 'Digite seu e-mail', Icons.email_outlined,
                  emailCampo: true, validar: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'E-mail inválido';
                    return null;
                  }),
                botao('Salvar alterações', salvandoPerfil, salvarPerfil, Icons.save_outlined),
              ]))),
            secao(Icons.lock_outline, 'Segurança da conta',
              'Altere sua senha para manter sua conta protegida.',
              Form(key: _senhaKey, child: Column(children: [
                campo('Senha atual', senhaAtual, 'Digite sua senha atual', Icons.lock_outline, senha: true),
                campo('Nova senha', senhaNova, 'Digite a nova senha', Icons.key_outlined, senha: true),
                campo('Confirmar nova senha', senhaConfirmacao, 'Confirme a nova senha',
                  Icons.verified_user_outlined, senha: true,
                  validar: (v) => v != senhaNova.text ? 'As senhas não coincidem' :
                    (v == null || v.isEmpty ? 'Campo obrigatório' : null)),
                CheckboxListTile(
                  value: mostrarSenhas,
                  onChanged: (v) => setState(() => mostrarSenhas = v ?? false),
                  title: const Text('Mostrar senhas'),
                  activeColor: verde,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                botao('Atualizar senha', salvandoSenha, salvarSenha, Icons.lock_reset),
              ]))),
            secao(Icons.delete_outline, 'Excluir conta',
              'Gerencie a exclusão permanente da sua conta.',
              const Text('Por segurança, a exclusão de conta ainda deve ser feita pelo site do Vitalle.',
                style: TextStyle(color: verde))),
          ]),
  );
}
