import 'package:flutter/material.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';

class CheckOutDialog extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onConfirmar;

  const CheckOutDialog({
    super.key,
    required this.mesa,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime agora = DateTime.now();
    final DateTime entrada = mesa.horaEntrada ?? agora;
    final Duration totalPermanencia = agora.difference(entrada);
    final status = mesa.statusPermanencia;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status.corFundoClara,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded, color: status.corPrimaria),
          ),
          const SizedBox(width: 12),
          Text(
            'Check-out: ${mesa.nomeExibicao}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card com resumo da permanência
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildLinhaResumo(
                    label: 'Hora de Entrada:',
                    valor: TimeFormatter.formatDateTime(mesa.horaEntrada),
                    icone: Icons.login_rounded,
                  ),
                  const Divider(height: 14),
                  _buildLinhaResumo(
                    label: 'Quantidade de Pessoas:',
                    valor: '${mesa.numeroPessoas} ${mesa.numeroPessoas == 1 ? "pessoa" : "pessoas"}',
                    icone: Icons.people_alt_rounded,
                  ),
                  const Divider(height: 14),
                  _buildLinhaResumo(
                    label: 'Hora de Saída:',
                    valor: TimeFormatter.formatDateTime(agora),
                    icone: Icons.logout_rounded,
                  ),
                  const Divider(height: 14),
                  _buildLinhaResumo(
                    label: 'Tempo Total:',
                    valor: TimeFormatter.formatCronometro(totalPermanencia),
                    icone: Icons.timelapse_rounded,
                    isDestaque: true,
                    corDestaque: status.corPrimaria,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '(${TimeFormatter.formatDuracaoAmigavel(totalPermanencia)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status.corPrimaria,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Resumo de Pedidos e Consumo (Modelo Pré-pago)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Text(
                        'Consumo da Mesa (Modelo Pré-pago):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (mesa.temConsumo) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total de Pedidos Realizados:', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        Text('${mesa.quantidadePedidos} pedido(s)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Último Pedido (há ${mesa.minutosDesdeUltimoPedido ?? 0} min):', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        Text('R\$ ${mesa.valorUltimoPedido.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      ],
                    ),
                    const Divider(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Somatório Total Consumido:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('R\$ ${mesa.valorTotalConsumo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Nenhum pedido lançado para esta mesa após o momento do check-in.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Faixa de status atingida
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: status.corFundoClara,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: status.corPrimaria.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(status.icone, size: 20, color: status.corPrimaria),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Classificação: ${status.rotulo}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status.corPrimaria,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'A mesa será liberada e o registro na TB_INGRESSO receberá a data/hora final e duração total para auditoria.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            onConfirmar();
            Navigator.of(context).pop();
          },
          child: const Text('Confirmar Liberação'),
        ),
      ],
    );
  }

  Widget _buildLinhaResumo({
    required String label,
    required String valor,
    required IconData icone,
    bool isDestaque = false,
    Color? corDestaque,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
          ],
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: isDestaque ? FontWeight.bold : FontWeight.w600,
            color: isDestaque ? (corDestaque ?? const Color(0xFF0F172A)) : const Color(0xFF1E293B),
            fontSize: isDestaque ? 15 : 13,
            fontFamily: isDestaque ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
