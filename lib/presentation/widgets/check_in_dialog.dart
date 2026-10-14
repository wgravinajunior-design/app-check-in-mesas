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
            child: const Icon(Icons.login_rounded, color: AppTheme.corMesaLivre),
          ),
          const SizedBox(width: 12),
          Text(
            'Check-in: ${widget.mesa.nomeExibicao}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? const Color(0xFFF8FAFC) : null,
            ),
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
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Horário de Entrada:',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        TimeFormatter.formatDateTime(_agora),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 16, color: isDark ? const Color(0xFF334155) : null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mesa / Identificador:',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        widget.mesa.codigo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Observação (opcional):',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : null,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _obsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex.: Garçom Lucas, Reserva VIP, 3 pessoas...',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38BDF8) : AppTheme.corMesaLivre,
                    width: 1.5,
                  ),
                ),
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
