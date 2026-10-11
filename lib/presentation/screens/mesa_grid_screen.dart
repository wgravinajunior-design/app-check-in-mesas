import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';
import '../../domain/repositories/ingresso_repository.dart';
import '../cubits/config/config_cubit.dart';
import '../cubits/config/config_state.dart';
import '../cubits/mesa/mesa_cubit.dart';
import '../cubits/mesa/mesa_state.dart';
import '../widgets/check_in_dialog.dart';
import '../widgets/check_out_dialog.dart';
import '../widgets/config_dialog.dart';
import '../widgets/mesa_card_widget.dart';
import '../widgets/stats_summary_widget.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checarAtualizacao(silencioso: true);
    });
  }

  Future<void> _checarAtualizacao({bool silencioso = false}) async {
    final info = await AppUpdateService.verificarAtualizacao();
    if (!mounted) return;

    if (info.temAtualizacao) {
      AppUpdateService.exibirDialogAtualizacao(context, info);
    } else if (!silencioso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seu aplicativo já está na versão mais recente!'),
          behavior: SnackBarBehavior.floating,
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
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 14,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_rounded, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Gestão de Mesas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Verificar Atualização (APK)',
              icon: const Icon(Icons.system_update_alt_rounded, size: 22),
              onPressed: () => _checarAtualizacao(silencioso: false),
            ),
            IconButton(
              tooltip: 'Configurações e Conexão Firebird',
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: () => _abrirConfiguracoes(context),
            ),
            IconButton(
              tooltip: 'Recarregar',
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: () {
                final configState = context.read<ConfigCubit>().state;
                final config = configState is ConfigLoaded ? configState.config : null;
                context.read<MesaCubit>().carregarMesas(config: config);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: BlocConsumer<MesaCubit, MesaState>(
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
                                  'Nenhuma mesa encontrada para o filtro selecionado.',
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
                                    onTap: () => _tratarCliqueMesa(context, mesa),
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
              child: Text('Iniciando sistema de gestão de mesas...'),
            );
          },
        ),
      ),
    );
  }

  List<Mesa> _filtrarMesas(List<Mesa> todas) {
    switch (_filtroAtivo) {
      case 'LIVRES':
        return todas.where((m) => !m.isOcupada).toList();
      case 'NORMAL':
        return todas
            .where((m) =>
                m.isOcupada && m.statusPermanencia == StatusPermanencia.normal)
            .toList();
      case 'ALERTA':
        return todas
            .where((m) =>
                m.isOcupada &&
                m.statusPermanencia == StatusPermanencia.alertaTolerancia)
            .toList();
      case 'EXCEDIDAS':
        return todas
            .where((m) =>
                m.isOcupada &&
                m.statusPermanencia == StatusPermanencia.limiteExcedido)
            .toList();
      default:
        return todas;
    }
  }

  void _tratarCliqueMesa(BuildContext context, Mesa mesa) {
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
          final total = await context.read<MesaCubit>().importarMesasDoFirebird(config);
          final configAtualizada = config.copyWith(totalMesas: total);
          if (context.mounted) {
            context.read<ConfigCubit>().salvarConfiguracoes(configAtualizada);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$total mesas importadas com sucesso da base de dados!'),
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
