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
  late TextEditingController _tempoVerdeController;
  late TextEditingController _tempoAmareloController;
  late TextEditingController _tempoVermelhoController;
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
  bool _permitirTransferirMesas = true;
  bool _alertaSonoro = true;
  bool _modoEscuro = false;
  bool _sincronizarMesas = true;
  bool _sincronizarComandas = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _permitirTransferirMesas = widget.configAtual.permitirTransferirMesas;
    _alertaSonoro = widget.configAtual.alertaSonoro;
    _modoEscuro = widget.configAtual.modoEscuro;
    _sincronizarMesas = widget.configAtual.sincronizarMesas;
    _sincronizarComandas = widget.configAtual.sincronizarComandas;

    _tempoVerdeController = TextEditingController(
      text: widget.configAtual.tempoVerdeMinutos.toString(),
    );
    _tempoAmareloController = TextEditingController(
      text: widget.configAtual.tempoAmareloMinutos.toString(),
    );
    _tempoVermelhoController = TextEditingController(
      text: widget.configAtual.tempoVermelhoMinutos.toString(),
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
    _tempoVerdeController.dispose();
    _tempoAmareloController.dispose();
    _tempoVermelhoController.dispose();
    _empresaIdController.dispose();
    _hostBancoController.dispose();
    _portaBancoController.dispose();
    _caminhoBancoController.dispose();
    _usuarioBancoController.dispose();
    _senhaBancoController.dispose();
    super.dispose();
  }

  AppConfig _obterConfiguracaoForm() {
    final verde = int.tryParse(_tempoVerdeController.text) ?? widget.configAtual.tempoVerdeMinutos;
    final amarelo = int.tryParse(_tempoAmareloController.text) ?? widget.configAtual.tempoAmareloMinutos;
    final vermelho = int.tryParse(_tempoVermelhoController.text) ?? widget.configAtual.tempoVermelhoMinutos;

    return widget.configAtual.copyWith(
      tempoVerdeMinutos: verde,
      tempoAmareloMinutos: amarelo,
      tempoVermelhoMinutos: vermelho,
      tempoAlertaMinutos: amarelo,
      tempoLimiteMinutos: vermelho,
      empresaId: int.tryParse(_empresaIdController.text) ?? widget.configAtual.empresaId,
      hostBanco: _hostBancoController.text.trim(),
      portaBanco: int.tryParse(_portaBancoController.text) ?? 3060,
      caminhoBanco: _caminhoBancoController.text.trim(),
      usuarioBanco: _usuarioBancoController.text.trim(),
      senhaBanco: _senhaBancoController.text.trim(),
      permitirTransferirMesas: _permitirTransferirMesas,
      alertaSonoro: _alertaSonoro,
      modoEscuro: _modoEscuro,
      sincronizarMesas: _sincronizarMesas,
      sincronizarComandas: _sincronizarComandas,
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

                        // SEÇÃO: TEMPO SEM PEDIR NADA (CONFIGURAÇÃO SEMAFÓRICA)
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.timer_outlined, color: Color(0xFF0D47A1), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tempo Sem Pedir Nada (Cores da Mesa)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Configuração de minutos para alternar as cores: Verde, Amarelo e Vermelho',
                                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // 3 CAMPOS PARA O TEMPO: VERDE, AMARELO E VERMELHO
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isNarrow = constraints.maxWidth < 420;

                                  final campoVerde = TextFormField(
                                    controller: _tempoVerdeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Verde (minutos)',
                                      hintText: '30',
                                      prefixIcon: const Icon(Icons.circle, color: Color(0xFF16A34A), size: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    ),
                                    validator: (val) {
                                      final num = int.tryParse(val ?? '');
                                      if (num == null || num <= 0) return 'Informe minutos';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  );

                                  final campoAmarelo = TextFormField(
                                    controller: _tempoAmareloController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Amarelo (minutos)',
                                      hintText: '60',
                                      prefixIcon: const Icon(Icons.circle, color: Color(0xFFD97706), size: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    ),
                                    validator: (val) {
                                      final num = int.tryParse(val ?? '');
                                      final verde = int.tryParse(_tempoVerdeController.text);
                                      if (num == null || num <= 0) return 'Informe minutos';
                                      if (verde != null && num <= verde) {
                                        return 'Maior que Verde';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  );

                                  final campoVermelho = TextFormField(
                                    controller: _tempoVermelhoController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Vermelho (minutos)',
                                      hintText: '90',
                                      prefixIcon: const Icon(Icons.circle, color: Color(0xFFDC2626), size: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    ),
                                    validator: (val) {
                                      final num = int.tryParse(val ?? '');
                                      final amarelo = int.tryParse(_tempoAmareloController.text);
                                      if (num == null || num <= 0) return 'Informe minutos';
                                      if (amarelo != null && num <= amarelo) {
                                        return 'Maior que Amarelo';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      children: [
                                        campoVerde,
                                        const SizedBox(height: 8),
                                        campoAmarelo,
                                        const SizedBox(height: 8),
                                        campoVermelho,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: campoVerde),
                                      const SizedBox(width: 8),
                                      Expanded(child: campoAmarelo),
                                      const SizedBox(width: 8),
                                      Expanded(child: campoVermelho),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              // Preview dinâmico do Semáforo
                              Builder(
                                builder: (context) {
                                  final v = int.tryParse(_tempoVerdeController.text) ?? 30;
                                  final a = int.tryParse(_tempoAmareloController.text) ?? 60;
                                  final r = int.tryParse(_tempoVermelhoController.text) ?? 90;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildFaixaLegenda('Verde', '0 a ${v}m', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        _buildFaixaLegenda('Amarelo', '${v + 1} a ${a}m', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        _buildFaixaLegenda('Vermelho', '> ${a}m (limite ${r}m)', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

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

                        const SizedBox(height: 12),

                        // Card 3: Operação do Salão & Preferências
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Operação do Salão & Preferências',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Switch: Permitir Transferir Mesas
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0284C7)),
                                title: const Text(
                                  'Permitir Transferir Mesas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Habilita o botão para remanejar clientes entre mesas mantendo o tempo ativo',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                value: _permitirTransferirMesas,
                                onChanged: (val) {
                                  setState(() {
                                    _permitirTransferirMesas = val;
                                  });
                                },
                              ),
                              const Divider(height: 8),

                              // Switch: Alerta Sonoro e Vibração
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: const Icon(Icons.volume_up_rounded, color: Colors.amber),
                                title: const Text(
                                  'Alerta Sonoro e Vibração',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Emite bip e vibração quando mesas atingem tolerância ou limite',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                value: _alertaSonoro,
                                onChanged: (val) {
                                  setState(() {
                                    _alertaSonoro = val;
                                  });
                                },
                              ),
                              const Divider(height: 8),

                              // Switch: Modo Escuro
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: const Icon(Icons.dark_mode_rounded, color: Color(0xFF6366F1)),
                                title: const Text(
                                  'Modo Escuro (Dark Mode)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Interface escura de alto contraste para ambientes noturnos',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                value: _modoEscuro,
                                onChanged: (val) {
                                  setState(() {
                                    _modoEscuro = val;
                                  });
                                },
                              ),
                              const Divider(height: 8),

                              // Switch: Sincronizar Mesas
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: const Icon(Icons.table_restaurant_rounded, color: Color(0xFF0284C7)),
                                title: const Text(
                                  'Sincronizar Mesas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Habilita a aba e o controle de permanência das mesas do salão',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                value: _sincronizarMesas,
                                onChanged: (val) {
                                  setState(() {
                                    _sincronizarMesas = val;
                                  });
                                },
                              ),
                              const Divider(height: 8),

                              // Switch: Sincronizar Comandas
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                secondary: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D9488)),
                                title: const Text(
                                  'Sincronizar Comandas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Habilita a aba e o controle de permanência de comandas individuais',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                value: _sincronizarComandas,
                                onChanged: (val) {
                                  setState(() {
                                    _sincronizarComandas = val;
                                  });
                                },
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

  Widget _buildFaixaLegenda(String titulo, String intervalo, Color corTexto, Color corFundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: corTexto.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: corTexto,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: corTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            intervalo,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
        ],
      ),
    );
  }
}
