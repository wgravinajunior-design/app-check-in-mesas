import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/barcode_parser.dart';
import '../../domain/entities/comanda.dart';
import '../../domain/entities/status_permanencia.dart';
import '../cubits/comanda/comanda_cubit.dart';
import '../cubits/comanda/comanda_state.dart';
import 'camera_scanner_dialog.dart';
import 'check_in_comanda_dialog.dart';
import 'check_out_comanda_dialog.dart';
import 'comanda_card_widget.dart';

class ComandaTabView extends StatefulWidget {
  const ComandaTabView({super.key});

  @override
  State<ComandaTabView> createState() => _ComandaTabViewState();
}

class _ComandaTabViewState extends State<ComandaTabView> {
  String _filtroAtivo = 'TODAS';
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ComandaCubit, ComandaState>(
      listener: (context, state) {
        if (state is ComandaError) {
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
        if (state is ComandaLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando comandas e status de permanência...',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        if (state is ComandaLoaded) {
          final comandasFiltradas = _filtrarComandas(state.comandas);

          return Column(
            children: [
              // Barra de Filtros / Estatísticas de Comandas
              _buildFiltrosBar(state),

              // Barra de Busca Rápida
              _buildBarraBusca(),

              const Divider(height: 1, thickness: 1),

              Expanded(
                child: comandasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_off_rounded,
                                size: 44, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _termoBusca.isNotEmpty
                                  ? 'Nenhuma comanda encontrada com "$_termoBusca".'
                                  : 'Nenhuma comanda para o filtro selecionado.',
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
                            itemCount: comandasFiltradas.length,
                            itemBuilder: (context, index) {
                              final comanda = comandasFiltradas[index];
                              return ComandaCardWidget(
                                comanda: comanda,
                                onTap: () => _tratarCliqueComanda(context, comanda),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return const Center(child: Text('Iniciando módulo de comandas...'));
      },
    );
  }

  Widget _buildFiltrosBar(ComandaLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFiltroChip('TODAS', 'Todas (${state.totalComandas})', Icons.all_inbox_rounded, Colors.blueGrey),
            const SizedBox(width: 6),
            _buildFiltroChip('LIVRES', 'Livres (${state.comandasLivres})', Icons.check_circle_outline_rounded, AppTheme.corMesaLivre),
            const SizedBox(width: 6),
            _buildFiltroChip('OCUPADAS', 'Ocupadas (${state.comandasOcupadas})', Icons.receipt_long_rounded, AppTheme.corMesaNormal),
            const SizedBox(width: 6),
            _buildFiltroChip(
              'ALERTA',
              'Alerta (${state.comandas.where((c) => c.isOcupada && c.statusPermanencia == StatusPermanencia.alertaTolerancia).length})',
              Icons.warning_amber_rounded,
              AppTheme.corMesaAlerta,
            ),
            const SizedBox(width: 6),
            _buildFiltroChip(
              'EXCEDIDAS',
              'Excedidas (${state.comandas.where((c) => c.isOcupada && c.statusPermanencia == StatusPermanencia.limiteExcedido).length})',
              Icons.alarm_on_rounded,
              AppTheme.corMesaExcedida,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String filtro, String label, IconData icone, Color cor) {
    final bool selecionado = _filtroAtivo == filtro;
    return FilterChip(
      selected: selecionado,
      showCheckmark: false,
      avatar: Icon(icone, size: 16, color: selecionado ? Colors.white : cor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: selecionado ? Colors.white : cor,
        ),
      ),
      backgroundColor: cor.withValues(alpha: 0.1),
      selectedColor: cor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selecionado ? cor : cor.withValues(alpha: 0.3)),
      ),
      onSelected: (_) {
        setState(() {
          _filtroAtivo = filtro;
        });
      },
    );
  }

  Future<void> _escanearComandaComCamera() async {
    final codigoLido = await CameraScannerDialog.abrirLeitor(
      context,
      titulo: 'Escanear Comanda',
      subtitulo: 'Aponte a câmera para o QR Code ou Código da Comanda',
    );

    if (codigoLido == null || !mounted) return;

    final state = context.read<ComandaCubit>().state;
    if (state is ComandaLoaded) {
      final codFormatado = BarcodeParser.formatarCodigoTresDigitos(codigoLido);
      final comandaEncontrada = state.comandas.cast<Comanda?>().firstWhere(
        (c) =>
            c != null &&
            (c.codigo == codFormatado ||
                c.codigo == codigoLido ||
                int.tryParse(c.codigo) == int.tryParse(codigoLido)),
        orElse: () => null,
      );

      _buscaController.text = codigoLido;
      setState(() {
        _termoBusca = codigoLido;
      });

      if (comandaEncontrada != null) {
        _tratarCliqueComanda(context, comandaEncontrada);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comanda "$codigoLido" não encontrada no sistema.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBarraBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: TextField(
        controller: _buscaController,
        decoration: InputDecoration(
          hintText: 'Buscar ou escanear número da comanda...',
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
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0D9488)),
                tooltip: 'Escanear comanda com a câmera',
                onPressed: _escanearComandaComCamera,
              ),
            ],
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  List<Comanda> _filtrarComandas(List<Comanda> todas) {
    List<Comanda> lista = todas;
    if (_termoBusca.isNotEmpty) {
      final termo = _termoBusca.toLowerCase().trim();
      lista = lista.where((c) {
        return c.codigo.toLowerCase().contains(termo) ||
            c.nomeExibicao.toLowerCase().contains(termo);
      }).toList();
    }

    switch (_filtroAtivo) {
      case 'LIVRES':
        return lista.where((c) => !c.isOcupada).toList();
      case 'OCUPADAS':
        return lista.where((c) => c.isOcupada).toList();
      case 'ALERTA':
        return lista
            .where((c) =>
                c.isOcupada &&
                c.statusPermanencia == StatusPermanencia.alertaTolerancia)
            .toList();
      case 'EXCEDIDAS':
        return lista
            .where((c) =>
                c.isOcupada &&
                c.statusPermanencia == StatusPermanencia.limiteExcedido)
            .toList();
      default:
        return lista;
    }
  }

  void _tratarCliqueComanda(BuildContext context, Comanda comanda) {
    if (!comanda.isOcupada) {
      showDialog(
        context: context,
        builder: (_) => CheckInComandaDialog(
          comanda: comanda,
          onConfirmar: (obs) {
            context.read<ComandaCubit>().realizarCheckIn(
                  comanda: comanda,
                  observacao: obs,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Check-in registrado na ${comanda.nomeExibicao}!'),
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
        builder: (_) => CheckOutComandaDialog(
          comanda: comanda,
          onConfirmar: () {
            context.read<ComandaCubit>().realizarCheckOut(comanda: comanda);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Check-out efetuado! ${comanda.nomeExibicao} liberada e gravada em TB_INGRESSO.'),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      );
    }
  }
}
