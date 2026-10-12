import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checarAtualizacao(silencioso: true);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _checarAtualizacao({bool silencioso = false}) async {
    final info = await AppUpdateService.verificarAtualizacao();
    if (!mounted) return;

    if (info.temAtualizacao) {
      AppUpdateService.exibirDialogAtualizacao(context, info);
    } else if (info.erroConexao && !silencioso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao checar atualizações: ${info.mensagemErro ?? "Erro de conexão"}'),
          backgroundColor: Colors.orange.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!silencioso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CheckMesa já está na versão mais recente (v${info.versaoAtual})!'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'BAIXAR APK',
            textColor: Colors.amber,
            onPressed: () {
              AppUpdateService.exibirDialogAtualizacao(context, info);
            },
          ),
        ),
      );
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
                _buildMesasView(),
                const ComandaTabView(),
              ],
            );
          } else if (sincronizarMesas) {
            bodyContent = _buildMesasView();
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

                // Recarregar
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  tooltip: 'Recarregar Dados',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () {
                    if (sincronizarMesas) {
                      context.read<MesaCubit>().carregarMesas(config: config);
                    }
                    if (sincronizarComandas) {
                      context.read<ComandaCubit>().carregarComandas(config: config);
                    }
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

  Widget _buildMesasView() {
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

              const Divider(height: 1, thickness: 1),
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
                              childAspectRatio: 1.15,
                            ),
                            itemCount: mesasFiltradas.length,
                            itemBuilder: (context, index) {
                              final mesa = mesasFiltradas[index];
                              return MesaCardWidget(
                                mesa: mesa,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: TextField(
        controller: _buscaController,
        decoration: InputDecoration(
          hintText: 'Buscar por número ou identificador da mesa...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _termoBusca.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() {
                      _termoBusca = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
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
            SnackBar(
              content: Text(
                  'Check-out efetuado! ${mesa.nomeExibicao} liberada e gravada na TB_INGRESSO.'),
              backgroundColor: const Color(0xFF0F172A),
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
