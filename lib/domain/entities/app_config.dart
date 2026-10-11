import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class AppConfig extends Equatable {
  final int tempoAlertaMinutos;
  final int tempoLimiteMinutos;
  final int totalMesas;
  final int empresaId;
  final String apiUrl;
  final bool autoSync;
  final String hostBanco;
  final int portaBanco;
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
    this.hostBanco = AppConstants.defaultHostFirebird,
    this.portaBanco = AppConstants.defaultPortaFirebird,
    this.caminhoBanco = AppConstants.defaultCaminhoBancoFirebird,
    this.usuarioBanco = AppConstants.defaultUsuarioFirebird,
    this.senhaBanco = AppConstants.defaultSenhaFirebird,
  });

  /// Monta a string de conexão nativa do Firebird 5.0 (ex.: localhost/3060:C:\...\DADOS.FDB)
  String get stringConexaoFirebird {
    final hostLimpo = hostBanco.trim();
    final caminhoLimpo = caminhoBanco.trim();

    if (hostLimpo.isNotEmpty) {
      if (portaBanco > 0) {
        return '$hostLimpo/$portaBanco:$caminhoLimpo';
      }
      return '$hostLimpo:$caminhoLimpo';
    }
    return caminhoLimpo;
  }

  AppConfig copyWith({
    int? tempoAlertaMinutos,
    int? tempoLimiteMinutos,
    int? totalMesas,
    int? empresaId,
    String? apiUrl,
    bool? autoSync,
    String? hostBanco,
    int? portaBanco,
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
      hostBanco: hostBanco ?? this.hostBanco,
      portaBanco: portaBanco ?? this.portaBanco,
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
        hostBanco,
        portaBanco,
        caminhoBanco,
        usuarioBanco,
        senhaBanco,
      ];
}
