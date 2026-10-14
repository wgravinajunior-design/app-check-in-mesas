import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/barcode_parser.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';
import '../../domain/repositories/ingresso_repository.dart';
import '../cubits/comanda/comanda_cubit.dart';
import '../cubits/config/config_cubit.dart';
import '../cubits/config/config_state.dart';
import '../cubits/mesa/mesa_cubit.dart';
import '../cubits/mesa/mesa_state.dart';
import '../widgets/camera_scanner_dialog.dart';
import '../widgets/check_in_dialog.dart';
import '../widgets/check_out_dialog.dart';
import '../widgets/comanda_tab_view.dart';
import '../widgets/config_dialog.dart';
import '../widgets/mesa_card_widget.dart';
import '../widgets/metricas_salao_dialog.dart';
import '../widgets/stats_summary_widget.dart';
import '../widgets/transferir_mesa_dialog.dart';
import 'historico_ingressos_screen.dart';

class MesaGridScreen extends StatefulWidget {
  final IngressoRepository ingressoRepository;

  const MesaGridScreen({
    super.key,
    required this.ingressoRepository,
  });

  @override
  State<MesaGridScreen> createState() => _MesaGridScreenState();
}

class _MesaGridScreenState extends State<MesaGridScreen> {
  String _filtroAtivo = 'TODAS';
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';
  StreamSubscription<List<Mesa>>? _mesasLiberadasSub;
  DateTime? _ultimoPopupLiberadas;
  String? _ultimasMesasPopup;

  @override
  void initState() {
    super.initState();
    _mesasLiberadasSub = context.read<MesaCubit>().mesasLiberadasStream.listen((mesasLiberadas) {
      if (!mounted || mesasLiberadas.isEmpty) return;
      _mostrarPopupMesasLiberadas(mesasLiberadas);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checarAtualizacao(silencioso: true);
    });
  }

  @override
  void dispose() {
    _mesasLiberadasSub?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _mostrarPopupMesasLiberadas(List<Mesa> liberadas) {
    if (!mounted || liberadas.isEmpty) return;

    final chaveAtual = liberadas.map((m) => '${m.id}_${m.codigo}').join(',');
    final agora = DateTime.now();
    if (_ultimasMesasPopup == chaveAtual &&
        _ultimoPopupLiberadas != null &&
        agora.difference(_ultimoPopupLiberadas!).inSeconds < 5) {
      return;
    }
    _ultimasMesasPopup = chaveAtual;
    _ultimoPopupLiberadas = agora;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14532D).withOpacity(0.5) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                liberadas.length == 1 ? 'Mesa Liberada!' : 'Mesas Liberadas!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              liberadas.length == 1
                  ? 'A mesa abaixo saiu do status ocupada e agora está livre:'
                  : 'As mesas abaixo saíram do status ocupada e agora estão livres:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liberadas.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14532D).withOpacity(0.3) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF22C55E) : const Color(0xFF81C784),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_restaurant_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.nomeExibicao,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK, Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _checarAtualizacao({bool silencioso = false}) async {
    final info = await AppUpdateService.verificarAtualizacao();
    if (!mounted) return;

    if (info.temAtualizacao) {
      AppUpdateService.exibirDialogAtualizacao(context, info);
    } else if (info.erroConexao && !silencioso) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Falha ao checar atualizações: ${info.mensagemErro ?? "Erro de conexão"}'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade900,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (!silencioso) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('CheckMesa já está na versão mais recente (v${info.versaoAtual})!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _escanearMesaComCamera() async {
    final codigoLido = await CameraScannerDialog.abrirLeitor(
      context,
      titulo: 'Escanear Mesa',
      subtitulo: 'Aponte a câmera para o QR Code ou Código da Mesa',
    );

    if (codigoLido == null || !mounted) return;

    final mesaState = context.read<MesaCubit>().state;
    if (mesaState is MesaLoaded) {
      final codFormatado = BarcodeParser.formatarCodigoTresDigitos(codigoLido);
      final mesaEncontrada = mesaState.mesas.cast<Mesa?>().firstWhere(
        (m) =>
            m != null &&
            (m.codigo == codFormatado ||
                m.codigo == codigoLido ||
                int.tryParse(m.codigo) == int.tryParse(codigoLido)),
        orElse: () => null,
      );

      _buscaController.text = codigoLido;
      setState(() {
        _termoBusca = codigoLido;
      });

      if (mesaEncontrada != null) {
        _tratarCliqueMesa(context, mesaEncontrada, mesaState.mesas);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa "$codigoLido" não encontrada no salão.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigCubit, ConfigState>(
      listener: (context, state) {
        if (state is ConfigLoaded) {
          context.read<MesaCubit>().definirConfiguracao(state.config);
          context.read<ComandaCubit>().definirConfiguracao(state.config);
        }
      },
      child: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, configState) {
          final config = configState is ConfigLoaded
              ? configState.config
              : const AppConfig();
          final bool sincronizarMesas = config.sincronizarMesas;
          final bool sincronizarComandas = config.sincronizarComandas;
          final bool mostrarAmbasAbas = sincronizarMesas && sincronizarComandas;

          Widget bodyContent;
          if (mostrarAmbasAbas) {
            bodyContent = TabBarView(
              children: [
                _buildMesasView(config),
                const ComandaTabView(),
              ],
            );
          } else if (sincronizarMesas) {
            bodyContent = _buildMesasView(config);
          } else if (sincronizarComandas) {
            bodyContent = const ComandaTabView();
          } else {
            bodyContent = Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_disabled_rounded, size: 64, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum módulo selecionado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Habilite "Sincronizar Mesas" ou "Sincronizar Comandas" nas configurações para monitorar o salão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _abrirConfiguracoes(context),
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Abrir Configurações'),
                    ),
                  ],
                ),
              ),
            );
          }

