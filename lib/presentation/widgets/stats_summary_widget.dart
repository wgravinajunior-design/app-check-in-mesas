import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../cubits/mesa/mesa_state.dart';

class StatsSummaryWidget extends StatelessWidget {
  final MesaLoaded state;
  final String filtroAtivo;
  final Function(String novoFiltro) onSelecionarFiltro;

  const StatsSummaryWidget({
    super.key,
    required this.state,
    required this.filtroAtivo,
    required this.onSelecionarFiltro,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCardIndicador(
                  titulo: 'Todas',
                  quantidade: state.totalMesas,
                  cor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  corFundo: const Color(0xFFF1F5F9),
                  filtroChave: 'TODAS',
                  icone: Icons.dashboard_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildCardIndicador(
                  titulo: 'Livres',
                  quantidade: state.totalLivres,
                  cor: AppTheme.corMesaLivre,
                  corFundo: AppTheme.corMesaLivreClaro,
                  filtroChave: 'LIVRES',
                  icone: Icons.check_circle_outline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildCardIndicador(
                  titulo: 'Atendimento',
                  quantidade: state.totalEmAtendimento,
                  cor: AppTheme.corMesaNormal,
                  corFundo: AppTheme.corMesaNormalClaro,
                  filtroChave: 'NORMAL',
                  icone: Icons.access_time_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildCardIndicador(
                  titulo: 'Alerta',
                  quantidade: state.totalEmAlerta,
                  cor: AppTheme.corMesaAlerta,
                  corFundo: AppTheme.corMesaAlertaClaro,
                  filtroChave: 'ALERTA',
                  icone: Icons.warning_amber_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildCardIndicador(
                  titulo: 'Excedidas',
                  quantidade: state.totalExcedidas,
                  cor: AppTheme.corMesaExcedida,
                  corFundo: AppTheme.corMesaExcedidaClaro,
                  filtroChave: 'EXCEDIDAS',
                  icone: Icons.alarm_on_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardIndicador({
    required String titulo,
    required int quantidade,
    required Color cor,
    required Color corFundo,
    required String filtroChave,
    required IconData icone,
    required bool isDark,
  }) {
    final bool isSelecionado = filtroAtivo == filtroChave;
    final Color chipBg = isSelecionado
        ? cor
        : (isDark ? cor.withValues(alpha: 0.16) : corFundo);
    final Color chipBorder = isSelecionado
        ? cor
        : cor.withValues(alpha: isDark ? 0.45 : 0.3);
    final Color chipText = isSelecionado ? Colors.white : cor;

    return InkWell(
      onTap: () => onSelecionarFiltro(filtroChave),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: chipBorder,
            width: isSelecionado ? 2 : 1,
          ),
          boxShadow: isSelecionado
              ? [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 16,
              color: chipText,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: chipText,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelecionado
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? cor.withValues(alpha: 0.25) : cor.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                quantidade.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: chipText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
