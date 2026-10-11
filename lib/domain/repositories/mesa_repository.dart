import '../entities/mesa.dart';

abstract class MesaRepository {
  /// Obtém a listagem completa de mesas cadastradas
  Future<List<Mesa>> listarMesas({required int empresaId});

  /// Inicializa ou popula as mesas padrão se a tabela estiver vazia
  Future<void> inicializarMesasPadrao({
    required int empresaId,
    required int quantidade,
  });

  /// Importa as mesas diretamente da base Firebird (.FDB) e sincroniza a base local
  Future<int> importarMesasDaBaseFirebird({
    required String caminhoBanco,
    required String usuario,
    required String senha,
    required int empresaId,
  });

  /// Atualiza o status de ocupação da mesa na retaguarda
  Future<void> atualizarStatusMesa({
    required int mesaId,
    required bool isOcupada,
  });
}
