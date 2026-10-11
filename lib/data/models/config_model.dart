import '../../domain/entities/app_config.dart';

class ConfigModel extends AppConfig {
  const ConfigModel({
    super.tempoAlertaMinutos,
    super.tempoLimiteMinutos,
    super.totalMesas,
    super.empresaId,
    super.apiUrl,
    super.autoSync,
  });

  factory ConfigModel.fromEntity(AppConfig entity) {
    return ConfigModel(
      tempoAlertaMinutos: entity.tempoAlertaMinutos,
      tempoLimiteMinutos: entity.tempoLimiteMinutos,
      totalMesas: entity.totalMesas,
      empresaId: entity.empresaId,
      apiUrl: entity.apiUrl,
      autoSync: entity.autoSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempoAlertaMinutos': tempoAlertaMinutos,
      'tempoLimiteMinutos': tempoLimiteMinutos,
      'totalMesas': totalMesas,
      'empresaId': empresaId,
      'apiUrl': apiUrl,
      'autoSync': autoSync,
    };
  }

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      tempoAlertaMinutos: json['tempoAlertaMinutos'] as int? ?? 90,
      tempoLimiteMinutos: json['tempoLimiteMinutos'] as int? ?? 120,
      totalMesas: json['totalMesas'] as int? ?? 30,
      empresaId: json['empresaId'] as int? ?? 1,
      apiUrl: json['apiUrl'] as String? ?? 'http://localhost:8080/api',
      autoSync: json['autoSync'] as bool? ?? false,
    );
  }
}
