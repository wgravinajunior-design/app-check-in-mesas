import '../entities/app_config.dart';

abstract class ConfigRepository {
  Future<AppConfig> carregarConfiguracoes();
  Future<void> salvarConfiguracoes(AppConfig config);
}
