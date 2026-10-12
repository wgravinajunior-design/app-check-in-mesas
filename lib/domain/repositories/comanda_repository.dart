import '../entities/app_config.dart';
import '../entities/comanda.dart';

abstract class ComandaRepository {
  /// Lista todas as comandas cadastradas
  Future<List<Comanda>> listarComandas({required int empresaId});

  /// Inicializa o lote padrão de comandas caso a tabela esteja vazia
  Future<void> inicializarComandasPadrao({
    required int empresaId,
    required int quantidade,
  });

  /// Atualiza o status de ocupação da comanda
  Future<void> atualizarStatusComanda({
    required int comandaId,
    required bool isOcupada,
  });

  /// Importa ou sincroniza as comandas a partir do Firebird/ERP
  Future<int> importarComandasDoFirebird({required AppConfig config});
}