          final Widget scaffoldContent = Scaffold(
            appBar: AppBar(
              titleSpacing: 8,
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_rounded, size: 20, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'CheckMesa',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              bottom: mostrarAmbasAbas
                  ? const TabBar(
                      indicatorColor: Colors.amber,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.table_restaurant_rounded, size: 19),
                          text: 'Mesas',
                        ),
                        Tab(
                          icon: Icon(Icons.receipt_long_rounded, size: 19),
                          text: 'Comandas',
                        ),
                      ],
                    )
                  : null,
              actions: [
                // Alternar Modo Escuro
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: config.modoEscuro
                      ? 'Alternar para Modo Claro'
                      : 'Alternar para Modo Escuro',
                  icon: Icon(
                    config.modoEscuro
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    final novaConfig =
                        config.copyWith(modoEscuro: !config.modoEscuro);
                    context.read<ConfigCubit>().salvarConfiguracoes(novaConfig);
                  },
                ),


                // Métricas do Salão
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Métricas e Giro do Salão',
                  icon: const Icon(Icons.analytics_outlined, size: 20),
                  onPressed: () {
                    final mesaState = context.read<MesaCubit>().state;
                    if (mesaState is MesaLoaded) {
                      showDialog(
                        context: context,
                        builder: (_) => MetricasSalaoDialog(mesas: mesaState.mesas),
                      );
                    }
                  },
                ),

                // Verificar Atualização
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Verificar Atualização (APK)',
                  icon: const Icon(Icons.system_update_alt_rounded, size: 20),
                  onPressed: () => _checarAtualizacao(silencioso: false),
                ),

                // Configurações
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Configurações e Conexão',
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => _abrirConfiguracoes(context),
                ),

                // Recarregar Manual
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Recarregar Dados (Auto a cada 2 min)',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () {
                    if (sincronizarMesas) {
                      context.read<MesaCubit>().carregarMesas(config: config);
                    }
                    if (sincronizarComandas) {
                      context.read<ComandaCubit>().carregarComandas(config: config);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Atualizando dados da retaguarda...'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: bodyContent,
          );

          if (mostrarAmbasAbas) {
            return DefaultTabController(
              length: 2,
              child: scaffoldContent,
            );
          }

          return scaffoldContent;
        },
      ),
    );
  }

  Widget _buildMesasView(AppConfig config) {
    return BlocConsumer<MesaCubit, MesaState>(
      listener: (context, state) {
        if (state is MesaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensagem),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MesaLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando mesas e status de permanência...',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        if (state is MesaLoaded) {
          final mesasFiltradas = _filtrarMesas(state.mesas);

          return Column(
            children: [
              StatsSummaryWidget(
                state: state,
                filtroAtivo: _filtroAtivo,
                onSelecionarFiltro: (novoFiltro) {
                  setState(() {
                    _filtroAtivo = novoFiltro;
                  });
                },
              ),

              // Barra de Busca Rápida de Mesas
              _buildBarraBusca(),

              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: mesasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_off_rounded,
                                size: 44, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _termoBusca.isNotEmpty
                                  ? 'Nenhuma mesa encontrada com "$_termoBusca".'
                                  : 'Nenhuma mesa encontrada para o filtro selecionado.',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          if (constraints.maxWidth > 1400) {
                            crossAxisCount = 8;
                          } else if (constraints.maxWidth > 1100) {
                            crossAxisCount = 6;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 550) {
                            crossAxisCount = 3;
                          } else {
                            crossAxisCount = 2;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: constraints.maxWidth > 600 ? 1.05 : 0.88,
                            ),
                            itemCount: mesasFiltradas.length,
                            itemBuilder: (context, index) {
                              final mesa = mesasFiltradas[index];
                              return MesaCardWidget(
                                mesa: mesa,
                                config: config,
                                onTap: () => _tratarCliqueMesa(
                                    context, mesa, state.mesas),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return const Center(
          child: Text('Iniciando sistema CheckMesa...'),
        );
      },
    );
  }

  Widget _buildBarraBusca() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: TextField(
        controller: _buscaController,
        decoration: InputDecoration(
          hintText: 'Buscar ou escanear número da mesa...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_termoBusca.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() {
                      _termoBusca = '';
                    });
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
                tooltip: 'Escanear mesa com a câmera',
                onPressed: _escanearMesaComCamera,
              ),
            ],
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : Theme.of(context).cardColor,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              width: 1.5,
            ),
          ),
        ),
        onChanged: (val) {
          setState(() {
            _termoBusca = val;
          });
        },
      ),
    );
  }

  List<Mesa> _filtrarMesas(List<Mesa> todas) {
    List<Mesa> lista = todas;
    if (_termoBusca.isNotEmpty) {
      final termo = _termoBusca.toLowerCase().trim();
      lista = lista.where((m) {
        return m.codigo.toLowerCase().contains(termo) ||
            m.nomeExibicao.toLowerCase().contains(termo);
      }).toList();
    }

    switch (_filtroAtivo) {
      case 'LIVRES':
        return lista.where((m) => !m.isOcupada).toList();
      case 'NORMAL':
        return lista
            .where((m) =>
                m.isOcupada && m.statusPermanencia == StatusPermanencia.normal)
            .toList();
      case 'ALERTA':
        return lista
            .where((m) =>
                m.isOcupada &&
                m.statusPermanencia == StatusPermanencia.alertaTolerancia)
            .toList();
      case 'EXCEDIDAS':
        return lista
            .where((m) =>
                m.isOcupada &&
                m.statusPermanencia == StatusPermanencia.limiteExcedido)
            .toList();
      default:
        return lista;
    }
  }

  void _tratarCliqueMesa(BuildContext context, Mesa mesa, List<Mesa> todasMesas) {
    if (!mesa.isOcupada) {
      showDialog(
        context: context,
        builder: (_) => CheckInDialog(
          mesa: mesa,
          onConfirmar: (obs) {
            context.read<MesaCubit>().realizarCheckIn(
                  mesa: mesa,
                  observacao: obs,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Check-in registrado na ${mesa.nomeExibicao}!'),
                backgroundColor: AppTheme.corMesaLivre,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      );
    } else {
      final configState = context.read<ConfigCubit>().state;
      final bool permitirTransferir = configState is ConfigLoaded
          ? configState.config.permitirTransferirMesas
          : true;

      if (!permitirTransferir) {
        _abrirCheckOutDialog(context, mesa);
      } else {
        // Exibe opções: Check-out ou Transferir Mesa
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            final mesasLivres =
                todasMesas.where((m) => !m.isOcupada).toList();
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              mesa.statusPermanencia.corPrimaria,
                          foregroundColor: Colors.white,
                          child: Text(mesa.codigo,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mesa.nomeExibicao,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                  'Tempo ativo: ${TimeFormatter.formatDuration(mesa.tempoDecorrido)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          mesa.statusPermanencia.corPrimaria,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.red),
                      ),
                      title: const Text('Realizar Check-out (Encerrar)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text(
                          'Libera a mesa e salva encerramento em TB_INGRESSO',
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _abrirCheckOutDialog(context, mesa);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: Color(0xFF0284C7)),
                      ),
                      title: const Text('Transferir para Outra Mesa',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                          'Remaneja clientes para mesa livre mantendo o tempo ativo (${mesasLivres.length} livres)',
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _abrirTransferirDialog(context, mesa, mesasLivres);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  void _abrirCheckOutDialog(BuildContext context, Mesa mesa) {
    showDialog(
      context: context,
      builder: (_) => CheckOutDialog(
        mesa: mesa,
        onConfirmar: () {
          context.read<MesaCubit>().realizarCheckOut(mesa: mesa);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check Out efetuado!'),
              backgroundColor: Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _abrirTransferirDialog(
      BuildContext context, Mesa mesa, List<Mesa> mesasLivres) {
    showDialog(
      context: context,
      builder: (_) => TransferirMesaDialog(
        mesaOrigem: mesa,
        mesasLivres: mesasLivres,
        onConfirmar: (mesaDestino, motivo) {
          context.read<MesaCubit>().transferirMesa(
                mesaOrigem: mesa,
                mesaDestino: mesaDestino,
                motivo: motivo,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cliente transferido da ${mesa.nomeExibicao} para a ${mesaDestino.nomeExibicao} com sucesso!'),
              backgroundColor: const Color(0xFF0284C7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _abrirConfiguracoes(BuildContext context) {
    final configState = context.read<ConfigCubit>().state;
    final configAtual = configState is ConfigLoaded
        ? configState.config
        : const AppConfig();

    showDialog(
      context: context,
      builder: (_) => ConfigDialog(
        configAtual: configAtual,
        onSalvar: (novaConfig) {
          context.read<ConfigCubit>().salvarConfiguracoes(novaConfig);
          context.read<MesaCubit>().definirConfiguracao(novaConfig);
          context.read<MesaCubit>().carregarMesas(config: novaConfig);
          context.read<ComandaCubit>().definirConfiguracao(novaConfig);
          if (novaConfig.sincronizarComandas) {
            context.read<ComandaCubit>().carregarComandas(config: novaConfig);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configurações atualizadas com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onTestarConexao: (config) {
          return context.read<MesaCubit>().testarConexaoFirebird(config);
        },
        onImportarMesasFirebird: (config) async {
          final total =
              await context.read<MesaCubit>().importarMesasDoFirebird(config);
          final configAtualizada = config.copyWith(totalMesas: total);
          if (context.mounted) {
            context.read<ConfigCubit>().salvarConfiguracoes(configAtualizada);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '$total mesas importadas com sucesso da base de dados!'),
                backgroundColor: AppTheme.corMesaLivre,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return total;
        },
        onAbrirAuditoria: () => _abrirHistorico(context),
      ),
    );
  }

  void _abrirHistorico(BuildContext context) {
    final configState = context.read<ConfigCubit>().state;
    final int empresaId =
        configState is ConfigLoaded ? configState.config.empresaId : 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoricoIngressosScreen(
          ingressoRepository: widget.ingressoRepository,
          empresaId: empresaId,
        ),
      ),
    );
  }
}
