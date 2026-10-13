import 'package:flutter/material.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';

class MesaCardWidget extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;
  final AppConfig? config;

  const MesaCardWidget({
    super.key,
    required this.mesa,
    required this.onTap,
    this.config,
  });

  /// Determina as cores e o ícone do tempo do último pedido conforme a configuração semafórica
  static ({Color corTexto, Color corFundo, Color corBorda, IconData icone}) _obterEstiloTempoPedido(
    int minutos,
    int tempoVerde,
    int tempoAmarelo,
    int tempoVermelho,
  ) {
    if (minutos <= tempoVerde) {
      // Normal / recente -> Verde
      return (
        corTexto: const Color(0xFF15803D), // Verde escuro
        corFundo: const Color(0xFFDCFCE7), // Fundo verde claro
        corBorda: const Color(0xFF86EFAC),
        icone: Icons.fastfood_rounded,
      );
    } else if (minutos <= tempoAmarelo) {
      // Alerta de tolerância -> Amarelo / Âmbar
      return (
        corTexto: const Color(0xFFB45309), // Âmbar escuro
        corFundo: const Color(0xFFFEF3C7), // Fundo amarelo claro
        corBorda: const Color(0xFFFCD34D),
        icone: Icons.warning_amber_rounded,
      );
    } else {
      // Limite excedido -> Vermelho
      final bool critico = minutos >= tempoVermelho;
      return (
        corTexto: critico ? const Color(0xFF991B1B) : const Color(0xFFB91C1C), // Vermelho perigo/excedido
        corFundo: critico ? const Color(0xFFFEE2E2) : const Color(0xFFFEF2F2),
        corBorda: critico ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5),
        icone: Icons.alarm_on_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = mesa.statusPermanencia;
    final corPrimaria = status.corPrimaria;
    final corFundo = status.corFundoClara;
    final bool isExcedida = status == StatusPermanencia.limiteExcedido;

    final int tempoVerde = config?.tempoVerdeMinutos ?? 30;
    final int tempoAmarelo = config?.tempoAmareloMinutos ?? 60;
    final int tempoVermelho = config?.tempoVermelhoMinutos ?? 90;

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

              // Corpo Central: Horário de Entrada, Quantidade de Pessoas e Cronômetro
              if (mesa.isOcupada) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 11, color: Color(0xFF475569)),
                          const SizedBox(width: 3),
                          Text(
                            mesa.numeroPessoas > 0 ? '${mesa.numeroPessoas} pess.' : '0 pess.',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
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
                // Seção Consumo & Último Pedido (Colorido conforme Config)
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
                      ? Builder(
                          builder: (context) {
                            final int minutosUltimo = mesa.minutosDesdeUltimoPedido ?? 0;
                            final estilo = _obterEstiloTempoPedido(
                              minutosUltimo,
                              tempoVerde,
                              tempoAmarelo,
                              tempoVermelho,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: estilo.corFundo,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: estilo.corBorda, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            estilo.icone,
                                            size: 11,
                                            color: estilo.corTexto,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Último: há ${minutosUltimo}m',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: estilo.corTexto,
                                            ),
                                          ),
                                        ],
                                      ),
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
                            );
                          },
                        )
                      : Builder(
                          builder: (context) {
                            final int minutosSemPedido = mesa.tempoDecorrido.inMinutes;
                            final estilo = _obterEstiloTempoPedido(
                              minutosSemPedido,
                              tempoVerde,
                              tempoAmarelo,
                              tempoVermelho,
                            );

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: estilo.corFundo,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: estilo.corBorda, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    estilo.icone,
                                    size: 11,
                                    color: estilo.corTexto,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      minutosSemPedido > 0
                                          ? 'Sem pedidos há ${minutosSemPedido}m'
                                          : 'Sem pedidos após check-in',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: estilo.corTexto,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
