import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'views/dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF07311C),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F2EE),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const VitalleApp());
}

class VitalleApp extends StatelessWidget {
  const VitalleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vitalle',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F2EE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF52745C)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07311C),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF07311C),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        useMaterial3: true,
      ),
      home: const TelaLogin(),
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  static const Color verdeEscuro = Color(0xFF07311C);
  static const Color verdeVitalle = Color(0xFF52745C);
  static const Color fundoCard = Color(0xFFFDF9F9);
  static const Color verdeLimao = Color(0xFFBBF0B9);
  static const Color fundo = Color(0xFFFCF7F4);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool ocultarSenha = true;
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> realizarLogin() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }
    setState(() => carregando = true);
    try {
      final resposta = await ApiService.login(email, senha);
      if (!mounted) return;
      if (resposta['sucesso'] == true) {
        final token = resposta['token'] as String?;
        if (token == null || token.isEmpty)
          throw Exception('O servidor não retornou um token válido.');
        final usuario = Map<String, dynamic>.from(resposta['usuario'] as Map);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardView(token: token, usuario: usuario),
          ),
        );
      } else {
        throw Exception(
          resposta['mensagem'] ?? 'Não foi possível realizar o login.',
        );
      }
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  InputDecoration decoracao(String dica, IconData icone, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: dica,
      prefixIcon: Icon(icone, color: verdeVitalle),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: verdeVitalle, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.favorite, size: 70, color: verdeVitalle),
                  const SizedBox(height: 16),
                  const Text(
                    'Vitalle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: verdeEscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cuidado que transforma',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: verdeVitalle),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Bem-vindo de volta!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: verdeEscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre com seus dados para continuar.',
                    style: TextStyle(fontSize: 15, color: verdeVitalle),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'E-mail',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: verdeEscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: decoracao(
                      'Digite seu e-mail',
                      Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Senha',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: verdeEscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: senhaController,
                    obscureText: ocultarSenha,
                    decoration: decoracao(
                      'Digite sua senha',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: verdeVitalle,
                        ),
                        onPressed: () =>
                            setState(() => ocultarSenha = !ocultarSenha),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: carregando ? null : realizarLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: verdeEscuro,
                        foregroundColor: verdeLimao,
                        disabledBackgroundColor: verdeVitalle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: carregando
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: verdeLimao,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
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
