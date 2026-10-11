import '../entities/ingresso.dart';

abstract class IngressoRepository {
  /// Obtém o próximo ID disponível para a empresa especificada
  Future<int> obterProximoId(int empresaId);

  /// Registra um novo ingresso (Check-in) com persistência em TB_INGRESSO
  Future<Ingresso> realizarCheckIn({
    required int empresaId,
    required String codigoMesa,
    required DateTime dataHoraEntrada,
    String? observacao,
  });

  /// Realiza o Check-out atualizando o ingresso com data de saída e duração
  Future<Ingresso> realizarCheckOut({
    required int empresaId,
    required int ingressoId,
    required DateTime dataHoraSaida,
  });

  /// Busca o ingresso em aberto (status 'A') para uma determinada mesa
  Future<Ingresso?> obterIngressoAbertoPorMesa({
    required int empresaId,
    required String codigoMesa,
  });

  /// Lista todos os ingressos registrados para auditoria e histórico
  Future<List<Ingresso>> listarHistorico({
    required int empresaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  });

  /// Lista todos os ingressos atualmente abertos
  Future<List<Ingresso>> listarIngressosAbertos({
    required int empresaId,
  });
}
