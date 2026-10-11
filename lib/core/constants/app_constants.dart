class AppConstants {
  // Configurações padrão de permanência em minutos
  static const int defaultTempoAlertaMinutos = 90; // 1h30m
  static const int defaultTempoLimiteMinutos = 120; // 2h00m
  static const int defaultTotalMesas = 30;
  static const int defaultEmpresaId = 1;

  // Status da Tabela TB_INGRESSO
  static const String statusIngressoAberto = 'A';
  static const String statusIngressoFinalizado = 'F';

  // Status da Mesa
  static const String statusMesaLivre = 'A'; // Aberta / Livre
  static const String statusMesaOcupada = 'O'; // Ocupada

  // Chaves do SharedPreferences
  static const String keyTempoAlerta = 'config_tempo_alerta';
  static const String keyTempoLimite = 'config_tempo_limite';
  static const String keyTotalMesas = 'config_total_mesas';
  static const String keyEmpresaId = 'config_empresa_id';
  static const String keyApiUrl = 'config_api_url';
  static const String keyAutoSync = 'config_auto_sync';
}
