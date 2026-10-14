import 'package:flutter/material.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/comanda.dart';
import '../../domain/entities/status_permanencia.dart';

class ComandaCardWidget extends StatelessWidget {
  final Comanda comanda;
  final VoidCallback onTap;

  const ComandaCardWidget({
    super.key,
    required this.comanda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = comanda.statusPermanencia;
    final corPrimaria = status.corPrimaria;
    final corFundo = status.corFundoClara;
    final bool isExcedida = status == StatusPermanencia.limiteExcedido;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isExcedida ? 4 : (isDark ? 0 : 1.5),
      shadowColor: isExcedida ? corPrimaria.withValues(alpha: 0.4) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: corPrimaria.withValues(alpha: isExcedida ? 0.9 : (isDark ? 0.45 : 0.35)),
          width: isExcedida ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      corPrimaria.withValues(alpha: comanda.isOcupada ? 0.22 : 0.08),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      corFundo,
                      Colors.white,
                    ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cabeçalho: Número da comanda e Badge de Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: corPrimaria.withValues(alpha: isDark ? 0.25 : 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: corPrimaria,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            comanda.nomeExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: corPrimaria,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.rotulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Corpo Central: Horário de Entrada e Cronômetro
              if (comanda.isOcupada) ...[
                Row(
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Entrada: ${TimeFormatter.formatTime(comanda.horaEntrada)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: corPrimaria.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 15,
                        color: corPrimaria,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimeFormatter.formatCronometro(comanda.tempoDecorrido),
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: corPrimaria,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 22,
                          color: corPrimaria.withValues(alpha: isDark ? 0.85 : 0.7),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toque p/ Check-in',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : corPrimaria,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 4),

              // Rodapé: Ação rápida
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comanda.isOcupada ? 'Check-out' : 'Disponível',
                      style: TextStyle(
                        fontSize: 10,
                        color: comanda.isOcupada
                            ? (isDark ? const Color(0xFFF1F5F9) : Colors.black87)
                            : (isDark ? const Color(0xFF4ADE80) : Colors.green[800]),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      comanda.isOcupada ? Icons.logout_rounded : Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: corPrimaria,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
