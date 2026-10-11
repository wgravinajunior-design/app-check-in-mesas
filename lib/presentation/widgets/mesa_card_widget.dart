import 'package:flutter/material.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';

class MesaCardWidget extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;

  const MesaCardWidget({
    super.key,
    required this.mesa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = mesa.statusPermanencia;
    final corPrimaria = status.corPrimaria;
    final corFundo = status.corFundoClara;
    final bool isExcedida = status == StatusPermanencia.limiteExcedido;

    return Card(
      elevation: isExcedida ? 6 : 2,
      shadowColor: isExcedida ? corPrimaria.withValues(alpha: 0.5) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: corPrimaria.withValues(alpha: isExcedida ? 0.9 : 0.4),
          width: isExcedida ? 2.5 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                corFundo,
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cabeçalho: Número da mesa e Badge de Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: corPrimaria.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status.icone,
                          size: 18,
                          color: corPrimaria,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mesa.nomeExibicao,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: corPrimaria,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.rotulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Corpo Central: Horário de Entrada e Cronômetro
              if (mesa.isOcupada) ...[
                Row(
                  children: [
                    const Icon(Icons.login_rounded, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Entrada: ${TimeFormatter.formatTime(mesa.horaEntrada)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: corPrimaria.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: corPrimaria,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        TimeFormatter.formatCronometro(mesa.tempoDecorrido),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: corPrimaria,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 28,
                          color: corPrimaria.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque para Check-in',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: corPrimaria,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // Rodapé: Ação rápida
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mesa.isOcupada ? 'Toque para Check-out' : 'Disponível',
                      style: TextStyle(
                        fontSize: 11,
                        color: mesa.isOcupada ? Colors.black87 : Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      mesa.isOcupada ? Icons.logout_rounded : Icons.arrow_forward_ios_rounded,
                      size: 13,
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
