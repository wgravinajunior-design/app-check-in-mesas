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
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text(
                  'Encerrar atendimento e registrar permanência',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Entrada:', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                Text(
                  TimeFormatter.formatDateTime(comanda.horaEntrada),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tempo Total Ativo:', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
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
              const Divider(height: 14),
              Text(
                'Obs: ${comanda.ingressoAtual!.observacao!}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
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
