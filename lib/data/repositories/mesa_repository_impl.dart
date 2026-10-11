import '../../domain/entities/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/mesa_local_datasource.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaLocalDataSource localDataSource;

  MesaRepositoryImpl({MesaLocalDataSource? localDataSource})
      : localDataSource = localDataSource ?? MesaLocalDataSource();

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
