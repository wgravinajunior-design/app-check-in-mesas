import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';

class MetricasSalaoDialog extends StatelessWidget {
  final List<Mesa> mesas;

  const MetricasSalaoDialog({
    super.key,
    required this.mesas,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isTablet = mediaQuery.size.width >= 600;

    final int totalMesas = mesas.length;
    final int ocupadas = mesas.where((m) => m.isOcupada).length;
    final int livres = totalMesas - ocupadas;
    final double taxaOcupacao = totalMesas > 0 ? (ocupadas / totalMesas) * 100 : 0;

    final int emAlerta = mesas
        .where((m) => m.isOcupada && m.statusPermanencia == StatusPermanencia.alertaTolerancia)
        .length;
    final int excedidas = mesas
        .where((m) => m.isOcupada && m.statusPermanencia == StatusPermanencia.limiteExcedido)
        .length;

    // Tempo médio de permanência das mesas ocupadas
    int mediaMinutos = 0;
    Mesa? mesaMaisTempo;
    if (ocupadas > 0) {
      final totalMinutos = mesas
          .where((m) => m.isOcupada)
          .fold<int>(0, (acc, m) => acc + m.tempoDecorrido.inMinutes);
      mediaMinutos = (totalMinutos / ocupadas).round();

      mesaMaisTempo = mesas
          .where((m) => m.isOcupada)
          .reduce((a, b) => a.tempoDecorrido > b.tempoDecorrido ? a : b);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Métricas e Giro do Salão',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Visão gerencial em tempo real',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Cards de Métricas em Grid
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatCard(
                    titulo: 'Ocupação do Salão',
                    valor: '${taxaOcupacao.toStringAsFixed(1)}%',
                    subtitulo: '$ocupadas de $totalMesas mesas',
                    cor: const Color(0xFF0D47A1),
                    icone: Icons.pie_chart_rounded,
                    largura: isTablet ? 245 : 150,
                  ),
                  _buildStatCard(
                    titulo: 'Tempo Médio Ativo',
                    valor: '${mediaMinutos}m',
                    subtitulo: ocupadas > 0 ? '${(mediaMinutos / 60).toStringAsFixed(1)} horas' : 'Sem mesas',
                    cor: const Color(0xFF0284C7),
                    icone: Icons.access_time_filled_rounded,
                    largura: isTablet ? 245 : 150,
                  ),
                  _buildStatCard(
                    titulo: 'Mesas Livres',
                    valor: '$livres',
                    subtitulo: 'Prontas para entrada',
                    cor: AppTheme.corMesaLivre,
                    icone: Icons.check_circle_rounded,
                    largura: isTablet ? 245 : 150,
                  ),
                  _buildStatCard(
                    titulo: 'Alerta / Excedidas',
                    valor: '$emAlerta / $excedidas',
                    subtitulo: 'Atenção do salão',
                    cor: excedidas > 0 ? AppTheme.corMesaExcedida : AppTheme.corMesaAlerta,
                    icone: Icons.warning_rounded,
                    largura: isTablet ? 245 : 150,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Destaque da Mesa com Maior Permanência
              if (mesaMaisTempo != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maior Permanência Atual: ${mesaMaisTempo.nomeExibicao}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Tempo decorrido: ${TimeFormatter.formatDuration(mesaMaisTempo.tempoDecorrido)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color cor,
    required IconData icone,
    required double largura,
  }) {
    return Container(
      width: largura,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
