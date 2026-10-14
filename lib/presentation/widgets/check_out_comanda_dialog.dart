import 'package:flutter/material.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/comanda.dart';
import '../../domain/entities/status_permanencia.dart';

class CheckOutComandaDialog extends StatelessWidget {
  final Comanda comanda;
  final VoidCallback onConfirmar;

  const CheckOutComandaDialog({
    super.key,
    required this.comanda,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-out: ${comanda.nomeExibicao}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? const Color(0xFFF8FAFC) : null,
                  ),
                ),
                Text(
                  'Encerrar atendimento e registrar permanência',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entrada:',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  TimeFormatter.formatDateTime(comanda.horaEntrada),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tempo Total Ativo:',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  TimeFormatter.formatDuration(comanda.tempoDecorrido),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: comanda.statusPermanencia.corPrimaria,
                  ),
                ),
              ],
            ),
            if (comanda.ingressoAtual?.observacao != null &&
                comanda.ingressoAtual!.observacao!.isNotEmpty) ...[
              Divider(height: 14, color: isDark ? const Color(0xFF334155) : null),
              Text(
                'Obs: ${comanda.ingressoAtual!.observacao!}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Confirmar Check-out'),
          onPressed: () {
            onConfirmar();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
