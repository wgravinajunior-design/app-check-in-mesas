import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/mesa.dart';

class CheckInDialog extends StatefulWidget {
  final Mesa mesa;
  final Function(String? observacao) onConfirmar;

  const CheckInDialog({
    super.key,
    required this.mesa,
    required this.onConfirmar,
  });

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final TextEditingController _obsController = TextEditingController();
  final DateTime _agora = DateTime.now();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.corMesaLivreClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.login_rounded, color: AppTheme.corMesaLivre),
          ),
          const SizedBox(width: 12),
          Text(
            'Check-in: ${widget.mesa.nomeExibicao}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Horário de Entrada:',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      Text(
                        TimeFormatter.formatDateTime(_agora),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mesa / Identificador:',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      Text(
                        widget.mesa.codigo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Observação (opcional):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _obsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex.: Garçom Lucas, Reserva VIP, 3 pessoas...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '* O registo será criado na tabela TB_INGRESSO para auditoria e histórico de permanência.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic),
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
            backgroundColor: AppTheme.corMesaLivre,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onConfirmar(_obsController.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text('Confirmar Check-in'),
        ),
      ],
    );
  }
}
