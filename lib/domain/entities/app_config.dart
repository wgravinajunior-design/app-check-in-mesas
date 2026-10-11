import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class AppConfig extends Equatable {
  final int tempoAlertaMinutos;
  final int tempoLimiteMinutos;
  final int totalMesas;
  final int empresaId;
  final String apiUrl;
  final bool autoSync;
  final String caminhoBanco;
  final String usuarioBanco;
  final String senhaBanco;

  const AppConfig({
    this.tempoAlertaMinutos = AppConstants.defaultTempoAlertaMinutos,
    this.tempoLimiteMinutos = AppConstants.defaultTempoLimiteMinutos,
    this.totalMesas = AppConstants.defaultTotalMesas,
    this.empresaId = AppConstants.defaultEmpresaId,
    this.apiUrl = 'http://localhost:8080/api',
    this.autoSync = false,
    this.caminhoBanco = AppConstants.defaultCaminhoBancoFirebird,
    this.usuarioBanco = AppConstants.defaultUsuarioFirebird,
    this.senhaBanco = AppConstants.defaultSenhaFirebird,
  });

  AppConfig copyWith({
    int? tempoAlertaMinutos,
    int? tempoLimiteMinutos,
    int? totalMesas,
    int? empresaId,
    String? apiUrl,
    bool? autoSync,
    String? caminhoBanco,
    String? usuarioBanco,
    String? senhaBanco,
  }) {
    return AppConfig(
      tempoAlertaMinutos: tempoAlertaMinutos ?? this.tempoAlertaMinutos,
      tempoLimiteMinutos: tempoLimiteMinutos ?? this.tempoLimiteMinutos,
      totalMesas: totalMesas ?? this.totalMesas,
      empresaId: empresaId ?? this.empresaId,
      apiUrl: apiUrl ?? this.apiUrl,
      autoSync: autoSync ?? this.autoSync,
      caminhoBanco: caminhoBanco ?? this.caminhoBanco,
      usuarioBanco: usuarioBanco ?? this.usuarioBanco,
      senhaBanco: senhaBanco ?? this.senhaBanco,
    );
  }

  @override
  List<Object?> get props => [
        tempoAlertaMinutos,
        tempoLimiteMinutos,
        totalMesas,
        empresaId,
        apiUrl,
        autoSync,
        caminhoBanco,
        usuarioBanco,
        senhaBanco,
      ];
}
