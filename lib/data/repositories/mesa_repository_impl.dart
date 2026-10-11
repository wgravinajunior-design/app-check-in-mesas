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
  Future<int> importarMesasDaBaseFirebird({
    required String caminhoBanco,
    required String usuario,
    required String senha,
    required int empresaId,
  }) async {
    final List<MesaModel> mesasFirebird =
        await firebirdBridgeDataSource.extrairMesasDaBaseFirebird(
      caminhoBanco: caminhoBanco,
      usuario: usuario,
      senha: senha,
      empresaId: empresaId,
    );

    await localDataSource.sincronizarMesasEmLote(
      empresaId: empresaId,
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
