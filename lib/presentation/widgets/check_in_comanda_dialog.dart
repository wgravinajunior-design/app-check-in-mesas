import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/comanda.dart';

class CheckInComandaDialog extends StatefulWidget {
  final Comanda comanda;
  final Function(String? observacao) onConfirmar;

  const CheckInComandaDialog({
    super.key,
    required this.comanda,
    required this.onConfirmar,
  });

  @override
  State<CheckInComandaDialog> createState() => _CheckInComandaDialogState();
}

class _CheckInComandaDialogState extends State<CheckInComandaDialog> {
  final TextEditingController _obsController = TextEditingController();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.corMesaLivre.withValues(alpha: 0.2)
                  : AppTheme.corMesaLivreClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.corMesaLivre),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in: ${widget.comanda.nomeExibicao}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? const Color(0xFFF8FAFC) : null,
                  ),
                ),
                Text(
                  'Iniciar contagem de permanência da comanda',
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observação / Identificação do Cliente (opcional):',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _obsController,
            decoration: InputDecoration(
              hintText: 'Ex.: Nome do cliente / mesa vinculada',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF64748B) : null,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.person_pin_circle_outlined, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.corMesaLivre,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Confirmar Check-in'),
          onPressed: () {
            widget.onConfirmar(_obsController.text.trim().isEmpty ? null : _obsController.text.trim());
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
