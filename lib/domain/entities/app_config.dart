import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class AppConfig extends Equatable {
  final int tempoVerdeMinutos;
  final int tempoAmareloMinutos;
  final int tempoVermelhoMinutos;
  final int totalMesas;
  final int empresaId;
  final String apiUrl;
  final bool autoSync;
  final String hostBanco;
  final int portaBanco;
  final String caminhoBanco;
  final String usuarioBanco;
  final String senhaBanco;
  final bool permitirTransferirMesas;
  final bool alertaSonoro;
  final bool modoEscuro;
  final bool sincronizarMesas;
  final bool sincronizarComandas;
  final int totalComandas;

  // Getters para compatibilidade legada
  int get tempoAlertaMinutos => tempoAmareloMinutos;
  int get tempoLimiteMinutos => tempoVermelhoMinutos;

  const AppConfig({
    this.tempoVerdeMinutos = AppConstants.defaultTempoVerdeMinutos,
    this.tempoAmareloMinutos = AppConstants.defaultTempoAmareloMinutos,
    this.tempoVermelhoMinutos = AppConstants.defaultTempoVermelhoMinutos,
    this.totalMesas = AppConstants.defaultTotalMesas,
    this.empresaId = AppConstants.defaultEmpresaId,
    this.apiUrl = 'http://localhost:8080/api',
    this.autoSync = false,
    this.hostBanco = AppConstants.defaultHostFirebird,
    this.portaBanco = AppConstants.defaultPortaFirebird,
    this.caminhoBanco = AppConstants.defaultCaminhoBancoFirebird,
    this.usuarioBanco = AppConstants.defaultUsuarioFirebird,
    this.senhaBanco = AppConstants.defaultSenhaFirebird,
    this.permitirTransferirMesas = true,
    this.alertaSonoro = true,
    this.modoEscuro = false,
    this.sincronizarMesas = true,
    this.sincronizarComandas = false,
    this.totalComandas = AppConstants.defaultTotalComandas,
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
    int? tempoVerdeMinutos,
    int? tempoAmareloMinutos,
    int? tempoVermelhoMinutos,
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
    bool? permitirTransferirMesas,
    bool? alertaSonoro,
    bool? modoEscuro,
    bool? sincronizarMesas,
    bool? sincronizarComandas,
    int? totalComandas,
  }) {
    return AppConfig(
      tempoVerdeMinutos: tempoVerdeMinutos ?? this.tempoVerdeMinutos,
      tempoAmareloMinutos: tempoAmareloMinutos ?? tempoAlertaMinutos ?? this.tempoAmareloMinutos,
      tempoVermelhoMinutos: tempoVermelhoMinutos ?? tempoLimiteMinutos ?? this.tempoVermelhoMinutos,
      totalMesas: totalMesas ?? this.totalMesas,
      empresaId: empresaId ?? this.empresaId,
      apiUrl: apiUrl ?? this.apiUrl,
      autoSync: autoSync ?? this.autoSync,
      hostBanco: hostBanco ?? this.hostBanco,
      portaBanco: portaBanco ?? this.portaBanco,
      caminhoBanco: caminhoBanco ?? this.caminhoBanco,
      usuarioBanco: usuarioBanco ?? this.usuarioBanco,
      senhaBanco: senhaBanco ?? this.senhaBanco,
      permitirTransferirMesas: permitirTransferirMesas ?? this.permitirTransferirMesas,
      alertaSonoro: alertaSonoro ?? this.alertaSonoro,
      modoEscuro: modoEscuro ?? this.modoEscuro,
      sincronizarMesas: sincronizarMesas ?? this.sincronizarMesas,
      sincronizarComandas: sincronizarComandas ?? this.sincronizarComandas,
      totalComandas: totalComandas ?? this.totalComandas,
    );
  }

  @override
  List<Object?> get props => [
        tempoVerdeMinutos,
        tempoAmareloMinutos,
        tempoVermelhoMinutos,
        totalMesas,
        empresaId,
        apiUrl,
        autoSync,
        hostBanco,
        portaBanco,
        caminhoBanco,
        usuarioBanco,
        senhaBanco,
        permitirTransferirMesas,
        alertaSonoro,
        modoEscuro,
        sincronizarMesas,
        sincronizarComandas,
        totalComandas,
      ];
}


