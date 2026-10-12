import 'package:flutter/material.dart';
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
  late TextEditingController _empresaIdController;
  late TextEditingController _hostBancoController;
  late TextEditingController _portaBancoController;
  late TextEditingController _caminhoBancoController;
  late TextEditingController _usuarioBancoController;
  late TextEditingController _senhaBancoController;

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
    _empresaIdController = TextEditingController(
      text: widget.configAtual.empresaId.toString(),
    );

    // Valores por máquina/ambiente (sem valores prefixados fixos)
    _hostBancoController = TextEditingController(
      text: widget.configAtual.hostBanco,
    );
    _portaBancoController = TextEditingController(
      text: widget.configAtual.portaBanco > 0 ? widget.configAtual.portaBanco.toString() : '3060',
    );
    _caminhoBancoController = TextEditingController(
      text: widget.configAtual.caminhoBanco,
    );
    _usuarioBancoController = TextEditingController(
      text: widget.configAtual.usuarioBanco.isNotEmpty ? widget.configAtual.usuarioBanco : 'SYSDBA',
    );
    _senhaBancoController = TextEditingController(
      text: widget.configAtual.senhaBanco.isNotEmpty ? widget.configAtual.senhaBanco : 'masterkey',
    );
  }

  @override
  void dispose() {
    _tempoAlertaController.dispose();
    _tempoLimiteController.dispose();
    _empresaIdController.dispose();
    _hostBancoController.dispose();
    _portaBancoController.dispose();
    _caminhoBancoController.dispose();
    _usuarioBancoController.dispose();
    _senhaBancoController.dispose();
    super.dispose();
  }

  AppConfig _obterConfiguracaoForm() {
    return widget.configAtual.copyWith(
      tempoAlertaMinutos: int.tryParse(_tempoAlertaController.text) ?? widget.configAtual.tempoAlertaMinutos,
      tempoLimiteMinutos: int.tryParse(_tempoLimiteController.text) ?? widget.configAtual.tempoLimiteMinutos,
      empresaId: int.tryParse(_empresaIdController.text) ?? widget.configAtual.empresaId,
      hostBanco: _hostBancoController.text.trim(),
      portaBanco: int.tryParse(_portaBancoController.text) ?? 3060,
      caminhoBanco: _caminhoBancoController.text.trim(),
      usuarioBanco: _usuarioBancoController.text.trim(),
      senhaBanco: _senhaBancoController.text.trim(),
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
          _statusMensagem = '$total mesas sincronizadas com sucesso do ERP!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImportando = false;
          _statusSucesso = false;
          _statusMensagem = 'Falha ao buscar mesas: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTablet = media.size.width >= 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: isTablet ? 32 : 18,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 640 : double.infinity,
          maxHeight: media.size.height * 0.90,
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho da Janela
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_outlined, color: Color(0xFF0D47A1), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Configurações',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Conteúdo Rolável Responsivo
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SEÇÃO: AUDITORIA (TB_INGRESSO)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D47A1), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Auditoria (TB_INGRESSO)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Histórico de check-in, check-out e rotatividade.',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                label: const Text('Auditoria', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onAbrirAuditoria();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // SEÇÃO: CONEXÃO (APENAS "CONEXÃO")
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storage_rounded, color: Color(0xFF1565C0), size: 19),
                                  SizedBox(width: 8),
                                  Text(
                                    'Conexão',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Host e Porta bem alinhados
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: TextFormField(
                                      controller: _hostBancoController,
                                      decoration: InputDecoration(
                                        labelText: 'Host / IP Servidor',
                                        hintText: 'Ex.: 192.168.1.100',
                                        prefixIcon: const Icon(Icons.dns_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _portaBancoController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Porta',
                                        hintText: '3060',
                                        prefixIcon: const Icon(Icons.lan_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Caminho da Base de Dados
                              TextFormField(
                                controller: _caminhoBancoController,
                                decoration: InputDecoration(
                                  labelText: 'Caminho da Base (.FDB)',
                                  hintText: r'Ex.: C:\Sistemas\DADOS.FDB',
                                  prefixIcon: const Icon(Icons.folder_open_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Usuário e Senha
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _usuarioBancoController,
                                      decoration: InputDecoration(
                                        labelText: 'Usuário',
                                        hintText: 'SYSDBA',
                                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Botões de Ação da Conexão
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: _isTestando
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.network_check_rounded, size: 17),
                                      label: const Text('Testar Conexão', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: (_isTestando || _isImportando) ? null : _testarConexaoFirebird,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: _isImportando
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.cloud_download_rounded, size: 17),
                                      label: const Text('Trazer Mesas (ERP)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: (_isTestando || _isImportando) ? null : _executarImportacaoFirebird,
                                    ),
                                  ),
                                ],
                              ),

                              // Mensagem de Feedback de Conexão
                              if (_statusMensagem != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
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
                                      const SizedBox(width: 8),
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

                        const SizedBox(height: 14),

                        // SEÇÃO: PARÂMETROS DE TOLERÂNCIA E ROTATIVIDADE
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.timer_outlined, color: Color(0xFF0D47A1), size: 19),
                                  SizedBox(width: 8),
                                  Text(
                                    'Parâmetros de Tolerância',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Tempos de Alerta e Limite
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _tempoAlertaController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Alerta (minutos)',
                                        hintText: '90',
                                        prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                        hintText: '120',
                                        prefixIcon: const Icon(Icons.alarm_on_rounded, color: Colors.red, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

                              // Empresa ID (sem campo de quantidade de mesas, pois busca do ERP)
                              TextFormField(
                                controller: _empresaIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Código da Empresa no ERP',
                                  hintText: '1',
                                  prefixIcon: const Icon(Icons.business_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 14),

              // Botões Inferiores Salvar / Cancelar
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final novaConfig = _obterConfiguracaoForm();
                        widget.onSalvar(novaConfig);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Salvar Configurações', style: TextStyle(fontWeight: FontWeight.bold)),
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
