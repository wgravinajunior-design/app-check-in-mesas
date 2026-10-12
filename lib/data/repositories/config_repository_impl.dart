import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  @override
  Future<AppConfig> carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();

    final int tempoAlerta = prefs.getInt(AppConstants.keyTempoAlerta) ??
        AppConstants.defaultTempoAlertaMinutos;
    final int tempoLimite = prefs.getInt(AppConstants.keyTempoLimite) ??
        AppConstants.defaultTempoLimiteMinutos;
    final int totalMesas = prefs.getInt(AppConstants.keyTotalMesas) ??
        AppConstants.defaultTotalMesas;
    final int empresaId = prefs.getInt(AppConstants.keyEmpresaId) ??
        AppConstants.defaultEmpresaId;
    final String apiUrl = prefs.getString(AppConstants.keyApiUrl) ??
        'http://localhost:8080/api';
    final bool autoSync = prefs.getBool(AppConstants.keyAutoSync) ?? false;
    final String hostBanco = prefs.getString(AppConstants.keyHostBanco) ??
        AppConstants.defaultHostFirebird;
    final int portaBanco = prefs.getInt(AppConstants.keyPortaBanco) ??
        AppConstants.defaultPortaFirebird;
    final String caminhoBanco = prefs.getString(AppConstants.keyCaminhoBanco) ??
        AppConstants.defaultCaminhoBancoFirebird;
    final String usuarioBanco = prefs.getString(AppConstants.keyUsuarioBanco) ??
        AppConstants.defaultUsuarioFirebird;
    final String senhaBanco = prefs.getString(AppConstants.keySenhaBanco) ??
        AppConstants.defaultSenhaFirebird;
    final bool permitirTransferirMesas =
        prefs.getBool(AppConstants.keyPermitirTransferirMesas) ?? true;
    final bool alertaSonoro =
        prefs.getBool(AppConstants.keyAlertaSonoro) ?? true;
    final bool modoEscuro =
        prefs.getBool(AppConstants.keyModoEscuro) ?? false;

    return AppConfig(
      tempoAlertaMinutos: tempoAlerta,
      tempoLimiteMinutos: tempoLimite,
      totalMesas: totalMesas,
      empresaId: empresaId,
      apiUrl: apiUrl,
      autoSync: autoSync,
      hostBanco: hostBanco,
      portaBanco: portaBanco,
      caminhoBanco: caminhoBanco,
      usuarioBanco: usuarioBanco,
      senhaBanco: senhaBanco,
      permitirTransferirMesas: permitirTransferirMesas,
      alertaSonoro: alertaSonoro,
      modoEscuro: modoEscuro,
    );
  }

  @override
  Future<void> salvarConfiguracoes(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(AppConstants.keyTempoAlerta, config.tempoAlertaMinutos);
    await prefs.setInt(AppConstants.keyTempoLimite, config.tempoLimiteMinutos);
    await prefs.setInt(AppConstants.keyTotalMesas, config.totalMesas);
    await prefs.setInt(AppConstants.keyEmpresaId, config.empresaId);
    await prefs.setString(AppConstants.keyApiUrl, config.apiUrl);
    await prefs.setBool(AppConstants.keyAutoSync, config.autoSync);
    await prefs.setString(AppConstants.keyHostBanco, config.hostBanco);
    await prefs.setInt(AppConstants.keyPortaBanco, config.portaBanco);
    await prefs.setString(AppConstants.keyCaminhoBanco, config.caminhoBanco);
    await prefs.setString(AppConstants.keyUsuarioBanco, config.usuarioBanco);
    await prefs.setString(AppConstants.keySenhaBanco, config.senhaBanco);
    await prefs.setBool(
        AppConstants.keyPermitirTransferirMesas, config.permitirTransferirMesas);
    await prefs.setBool(AppConstants.keyAlertaSonoro, config.alertaSonoro);
    await prefs.setBool(AppConstants.keyModoEscuro, config.modoEscuro);
  }
}
