import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_config.dart';

class ConfigModel extends AppConfig {
  const ConfigModel({
    super.tempoAlertaMinutos,
    super.tempoLimiteMinutos,
    super.totalMesas,
    super.empresaId,
    super.apiUrl,
    super.autoSync,
    super.hostBanco,
    super.portaBanco,
    super.caminhoBanco,
    super.usuarioBanco,
    super.senhaBanco,
  });

  factory ConfigModel.fromEntity(AppConfig entity) {
    return ConfigModel(
      tempoAlertaMinutos: entity.tempoAlertaMinutos,
      tempoLimiteMinutos: entity.tempoLimiteMinutos,
      totalMesas: entity.totalMesas,
      empresaId: entity.empresaId,
      apiUrl: entity.apiUrl,
      autoSync: entity.autoSync,
      hostBanco: entity.hostBanco,
      portaBanco: entity.portaBanco,
      caminhoBanco: entity.caminhoBanco,
      usuarioBanco: entity.usuarioBanco,
      senhaBanco: entity.senhaBanco,
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
      'hostBanco': hostBanco,
      'portaBanco': portaBanco,
      'caminhoBanco': caminhoBanco,
      'usuarioBanco': usuarioBanco,
      'senhaBanco': senhaBanco,
    };
  }

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      tempoAlertaMinutos: json['tempoAlertaMinutos'] as int? ?? AppConstants.defaultTempoAlertaMinutos,
      tempoLimiteMinutos: json['tempoLimiteMinutos'] as int? ?? AppConstants.defaultTempoLimiteMinutos,
      totalMesas: json['totalMesas'] as int? ?? AppConstants.defaultTotalMesas,
      empresaId: json['empresaId'] as int? ?? AppConstants.defaultEmpresaId,
      apiUrl: json['apiUrl'] as String? ?? 'http://localhost:8080/api',
      autoSync: json['autoSync'] as bool? ?? false,
      hostBanco: json['hostBanco'] as String? ?? AppConstants.defaultHostFirebird,
      portaBanco: json['portaBanco'] as int? ?? AppConstants.defaultPortaFirebird,
      caminhoBanco: json['caminhoBanco'] as String? ?? AppConstants.defaultCaminhoBancoFirebird,
      usuarioBanco: json['usuarioBanco'] as String? ?? AppConstants.defaultUsuarioFirebird,
      senhaBanco: json['senhaBanco'] as String? ?? AppConstants.defaultSenhaFirebird,
    );
  }
}
