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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final corCardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final corCardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final corConsumoBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final corConsumoBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? status.corPrimaria.withValues(alpha: 0.2) : status.corFundoClara,
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
                color: corCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: corCardBorder),
              ),
              child: Column(
                children: [
                  _buildLinhaResumo(
                    label: 'Hora de Entrada:',
                    valor: TimeFormatter.formatDateTime(mesa.horaEntrada),
                    icone: Icons.login_rounded,
                    isDark: isDark,
                  ),
                  Divider(height: 14, color: isDark ? const Color(0xFF1E293B) : null),
                  _buildLinhaResumo(
                    label: 'Quantidade de Pessoas:',
                    valor: '${mesa.numeroPessoas} ${mesa.numeroPessoas == 1 ? "pessoa" : "pessoas"}',
                    icone: Icons.people_alt_rounded,
                    isDark: isDark,
                  ),
                  Divider(height: 14, color: isDark ? const Color(0xFF1E293B) : null),
                  _buildLinhaResumo(
                    label: 'Hora de Saída:',
                    valor: TimeFormatter.formatDateTime(agora),
                    icone: Icons.logout_rounded,
                    isDark: isDark,
                  ),
                  Divider(height: 14, color: isDark ? const Color(0xFF1E293B) : null),
                  _buildLinhaResumo(
                    label: 'Tempo Total:',
                    valor: TimeFormatter.formatCronometro(totalPermanencia),
                    icone: Icons.timelapse_rounded,
                    isDestaque: true,
                    corDestaque: status.corPrimaria,
                    isDark: isDark,
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
                color: corConsumoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: corConsumoBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        'Consumo da Mesa (Modelo Pré-pago):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (mesa.temConsumo) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total de Pedidos Realizados:', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                        Text('${mesa.quantidadePedidos} pedido(s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : null)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Último Pedido (há ${mesa.minutosDesdeUltimoPedido ?? 0} min):', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                        Text('R\$ ${mesa.valorUltimoPedido.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))),
                      ],
                    ),
                    Divider(height: 10, color: isDark ? const Color(0xFF1E293B) : null),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Somatório Total Consumido:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                        Text('R\$ ${mesa.valorTotalConsumo.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Nenhum pedido lançado para esta mesa após o momento do check-in.',
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontStyle: FontStyle.italic),
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
                color: isDark ? status.corPrimaria.withValues(alpha: 0.18) : status.corFundoClara,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: status.corPrimaria.withValues(alpha: isDark ? 0.5 : 0.4)),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
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
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 13),
            ),
          ],
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: isDestaque ? FontWeight.bold : FontWeight.w600,
            color: isDestaque
                ? (corDestaque ?? (isDark ? Colors.white : const Color(0xFF0F172A)))
                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            fontSize: isDestaque ? 15 : 13,
            fontFamily: isDestaque ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
