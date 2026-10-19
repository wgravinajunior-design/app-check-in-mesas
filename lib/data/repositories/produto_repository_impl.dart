import '../../domain/entities/app_config.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/produto_repository.dart';
import '../datasources/firebird_bridge_datasource.dart';
import '../datasources/produto_local_datasource.dart';
import '../models/produto_model.dart';

class ProdutoRepositoryImpl implements ProdutoRepository {
  final FirebirdBridgeDataSource firebirdDataSource;
  final ProdutoLocalDataSource localDataSource;

  ProdutoRepositoryImpl({
    FirebirdBridgeDataSource? firebirdDataSource,
    ProdutoLocalDataSource? localDataSource,
  })  : firebirdDataSource = firebirdDataSource ?? FirebirdBridgeDataSource(),
        localDataSource = localDataSource ?? ProdutoLocalDataSource();

  @override
  Future<List<Produto>> listarProdutos({
    required AppConfig config,
    bool forcarRemoto = false,
  }) async {
    // 1. Tenta carregar da retaguarda Firebird diretamente
    try {
      final List<ProdutoModel> remotos =
          await firebirdDataSource.listarProdutosDaBaseFirebird(config: config);

      if (remotos.isNotEmpty) {
        // Atualiza o cache local
        await localDataSource.salvarProdutosEmLote(
          empresaId: config.empresaId,
          produtos: remotos,
        );
        return remotos;
      }
    } catch (_) {}

    // 2. Se falhar ou estiver offline, busca do cache SQLite local
    final locais = await localDataSource.listarProdutosLocal(
      empresaId: config.empresaId,
    );

    return locais;
  }

  @override
  Future<void> alterarStatusProduto({
    required AppConfig config,
    required Produto produto,
    required bool ativar,
    int? usuarioId,
  }) async {
    final String novoStatus = ativar ? 'A' : 'I';

    // 1. Altera no Firebird e grava auditoria
    await firebirdDataSource.alterarStatusProdutoFirebird(
      config: config,
      produto: produto,
      ativar: ativar,
      usuarioId: usuarioId ?? 1,
    );

    // 2. Atualiza no cache SQLite local
    await localDataSource.atualizarStatusLocal(
      produtoId: produto.id,
      novoStatus: novoStatus,
    );
  }
}
