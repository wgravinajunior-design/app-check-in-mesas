import '../../domain/entities/app_config.dart';
import '../../domain/entities/comanda.dart';
import '../../domain/repositories/comanda_repository.dart';
import '../datasources/comanda_local_datasource.dart';

class ComandaRepositoryImpl implements ComandaRepository {
  final ComandaLocalDataSource localDataSource;

  ComandaRepositoryImpl({
    ComandaLocalDataSource? localDataSource,
  }) : localDataSource = localDataSource ?? ComandaLocalDataSource();

  @override
  Future<List<Comanda>> listarComandas({required int empresaId}) {
    return localDataSource.listarComandas(empresaId: empresaId);
  }

  @override
  Future<void> inicializarComandasPadrao({
    required int empresaId,
    required int quantidade,
  }) {
    return localDataSource.inicializarComandasPadrao(
      empresaId: empresaId,
      quantidade: quantidade,
    );
  }

  @override
  Future<void> atualizarStatusComanda({
    required int comandaId,
    required bool isOcupada,
  }) {
    return localDataSource.atualizarStatusComanda(
      comandaId: comandaId,
      isOcupada: isOcupada,
    );
  }

  @override
  Future<int> importarComandasDoFirebird({required AppConfig config}) async {
    // Garante que o lote padrão de comandas configurado no AppConfig esteja presente
    final int qtd = config.totalComandas > 0 ? config.totalComandas : 50;
    await localDataSource.inicializarComandasPadrao(
      empresaId: config.empresaId,
      quantidade: qtd,
    );
    final lista = await localDataSource.listarComandas(empresaId: config.empresaId);
    return lista.length;
  }
}
