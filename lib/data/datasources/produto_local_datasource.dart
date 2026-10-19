import 'package:sqflite/sqflite.dart';
import '../../core/database/local_database.dart';
import '../models/produto_model.dart';

class ProdutoLocalDataSource {
  final LocalDatabase localDatabase;

  ProdutoLocalDataSource({LocalDatabase? localDatabase})
      : localDatabase = localDatabase ?? LocalDatabase.instance;

  Future<List<ProdutoModel>> listarProdutosLocal({required int empresaId}) async {
    final db = await localDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'TB_PRODUTO',
      where: 'PRD_EMPRESA = ?',
      whereArgs: [empresaId],
      orderBy: 'PRD_DESCRICAO ASC',
    );

    return maps.map((m) => ProdutoModel.fromLocalDb(m)).toList();
  }

  Future<void> salvarProdutosEmLote({
    required int empresaId,
    required List<ProdutoModel> produtos,
  }) async {
    final db = await localDatabase.database;
    final batch = db.batch();

    for (final p in produtos) {
      batch.insert(
        'TB_PRODUTO',
        p.toMapLocalDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> atualizarStatusLocal({
    required int produtoId,
    required String novoStatus,
  }) async {
    final db = await localDatabase.database;
    await db.update(
      'TB_PRODUTO',
      {'PRD_STATUS': novoStatus},
      where: 'PRD_ID = ?',
      whereArgs: [produtoId],
    );
  }
}
