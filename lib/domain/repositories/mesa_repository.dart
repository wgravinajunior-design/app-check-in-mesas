import '../entities/app_config.dart';
import '../entities/consumo_mesa_resumo.dart';
import '../entities/mesa.dart';

abstract class MesaRepository {
  /// Obtém a listagem completa de mesas cadastradas
  Future<List<Mesa>> listarMesas({required int empresaId});

  /// Inicializa ou popula as mesas padrão se a tabela estiver vazia
  Future<void> inicializarMesasPadrao({
    required int empresaId,
    required int quantidade,
  });

  /// Testa a conexão direta com o Firebird 5.0 usando host, porta e caminho
  Future<String> testarConexaoFirebird({required AppConfig config});

  /// Importa as mesas diretamente da base Firebird (.FDB) e sincroniza a base local
  Future<int> importarMesasDaBaseFirebird({required AppConfig config});

  /// Atualiza o status de ocupação da mesa na retaguarda
  Future<void> atualizarStatusMesa({
    required int mesaId,
    required bool isOcupada,
  });

  /// Obtém o resumo dos pedidos de uma mesa feitos após o check-in (modelo pré-pago)
  Future<ConsumoMesaResumo> obterConsumoMesa({
    required int empresaId,
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
    required AppConfig config,
  });

  /// Obtém o resumo dos pedidos em lote para todas as mesas ocupadas (modelo pré-pago)
  Future<Map<int, ConsumoMesaResumo>> obterConsumoMesasOcupadas({
    required int empresaId,
    required List<Mesa> mesasOcupadas,
    required AppConfig config,
  });

  /// Executa a consulta consolidada oficial via Firebird (CTE Mesas + Ingressos + Pedidos)
  Future<List<Mesa>> carregarMesasCompletasFirebird({required AppConfig config});

  /// Executa o INSERT do Check-in diretamente na TB_INGRESSO do Firebird
  Future<void> executarCheckInFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraEntrada,
    String? observacao,
  });

  /// Executa o UPDATE do Check-out diretamente na TB_INGRESSO do Firebird
  Future<void> executarCheckOutFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraSaida,
  });
}

