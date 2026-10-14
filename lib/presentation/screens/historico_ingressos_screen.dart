import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/ingresso.dart';
import '../../domain/repositories/ingresso_repository.dart';

class HistoricoIngressosScreen extends StatefulWidget {
  final IngressoRepository ingressoRepository;
  final int empresaId;

  const HistoricoIngressosScreen({
    super.key,
    required this.ingressoRepository,
    required this.empresaId,
  });

  @override
  State<HistoricoIngressosScreen> createState() => _HistoricoIngressosScreenState();
}

class _HistoricoIngressosScreenState extends State<HistoricoIngressosScreen> {
  List<Ingresso> _lista = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final dados = await widget.ingressoRepository.listarHistorico(
        empresaId: widget.empresaId,
      );
      setState(() {
        _lista = dados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  Future<void> _exportarCsv() async {
    if (_lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum registro para exportar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final StringBuffer csv = StringBuffer();
      // Cabeçalho compatível com Excel brasileiro
      csv.writeln('ID;EMPRESA;CODIGO_MESA;STATUS;DATA_ENTRADA;DATA_SAIDA;DURACAO_MINUTOS;OBSERVACAO');

      for (final item in _lista) {
        final id = item.id;
        final empresa = item.empresaId;
        final mesa = item.codigoMesa;
        final status = item.status == 'A' ? 'Aberto' : 'Finalizado';
        final entrada = item.dtEntrada != null ? TimeFormatter.formatDateTime(item.dtEntrada) : '';
        final saida = item.dtSaida != null ? TimeFormatter.formatDateTime(item.dtSaida) : '';
        final duracao = item.duracaoMinutos ?? 0;
        final obs = (item.observacao ?? '').replaceAll(';', ',').replaceAll('\n', ' ');

        csv.writeln('$id;$empresa;$mesa;$status;$entrada;$saida;$duracao;"$obs"');
      }

      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String caminhoArquivo = '${directory.path}/TB_INGRESSO_${widget.empresaId}_$timestamp.csv';
      final file = File(caminhoArquivo);
      await file.writeAsString(csv.toString(), encoding: utf8);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text('Relatório CSV Gerado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_lista.length} registros exportados com sucesso no padrão do ERP (TB_INGRESSO).',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Local do arquivo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  caminhoArquivo,
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: caminhoArquivo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caminho copiado para a área de transferência!')),
                  );
                },
                child: const Text('Copiar Caminho'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria - TB_INGRESSO'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV (Excel)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportarCsv,
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarHistorico,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum registro de permanência em TB_INGRESSO.',
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lista.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _lista[index];
                    final bool isFinalizado = item.status == 'F';

                    return Card(
                      elevation: isDark ? 0 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                                            : const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Mesa ${item.codigoMesa}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ID: #${item.id}',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFinalizado
                                        ? AppTheme.corMesaLivre.withValues(alpha: 0.15)
                                        : AppTheme.corMesaNormal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isFinalizado ? 'FINALIZADO (F)' : 'EM ATENDIMENTO (A)',
                                    style: TextStyle(
                                      color: isFinalizado ? (isDark ? const Color(0xFF94A3B8) : AppTheme.corMesaLivre) : AppTheme.corMesaNormal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 16, color: isDark ? const Color(0xFF334155) : null),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Entrada (Check-in)',
                                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        TimeFormatter.formatDateTime(item.dtEntrada),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? const Color(0xFFF1F5F9) : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saída (Check-out)',
                                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.dtSaida != null
                                            ? TimeFormatter.formatDateTime(item.dtSaida)
                                            : 'Ainda aberta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: item.dtSaida != null
                                              ? (isDark ? const Color(0xFFF1F5F9) : Colors.black87)
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Duração',
                                        style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                      Text(
                                        '${item.duracaoMinutos ?? 0} min',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? const Color(0xFFF8FAFC) : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item.observacao != null && item.observacao!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.observacao!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
