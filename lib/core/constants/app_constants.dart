class AppConstants {
  // Configurações padrão de permanência em minutos
  static const int defaultTempoAlertaMinutos = 90; // 1h30m
  static const int defaultTempoLimiteMinutos = 120; // 2h00m
  static const int defaultTotalMesas = 75; // Total de mesas cadastradas na Mansão da Torre
  static const int defaultEmpresaId = 1;

  // Configurações padrão de conexão (dinâmicas por dispositivo/ambiente)
  static const String defaultHostFirebird = ''; // Informado pelo usuário por máquina
  static const int defaultPortaFirebird = 3060; // Porta padrão TCP Firebird
  static const String defaultCaminhoBancoFirebird = ''; // Caminho da base configurável
  static const String defaultUsuarioFirebird = 'SYSDBA';
  static const String defaultSenhaFirebird = 'masterkey';

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
  static const String keyHostBanco = 'config_host_firebird';
  static const String keyPortaBanco = 'config_porta_firebird';
  static const String keyCaminhoBanco = 'config_caminho_banco_firebird';
  static const String keyUsuarioBanco = 'config_usuario_firebird';
  static const String keySenhaBanco = 'config_senha_firebird';
  static const String keyPermitirTransferirMesas = 'config_permitir_transferir_mesas';
  static const String keyAlertaSonoro = 'config_alerta_sonoro';
  static const String keyModoEscuro = 'config_modo_escuro';
}
