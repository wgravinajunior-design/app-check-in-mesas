import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/local_database.dart';
import '../models/mesa_model.dart';

class MesaLocalDataSource {
  final LocalDatabase databaseProvider;

  MesaLocalDataSource({LocalDatabase? database})
      : databaseProvider = database ?? LocalDatabase.instance;

  Future<List<MesaModel>> listarMesas({required int empresaId}) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        MSA_ID,
        MSA_EMPRESA,
        MSA_CODIGO,
        MSA_DESCRICAO,
        MSA_NR_PESSOAS,
        MSA_STATUS
      FROM TB_MESA
      WHERE MSA_EMPRESA = ?
      ORDER BY CAST(MSA_CODIGO AS INTEGER) ASC, MSA_CODIGO ASC
      ''',
      [empresaId],
    );

    return maps.map((map) => MesaModel.fromDbMap(map)).toList();
  }

  Future<void> inicializarMesasSeVazio({
    required int empresaId,
    required int quantidade,
  }) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> countResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS TOTAL
      FROM TB_MESA
      WHERE MSA_EMPRESA = ?
      ''',
      [empresaId],
    );

    final int total = countResult.first['TOTAL'] as int? ?? 0;
    if (total == 0) {
      final batch = db.batch();
      for (int i = 1; i <= quantidade; i++) {
        final String codigo = i.toString().padLeft(3, '0');
        batch.insert(
          'TB_MESA',
          {
            'MSA_ID': i,
            'MSA_EMPRESA': empresaId,
            'MSA_CODIGO': codigo,
            'MSA_DESCRICAO': 'Mesa $codigo',
            'MSA_NR_PESSOAS': 4,
            'MSA_STATUS': 'A',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  /// Substitui as mesas do SQLite local pelas mesas reais importadas do banco Firebird
  Future<void> sincronizarMesasEmLote({
    required int empresaId,
    required List<MesaModel> novasMesas,
  }) async {
    final db = await databaseProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        'TB_MESA',
        where: 'MSA_EMPRESA = ?',
        whereArgs: [empresaId],
      );

      final batch = txn.batch();
      for (final mesa in novasMesas) {
        batch.insert(
          'TB_MESA',
          mesa.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> atualizarStatusMesa({
    required int mesaId,
    required bool isOcupada,
  }) async {
    final db = await databaseProvider.database;
    await db.rawUpdate(
      '''
      UPDATE TB_MESA
      SET MSA_STATUS = ?
      WHERE MSA_ID = ?
      ''',
      [isOcupada ? 'O' : 'A', mesaId],
    );
  }
}
