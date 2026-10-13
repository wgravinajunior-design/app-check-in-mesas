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
      elevation: isExcedida ? 4 : 1.5,
      shadowColor: isExcedida ? corPrimaria.withValues(alpha: 0.4) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: corPrimaria.withValues(alpha: isExcedida ? 0.9 : 0.35),
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
              colors: [
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
              // Cabeçalho: Número da mesa e Badge de Status Compacto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: corPrimaria.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status.icone,
                            size: 15,
                            color: corPrimaria,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mesa.nomeExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
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
              if (mesa.isOcupada) ...[
                Row(
                  children: [
                    const Icon(Icons.login_rounded, size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Entrada: ${TimeFormatter.formatTime(mesa.horaEntrada)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
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
                    color: corPrimaria.withValues(alpha: 0.1),
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
                        TimeFormatter.formatCronometro(mesa.tempoDecorrido),
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
                const SizedBox(height: 3),
                // Seção Consumo & Último Pedido (Modelo Pré-pago)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: mesa.temConsumo
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.fastfood_rounded,
                                      size: 11,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Último: há ${mesa.minutosDesdeUltimoPedido ?? 0}m',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'R\$ ${mesa.valorUltimoPedido.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total (${mesa.quantidadePedidos} ped):',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'R\$ ${mesa.valorTotalConsumo.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: const [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sem pedidos após check-in',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
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
                          color: corPrimaria.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toque p/ Check-in',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: corPrimaria,
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
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mesa.isOcupada ? 'Check-out' : 'Disponível',
                      style: TextStyle(
                        fontSize: 10,
                        color: mesa.isOcupada ? Colors.black87 : Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      mesa.isOcupada ? Icons.logout_rounded : Icons.arrow_forward_ios_rounded,
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
