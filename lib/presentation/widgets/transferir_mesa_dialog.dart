import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/status_permanencia.dart';


class TransferirMesaDialog extends StatefulWidget {
  final Mesa mesaOrigem;
  final List<Mesa> mesasLivres;
  final void Function(Mesa mesaDestino, String? motivo) onConfirmar;

  const TransferirMesaDialog({
    super.key,
    required this.mesaOrigem,
    required this.mesasLivres,
    required this.onConfirmar,
  });

  @override
  State<TransferirMesaDialog> createState() => _TransferirMesaDialogState();
}

class _TransferirMesaDialogState extends State<TransferirMesaDialog> {
  Mesa? _mesaDestinoSelecionada;
  final TextEditingController _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.mesasLivres.isNotEmpty) {
      _mesaDestinoSelecionada = widget.mesasLivres.first;
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isTablet = mediaQuery.size.width >= 600;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transferir Mesa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : null,
                          ),
                        ),
                        Text(
                          'Mantenha o tempo de permanência ativo',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informações da Mesa de Origem
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.mesaOrigem.statusPermanencia.corPrimaria,
                      foregroundColor: Colors.white,
                      radius: 20,
                      child: Text(
                        widget.mesaOrigem.codigo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mesaOrigem.nomeExibicao,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? const Color(0xFFF1F5F9) : null,
                            ),
                          ),
                          Text(
                            'Tempo ativo: ${TimeFormatter.formatDuration(widget.mesaOrigem.tempoDecorrido)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.mesaOrigem.statusPermanencia.corPrimaria,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Seleção da Mesa de Destino
              Text(
                'Selecione a Mesa de Destino (Livre):',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? const Color(0xFFCBD5E1) : null,
                ),
              ),
              const SizedBox(height: 8),

              if (widget.mesasLivres.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.withValues(alpha: 0.18) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.red.withValues(alpha: 0.4) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Não há outras mesas livres no momento para realizar a transferência.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFFCA5A5) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Mesa>(
                  initialValue: _mesaDestinoSelecionada,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.table_restaurant_rounded, color: AppTheme.corMesaLivre),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : null,
                  items: widget.mesasLivres.map((mesa) {
                    return DropdownMenuItem<Mesa>(
                      value: mesa,
                      child: Text(
                        '${mesa.nomeExibicao} (Livre)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (Mesa? novaMesa) {
                    setState(() {
                      _mesaDestinoSelecionada = novaMesa;
                    });
                  },
                ),
              const SizedBox(height: 14),

              // Motivo opcional
              TextField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo da Transferência (opcional)',
                  hintText: 'Ex.: Mudança para área externa / juntou mesas',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : null),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Confirmar Transferência'),
                    onPressed: widget.mesasLivres.isEmpty || _mesaDestinoSelecionada == null
                        ? null
                        : () {
                            widget.onConfirmar(
                              _mesaDestinoSelecionada!,
                              _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
                            );
                            Navigator.of(context).pop();
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
