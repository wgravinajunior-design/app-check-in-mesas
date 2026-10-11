import '../entities/app_config.dart';
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
}
