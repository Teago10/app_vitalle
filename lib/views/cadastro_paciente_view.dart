
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class CadastroPacienteView extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? paciente;

  const CadastroPacienteView({
    super.key,
    required this.token,
    this.paciente,
  });

  @override
  State<CadastroPacienteView> createState() =>
      _CadastroPacienteViewState();
}

class _CadastroPacienteViewState extends State<CadastroPacienteView> {
  static const Color verdeEscuro = Color(0xFF07311C);
  static const Color verdeVitalle = Color(0xFF52745C);
  static const Color verdeLimao = Color(0xFFBBF0B9);
  static const Color fundo = Color(0xFFFCF7F4);
  static const Color fundoCard = Color(0xFFFDF9F9);

  final formKey = GlobalKey<FormState>();

  final nome = TextEditingController();
  final dataNascimento = TextEditingController();
  final email = TextEditingController();
  final comorbidade = TextEditingController();
  final condicaoFisica = TextEditingController();
  final medicacao = TextEditingController();
  final horarioMedicacao = TextEditingController();
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final estado = TextEditingController();

  final numeroFocus = FocusNode();

  bool usaFraldas = false;
  bool salvando = false;
  bool buscandoCep = false;
  bool alterado = false;

  String? erroCep;
  String? ultimoCepConsultado;
  int identificadorConsulta = 0;

  bool get modoEdicao => widget.paciente != null;

  List<TextEditingController> get controllers => [
        nome,
        dataNascimento,
        email,
        comorbidade,
        condicaoFisica,
        medicacao,
        horarioMedicacao,
        cep,
        rua,
        numero,
        complemento,
        bairro,
        cidade,
        estado,
      ];

  @override
  void initState() {
    super.initState();

    if (modoEdicao) {
      final paciente = widget.paciente!;

      String valor(String campo) =>
          paciente[campo]?.toString() ?? '';

      nome.text = valor('nome');
      email.text = valor('email');
      comorbidade.text = valor('comorbidade');
      condicaoFisica.text = valor('condicao_fisica');
      medicacao.text = valor('medicacao');
      horarioMedicacao.text = valor('horario_medicacao');

      cep.text = valor('cep');
      rua.text = valor('rua');
      numero.text = valor('numero');
      complemento.text = valor('complemento');
      bairro.text = valor('bairro');
      cidade.text = valor('cidade');
      estado.text = valor('estado');

      usaFraldas = paciente['usa_fraldas'] == true ||
          paciente['usa_fraldas'] == 1 ||
          paciente['usa_fraldas'] == '1';

      final data = DateTime.tryParse(
        valor('data_nascimento'),
      );

      if (data != null) {
        dataNascimento.text =
            '${data.day.toString().padLeft(2, '0')}/'
            '${data.month.toString().padLeft(2, '0')}/'
            '${data.year}';
      }

      ultimoCepConsultado =
          cep.text.replaceAll(RegExp(r'\D'), '');
    }

    for (final controller in controllers) {
      controller.addListener(marcarAlteracao);
    }
  }

  void marcarAlteracao() {
    alterado = true;
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.removeListener(marcarAlteracao);
      controller.dispose();
    }

