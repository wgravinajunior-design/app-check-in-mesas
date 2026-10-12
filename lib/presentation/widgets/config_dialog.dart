import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_config.dart';

class ConfigDialog extends StatefulWidget {
  final AppConfig configAtual;
  final Function(AppConfig novaConfig) onSalvar;
  final Future<String> Function(AppConfig config)? onTestarConexao;
  final Future<int> Function(AppConfig config)? onImportarMesasFirebird;
  final VoidCallback onAbrirAuditoria;

  const ConfigDialog({
    super.key,
    required this.configAtual,
    required this.onSalvar,
    this.onTestarConexao,
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
  late TextEditingController _hostBancoController;
  late TextEditingController _portaBancoController;
  late TextEditingController _caminhoBancoController;
  late TextEditingController _usuarioBancoController;
  late TextEditingController _senhaBancoController;
  late TextEditingController _apiUrlController;
  late bool _autoSync;

  bool _isTestando = false;
  bool _isImportando = false;
  String? _statusMensagem;
  bool _statusSucesso = false;

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
    final hostSalvo = widget.configAtual.hostBanco.trim();
    final hostSugerido = (!kIsWeb && Platform.isAndroid && (hostSalvo == 'localhost' || hostSalvo == '127.0.0.1' || hostSalvo.isEmpty))
        ? AppConstants.defaultHostFirebird
        : (hostSalvo.isEmpty ? AppConstants.defaultHostFirebird : hostSalvo);

    _hostBancoController = TextEditingController(
      text: hostSugerido,
    );
    _portaBancoController = TextEditingController(
      text: widget.configAtual.portaBanco.toString(),
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
    _hostBancoController.dispose();
    _portaBancoController.dispose();
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
      hostBanco: _hostBancoController.text.trim(),
      portaBanco: int.tryParse(_portaBancoController.text) ?? widget.configAtual.portaBanco,
      caminhoBanco: _caminhoBancoController.text.trim(),
      usuarioBanco: _usuarioBancoController.text.trim(),
      senhaBanco: _senhaBancoController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      autoSync: _autoSync,
    );
  }

  Future<void> _testarConexaoFirebird() async {
    if (widget.onTestarConexao == null) return;
    setState(() {
      _isTestando = true;
      _statusMensagem = null;
    });

    final config = _obterConfiguracaoForm();
    widget.onSalvar(config);

    try {
      final resultado = await widget.onTestarConexao!(config);
      if (mounted) {
        setState(() {
          _isTestando = false;
          _statusSucesso = true;
          _statusMensagem = resultado;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestando = false;
          _statusSucesso = false;
          _statusMensagem = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _executarImportacaoFirebird() async {
    if (widget.onImportarMesasFirebird == null) return;
    setState(() {
      _isImportando = true;
      _statusMensagem = null;
    });

    final config = _obterConfiguracaoForm();
    widget.onSalvar(config);

    try {
      final total = await widget.onImportarMesasFirebird!(config);
      if (mounted) {
        setState(() {
          _isImportando = false;
          _statusSucesso = true;
          _totalMesasController.text = total.toString();
          _statusMensagem = '$total mesas da Mansão da Torre sincronizadas com sucesso!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImportando = false;
          _statusSucesso = false;
          _statusMensagem = 'Falha ao importar: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 750),
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
                      Icon(Icons.settings_outlined, color: Color(0xFF0D47A1), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Configurações',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D47A1), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Auditoria de Permanência (TB_INGRESSO)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Histórico de check-in, check-out, duração e rotatividade.',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                                label: const Text('Auditoria', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onAbrirAuditoria();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEÇÃO 2: CONEXÃO DIRETA COM O FIREBIRD 5.0
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.storage_rounded, color: Color(0xFF1565C0), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Conexão Direta Firebird 5.0',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Text(
                                      'Direto / Nativo',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Banner explicativo para Mobile / Wi-Fi
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.wifi_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Conexão direta: use o IP ${AppConstants.defaultHostFirebird} e porta ${AppConstants.defaultPortaFirebird}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _hostBancoController.text = AppConstants.defaultHostFirebird;
                                        _portaBancoController.text = AppConstants.defaultPortaFirebird.toString();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Aplicar IP',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), decoration: TextDecoration.underline),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Host e Porta
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _hostBancoController,
                                      decoration: InputDecoration(
                                        labelText: 'Host / IP Servidor',
                                        hintText: '192.168.0.109',
                                        prefixIcon: const Icon(Icons.dns_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _portaBancoController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Porta',
                                        hintText: '3060',
                                        helperText: 'Padrão FB5: 3060',
                                        prefixIcon: const Icon(Icons.lan_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Seleção rápida de porta
                              Row(
                                children: [
                                  const Text('Porta rápida: ', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _portaBancoController.text = '3060';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _portaBancoController.text == '3060' ? const Color(0xFFDBEAFE) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _portaBancoController.text == '3060' ? const Color(0xFF2563EB) : Colors.grey.shade300),
                                      ),
                                      child: const Text('3060 (FB5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _portaBancoController.text = '3050';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _portaBancoController.text == '3050' ? const Color(0xFFDBEAFE) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _portaBancoController.text == '3050' ? const Color(0xFF2563EB) : Colors.grey.shade300),
                                      ),
                                      child: const Text('3050 (Padrão)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Caminho da Base
                              TextFormField(
                                controller: _caminhoBancoController,
                                decoration: InputDecoration(
                                  labelText: 'Caminho Completo da Base (.FDB)',
                                  hintText: r'C:\Users\Walter\OneDrive\DADOS\MANSAO\DADOS.FDB',
                                  prefixIcon: const Icon(Icons.folder_open_rounded, size: 18),
                                  suffixIcon: IconButton(
                                    tooltip: 'Restaurar padrão Mansão',
                                    icon: const Icon(Icons.restore_rounded, size: 20),
                                    onPressed: () {
                                      _hostBancoController.text = AppConstants.defaultHostFirebird;
                                      _portaBancoController.text = AppConstants.defaultPortaFirebird.toString();
                                      _caminhoBancoController.text = AppConstants.defaultCaminhoBancoFirebird;
                                    },
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Usuário e Senha
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _usuarioBancoController,
                                      decoration: InputDecoration(
                                        labelText: 'Usuário',
                                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _senhaBancoController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Botões de Ação Firebird
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: _isTestando
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.network_check_rounded, size: 17),
                                      label: const Text('Testar Conexão', style: TextStyle(fontSize: 12)),
                                      onPressed: (_isTestando || _isImportando) ? null : _testarConexaoFirebird,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: _isImportando
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.cloud_download_rounded, size: 17),
                                      label: const Text('Trazer Mesas (75)', style: TextStyle(fontSize: 12)),
                                      onPressed: (_isTestando || _isImportando) ? null : _executarImportacaoFirebird,
                                    ),
                                  ),
                                ],
                              ),

                              if (_statusMensagem != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _statusSucesso ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _statusSucesso ? Colors.green.shade300 : Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _statusSucesso ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                        size: 16,
                                        color: _statusSucesso ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _statusMensagem!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusSucesso ? Colors.green.shade800 : Colors.red.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEÇÃO 3: PARÂMETROS DE TEMPO E LIMITES
                        const Text(
                          'Parâmetros de Tolerância e Rotatividade',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tempoAlertaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Alerta (minutos)',
                                  helperText: 'Padrão: 90 min (1h30m)',
                                  prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num <= 0) return 'Informe minutos';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _tempoLimiteController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Limite Máximo (min)',
                                  helperText: 'Padrão: 120 min (2h00m)',
                                  prefixIcon: const Icon(Icons.alarm_on_rounded, color: Colors.red, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalMesasController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Total de Mesas',
                                  prefixIcon: const Icon(Icons.table_restaurant_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num <= 0) return 'Mínimo de 1';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _empresaIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'ID Empresa (ERP)',
                                  prefixIcon: const Icon(Icons.business_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

              const Divider(height: 16),

              // Botões inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
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
