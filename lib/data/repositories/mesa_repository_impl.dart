import '../../domain/entities/app_config.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/firebird_bridge_datasource.dart';
import '../datasources/mesa_local_datasource.dart';
import '../models/mesa_model.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaLocalDataSource localDataSource;
  final FirebirdBridgeDataSource firebirdBridgeDataSource;

  MesaRepositoryImpl({
    MesaLocalDataSource? localDataSource,
    FirebirdBridgeDataSource? firebirdBridgeDataSource,
  })  : localDataSource = localDataSource ?? MesaLocalDataSource(),
        firebirdBridgeDataSource =
            firebirdBridgeDataSource ?? FirebirdBridgeDataSource();

  @override
  Future<List<Mesa>> listarMesas({required int empresaId}) {
    return localDataSource.listarMesas(empresaId: empresaId);
  }

  @override
  Future<void> inicializarMesasPadrao({
    required int empresaId,
    required int quantidade,
  }) {
    return localDataSource.inicializarMesasSeVazio(
      empresaId: empresaId,
      quantidade: quantidade,
    );
  }

  @override
  Future<String> testarConexaoFirebird({required AppConfig config}) {
    return firebirdBridgeDataSource.testarConexaoDirectFirebird(config);
  }

  @override
  Future<int> importarMesasDaBaseFirebird({
    required AppConfig config,
  }) async {
    final List<MesaModel> mesasFirebird =
        await firebirdBridgeDataSource.extrairMesasDaBaseFirebird(
      config: config,
    );

    await localDataSource.sincronizarMesasEmLote(
      empresaId: config.empresaId,
      novasMesas: mesasFirebird,
    );

    return mesasFirebird.length;
  }

  @override
  Future<void> atualizarStatusMesa({
    required int mesaId,
    required bool isOcupada,
  }) {
    return localDataSource.atualizarStatusMesa(
      mesaId: mesaId,
      isOcupada: isOcupada,
    );
  }
}