    numeroFocus.dispose();
    super.dispose();
  }

  String somenteNumeros(String valor) =>
      valor.replaceAll(RegExp(r'\D'), '');

  String? obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  String? validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o e-mail';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(valor.trim())) {
      return 'E-mail inválido';
    }

    return null;
  }

  String? validarData(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe a data';
    }

    final partes = valor.split('/');

    if (partes.length != 3) return 'Data inválida';

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) {
      return 'Data inválida';
    }

    if (ano < 1900 || ano > DateTime.now().year) {
      return 'Ano inválido';
    }

    final data = DateTime(ano, mes, dia);

    if (data.day != dia ||
        data.month != mes ||
        data.year != ano ||
        data.isAfter(DateTime.now())) {
      return 'Data inválida';
    }

    return null;
  }

  String converterData(String valor) {
    final partes = valor.split('/');
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  Future<void> selecionarData() async {
    final agora = DateTime.now();
    DateTime inicial = DateTime(1950);

    if (dataNascimento.text.isNotEmpty &&
        validarData(dataNascimento.text) == null) {
      final partes = dataNascimento.text.split('/');

      inicial = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
    }

    final selecionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1900),
      lastDate: agora,
      helpText: 'Data de nascimento',
    );

    if (selecionada == null || !mounted) return;

    setState(() {
      dataNascimento.text =
          '${selecionada.day.toString().padLeft(2, '0')}/'
          '${selecionada.month.toString().padLeft(2, '0')}/'
          '${selecionada.year}';
    });
  }

  Future<void> consultarCep() async {
    final cepLimpo = somenteNumeros(cep.text);

    if (cepLimpo.length != 8) {
      setState(() {
        erroCep = 'Informe um CEP com 8 números';
      });
      return;
    }

    if (ultimoCepConsultado == cepLimpo) return;

    final consultaAtual = ++identificadorConsulta;

    setState(() {
      buscandoCep = true;
      erroCep = null;
    });

    try {
      final endereco = await ApiService.buscarCep(cepLimpo);

      if (!mounted ||
          consultaAtual != identificadorConsulta ||
          somenteNumeros(cep.text) != cepLimpo) {
        return;
      }

      setState(() {
        rua.text = endereco['logradouro']?.toString() ?? '';
        bairro.text = endereco['bairro']?.toString() ?? '';
        cidade.text = endereco['localidade']?.toString() ?? '';
        estado.text = endereco['uf']?.toString() ?? '';

        ultimoCepConsultado = cepLimpo;
      });

      if (rua.text.isNotEmpty) {
        numeroFocus.requestFocus();
      }
    } catch (e) {
      if (!mounted ||
          consultaAtual != identificadorConsulta ||
          somenteNumeros(cep.text) != cepLimpo) {
        return;
      }

      setState(() {
        erroCep = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && consultaAtual == identificadorConsulta) {
        setState(() {
          buscandoCep = false;
        });
      }
    }
  }

  void cepAlterado(String valor) {
    identificadorConsulta++;

    setState(() {
      erroCep = null;
      buscandoCep = false;
      ultimoCepConsultado = null;

      rua.clear();
      bairro.clear();
      cidade.clear();
      estado.clear();
    });

    if (somenteNumeros(valor).length == 8) {
      consultarCep();
    }
  }

  void limparCep() {
    identificadorConsulta++;

    setState(() {
      cep.clear();
      rua.clear();
      bairro.clear();
      cidade.clear();
      estado.clear();
      buscandoCep = false;
      erroCep = null;
      ultimoCepConsultado = null;
    });
  }

  Widget campo(
    String titulo,
    TextEditingController controller, {
    bool required = false,
    int? maxLength,
    TextInputType? teclado,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    FocusNode? focusNode,
    Widget? suffixIcon,
    TextCapitalization capitalization =
        TextCapitalization.sentences,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLength,
        keyboardType: teclado,
        textCapitalization: capitalization,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator ?? (required ? obrigatorio : null),
        decoration: InputDecoration(
          labelText: titulo,
          counterText: '',
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: verdeVitalle),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: verdeVitalle.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: verdeVitalle,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget campoCep() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: cep,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
          _CepFormatter(),
        ],
        onChanged: cepAlterado,
        validator: (valor) {
          if (somenteNumeros(valor ?? '').length != 8) {
            return 'Informe um CEP válido';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'CEP *',
          hintText: '00000-000',
          errorText: erroCep,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(
            Icons.location_on_outlined,
            color: verdeVitalle,
          ),
          suffixIcon: buscandoCep
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: verdeVitalle,
                    ),
                  ),
                )
              : cep.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpar CEP',
                      onPressed: limparCep,
                      icon: const Icon(Icons.close),
                    )
                  : const Icon(
                      Icons.search,
                      color: verdeVitalle,
                    ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget secao(
    String titulo,
    IconData icone,
    List<Widget> campos,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fundoCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: verdeVitalle.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: verdeVitalle),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: verdeEscuro,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...campos,
        ],
      ),
    );
  }

  Future<bool> confirmarSaida() async {
    if (!alterado) return true;

    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Os dados preenchidos ainda não foram salvos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return sair ?? false;
  }

  Future<void> salvarPaciente() async {
    if (salvando || buscandoCep) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifique os campos obrigatórios.'),
        ),
      );
      return;
    }

    setState(() => salvando = true);

    String? opcional(TextEditingController controller) {
      final valor = controller.text.trim();
      return valor.isEmpty ? null : valor;
    }

    final dados = <String, dynamic>{
      'nome': nome.text.trim(),
      'data_nascimento': converterData(dataNascimento.text),
      'email': email.text.trim(),
      'comorbidade': opcional(comorbidade),
      'condicao_fisica': opcional(condicaoFisica),
      'usa_fraldas': usaFraldas,
      'medicacao': opcional(medicacao),
      'horario_medicacao': opcional(horarioMedicacao),
      'cep': cep.text.trim(),
      'rua': rua.text.trim(),
      'numero': numero.text.trim(),
      'complemento': opcional(complemento),
      'bairro': bairro.text.trim(),
      'cidade': cidade.text.trim(),
      'estado': estado.text.trim().toUpperCase(),
    };

    try {
      if (modoEdicao) {
        await ApiService.editarPaciente(
          widget.token,
          int.parse(widget.paciente!['id'].toString()),
          dados,
        );
      } else {
        await ApiService.cadastrarPaciente(
          widget.token,
          dados,
        );
      }

      if (!mounted) return;

      alterado = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            modoEdicao
                ? 'Paciente atualizado com sucesso!'
                : 'Paciente cadastrado com sucesso!',
          ),
          backgroundColor: verdeVitalle,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !alterado && !salvando,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || salvando) return;

        final sair = await confirmarSaida();

        if (sair && context.mounted) {
          alterado = false;
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: fundo,
        appBar: AppBar(
          backgroundColor: verdeEscuro,
          foregroundColor: Colors.white,
          title: Text(
            modoEdicao ? 'Editar paciente' : 'Cadastrar paciente',
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                modoEdicao ? 'Editar paciente' : 'Novo paciente',
                style: const TextStyle(
                  color: verdeEscuro,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                modoEdicao
                    ? 'Atualize os dados do paciente.'
                    : 'Preencha os dados para realizar o cadastro.',
                style: const TextStyle(color: verdeVitalle),
              ),
              const SizedBox(height: 24),

              secao(
                'Dados pessoais',
                Icons.person_outline,
                [
                  campo(
                    'Nome completo *',
                    nome,
                    required: true,
                    maxLength: 150,
                    capitalization: TextCapitalization.words,
                  ),
                  campo(
                    'Data de nascimento *',
                    dataNascimento,
                    readOnly: true,
                    onTap: selecionarData,
                    validator: validarData,
                    suffixIcon: IconButton(
                      onPressed: selecionarData,
                      icon: const Icon(
                        Icons.calendar_month,
                        color: verdeVitalle,
                      ),
                    ),
                  ),
                  campo(
                    'E-mail *',
                    email,
                    maxLength: 70,
                    teclado: TextInputType.emailAddress,
                    validator: validarEmail,
                    capitalization: TextCapitalization.none,
                  ),
                ],
              ),

              secao(
                'Informações de saúde',
                Icons.favorite_outline,
                [
                  campo(
                    'Comorbidade',
                    comorbidade,
                    maxLength: 200,
                  ),
                  campo(
                    'Condição física',
                    condicaoFisica,
                    maxLength: 200,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usa fraldas?'),
                    value: usaFraldas,
                    activeThumbColor: verdeVitalle,
                    onChanged: (valor) {
                      setState(() {
                        usaFraldas = valor;
                        alterado = true;
                      });
                    },
                  ),
                  campo(
                    'Medicação',
                    medicacao,
                    maxLength: 200,
                  ),
                  campo(
                    'Horário da medicação',
                    horarioMedicacao,
                    maxLength: 100,
                  ),
                ],
              ),

              secao(
                'Endereço',
                Icons.location_on_outlined,
                [
                  const Text(
                    'Digite o CEP para preencher o endereço automaticamente.',
                    style: TextStyle(
                      color: verdeVitalle,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  campoCep(),
                  campo(
                    'Rua *',
                    rua,
                    required: true,
                    maxLength: 200,
                    capitalization: TextCapitalization.words,
                  ),
                  campo(
                    'Número *',
                    numero,
                    required: true,
                    maxLength: 20,
                    focusNode: numeroFocus,
                  ),
                  campo(
                    'Complemento',
                    complemento,
                    maxLength: 100,
                  ),
                  campo(
                    'Bairro *',
                    bairro,
                    required: true,
                    maxLength: 100,
                  ),
                  campo(
                    'Cidade *',
                    cidade,
                    required: true,
                    maxLength: 100,
                  ),
                  campo(
                    'Estado *',
                    estado,
                    maxLength: 2,
                    capitalization:
                        TextCapitalization.characters,
                    validator: (valor) {
                      if (valor == null ||
                          !RegExp(r'^[a-zA-Z]{2}$')
                              .hasMatch(valor.trim())) {
                        return 'Informe a UF com 2 letras';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      salvando || buscandoCep ? null : salvarPaciente,
                  icon: salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: verdeEscuro,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    salvando
                        ? 'Salvando...'
                        : modoEdicao
                            ? 'Salvar alterações'
                            : 'Cadastrar paciente',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verdeLimao,
                    foregroundColor: verdeEscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text
        .replaceAll(RegExp(r'\D'), '');

    final limitados = digitos.length > 8
        ? digitos.substring(0, 8)
        : digitos;

    final formatado = limitados.length > 5
        ? '${limitados.substring(0, 5)}-${limitados.substring(5)}'
        : limitados;

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(
        offset: formatado.length,
      ),
    );
  }
}
