import 'package:flutter/material.dart';
import '../../domain/entities/app_config.dart';

class ConfigDialog extends StatefulWidget {
  final AppConfig configAtual;
  final Function(AppConfig novaConfig) onSalvar;

  const ConfigDialog({
    super.key,
    required this.configAtual,
    required this.onSalvar,
  });

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late TextEditingController _tempoAlertaController;
  late TextEditingController _tempoLimiteController;
  late TextEditingController _totalMesasController;
  late TextEditingController _empresaIdController;
  late TextEditingController _apiUrlController;
  late bool _autoSync;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tempoAlertaController = TextEditingController(
      text: widget.configAtual.tempoAlertaMinutos.toString(),
    );
    _tempoLimiteController = TextEditingController(
      text: widget.configAtual.tempoLimiteMinutos.toString(),
    );
    _totalMesasController = TextEditingController(
      text: widget.configAtual.totalMesas.toString(),
    );
    _empresaIdController = TextEditingController(
      text: widget.configAtual.empresaId.toString(),
    );
    _apiUrlController = TextEditingController(
      text: widget.configAtual.apiUrl,
    );
    _autoSync = widget.configAtual.autoSync;
  }

  @override
  void dispose() {
    _tempoAlertaController.dispose();
    _tempoLimiteController.dispose();
    _totalMesasController.dispose();
    _empresaIdController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Color(0xFF0D47A1)),
          SizedBox(width: 10),
          Text(
            'Configurações de Permanência',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parâmetros de Rotatividade e Tolerância',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tempoAlertaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tempo de Alerta (minutos)',
                  helperText: 'Padrão: 90 minutos (1h30m) - Fica Amarelo/Laranja',
                  prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  final num = int.tryParse(val ?? '');
                  if (num == null || num <= 0) return 'Informe um valor positivo em minutos';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tempoLimiteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tempo Limite Máximo (minutos)',
                  helperText: 'Padrão: 120 minutos (2h00m) - Fica Vermelho Excedido',
                  prefixIcon: const Icon(Icons.alarm_on_rounded, color: Colors.red),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  final num = int.tryParse(val ?? '');
                  final alerta = int.tryParse(_tempoAlertaController.text);
                  if (num == null || num <= 0) return 'Informe um valor positivo';
                  if (alerta != null && num <= alerta) {
                    return 'Tempo limite deve ser maior que o tempo de alerta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _totalMesasController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantidade de Mesas',
                  helperText: 'Capacidade total de mesas do salão',
                  prefixIcon: const Icon(Icons.table_restaurant_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  final num = int.tryParse(val ?? '');
                  if (num == null || num <= 0) return 'Mínimo de 1 mesa';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _empresaIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ID da Empresa (ING_EMPRESA)',
                  helperText: 'Conforme TB_EMPRESA da base Firebird',
                  prefixIcon: const Icon(Icons.business_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apiUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL da API Retaguarda (Opcional)',
                  helperText: 'Ex.: http://192.168.1.100:8080/api',
                  prefixIcon: const Icon(Icons.cloud_sync_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final novaConfig = widget.configAtual.copyWith(
                tempoAlertaMinutos: int.parse(_tempoAlertaController.text),
                tempoLimiteMinutos: int.parse(_tempoLimiteController.text),
                totalMesas: int.parse(_totalMesasController.text),
                empresaId: int.parse(_empresaIdController.text),
                apiUrl: _apiUrlController.text.trim(),
                autoSync: _autoSync,
              );
              widget.onSalvar(novaConfig);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
