import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_config.dart';

class ConfigDialog extends StatefulWidget {
  final AppConfig configAtual;
  final Function(AppConfig novaConfig) onSalvar;
  final Future<int> Function(AppConfig config)? onImportarMesasFirebird;
  final VoidCallback onAbrirAuditoria;

  const ConfigDialog({
    super.key,
    required this.configAtual,
    required this.onSalvar,
    this.onImportarMesasFirebird,
    required this.onAbrirAuditoria,
  });

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late TextEditingController _tempoAlertaController;
  late TextEditingController _tempoLimiteController;
  late TextEditingController _totalMesasController;
  late TextEditingController _empresaIdController;
  late TextEditingController _caminhoBancoController;
  late TextEditingController _usuarioBancoController;
  late TextEditingController _senhaBancoController;
  late TextEditingController _apiUrlController;
  late bool _autoSync;

  bool _isImportando = false;
  String? _statusImportacao;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tempoAlertaController = TextEditingController(
      text: widget.configAtual.tempoAlertaMinutos.toString(),
    );
    _tempoLimiteController = TextEditingController(
      text: widget.configAtual.tempoLimiteMinutos.toString(),
    );
    _totalMesasController = TextEditingController(
      text: widget.configAtual.totalMesas.toString(),
    );
    _empresaIdController = TextEditingController(
      text: widget.configAtual.empresaId.toString(),
    );
    _caminhoBancoController = TextEditingController(
      text: widget.configAtual.caminhoBanco,
    );
    _usuarioBancoController = TextEditingController(
      text: widget.configAtual.usuarioBanco,
    );
    _senhaBancoController = TextEditingController(
      text: widget.configAtual.senhaBanco,
    );
    _apiUrlController = TextEditingController(
      text: widget.configAtual.apiUrl,
    );
    _autoSync = widget.configAtual.autoSync;
  }

  @override
  void dispose() {
    _tempoAlertaController.dispose();
    _tempoLimiteController.dispose();
    _totalMesasController.dispose();
    _empresaIdController.dispose();
    _caminhoBancoController.dispose();
    _usuarioBancoController.dispose();
    _senhaBancoController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  AppConfig _obterConfiguracaoForm() {
    return widget.configAtual.copyWith(
      tempoAlertaMinutos: int.tryParse(_tempoAlertaController.text) ?? widget.configAtual.tempoAlertaMinutos,
      tempoLimiteMinutos: int.tryParse(_tempoLimiteController.text) ?? widget.configAtual.tempoLimiteMinutos,
      totalMesas: int.tryParse(_totalMesasController.text) ?? widget.configAtual.totalMesas,
      empresaId: int.tryParse(_empresaIdController.text) ?? widget.configAtual.empresaId,
      caminhoBanco: _caminhoBancoController.text.trim(),
      usuarioBanco: _usuarioBancoController.text.trim(),
      senhaBanco: _senhaBancoController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      autoSync: _autoSync,
    );
  }

  Future<void> _executarImportacaoFirebird() async {
    if (widget.onImportarMesasFirebird == null) return;
    setState(() {
      _isImportando = true;
      _statusImportacao = null;
    });

    final config = _obterConfiguracaoForm();
    // Salva antes de importar para persistir o caminho informado
    widget.onSalvar(config);

    try {
      final total = await widget.onImportarMesasFirebird!(config);
      if (mounted) {
        setState(() {
          _isImportando = false;
          _totalMesasController.text = total.toString();
          _statusImportacao = '$total mesas importadas com sucesso da base Firebird!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImportando = false;
          _statusImportacao = 'Erro na importação: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_outlined, color: Color(0xFF0D47A1), size: 26),
                      SizedBox(width: 10),
                      Text(
                        'Configurações do Sistema',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Conteúdo rolável
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SEÇÃO 1: AUDITORIA (TB_INGRESSO) DENTRO DAS CONFIGURAÇÕES
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.receipt_long_rounded, color: Color(0xFF0D47A1), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Auditoria de Permanência (TB_INGRESSO)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Acesse o histórico completo de check-in, check-out, duração e rotatividade das mesas.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D47A1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                                  label: const Text('Abrir Tela de Auditoria & Histórico'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onAbrirAuditoria();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // SEÇÃO 2: SELEÇÃO DA BASE DE DADOS E CARGA DE MESAS
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storage_rounded, color: Color(0xFF1565C0), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Base de Dados Retaguarda (Firebird .FDB)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _caminhoBancoController,
                                decoration: InputDecoration(
                                  labelText: 'Caminho do Banco de Dados (.FDB)',
                                  hintText: r'C:\Users\Walter\OneDrive\DADOS\MANSAO\DADOS.FDB',
                                  helperText: 'Arquivo local ou caminho de rede para o banco de dados',
                                  prefixIcon: const Icon(Icons.folder_open_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    tooltip: 'Restaurar caminho padrão MANSAO',
                                    icon: const Icon(Icons.restore_rounded),
                                    onPressed: () {
                                      _caminhoBancoController.text =
                                          AppConstants.defaultCaminhoBancoFirebird;
                                    },
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _usuarioBancoController,
                                      decoration: InputDecoration(
                                        labelText: 'Usuário',
                                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _senhaBancoController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: _isImportando
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_download_rounded, size: 18),
                                  label: Text(
                                    _isImportando
                                        ? 'Importando mesas do Firebird...'
                                        : 'Trazer Mesas Cadastradas da Base (TB_MESA)',
                                  ),
                                  onPressed: _isImportando ? null : _executarImportacaoFirebird,
                                ),
                              ),
                              if (_statusImportacao != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _statusImportacao!.startsWith('Erro')
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _statusImportacao!.startsWith('Erro')
                                          ? Colors.red.shade300
                                          : Colors.green.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    _statusImportacao!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _statusImportacao!.startsWith('Erro')
                                          ? Colors.red.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // SEÇÃO 3: PARÂMETROS DE TEMPO E LIMITES
                        const Text(
                          'Parâmetros de Tolerância e Rotatividade',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tempoAlertaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Alerta (minutos)',
                                  helperText: 'Padrão: 90 min (1h30m)',
                                  prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num <= 0) return 'Informe minutos';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _tempoLimiteController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Limite Máximo (min)',
                                  helperText: 'Padrão: 120 min (2h00m)',
                                  prefixIcon: const Icon(Icons.alarm_on_rounded, color: Colors.red, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  final alerta = int.tryParse(_tempoAlertaController.text);
                                  if (num == null || num <= 0) return 'Informe minutos';
                                  if (alerta != null && num <= alerta) {
                                    return 'Maior que alerta';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalMesasController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Quantidade de Mesas',
                                  prefixIcon: const Icon(Icons.table_restaurant_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num <= 0) return 'Mínimo de 1 mesa';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _empresaIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'ID da Empresa (ERP)',
                                  prefixIcon: const Icon(Icons.business_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 20),

              // Botões inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final novaConfig = _obterConfiguracaoForm();
                        widget.onSalvar(novaConfig);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Salvar Configurações'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
