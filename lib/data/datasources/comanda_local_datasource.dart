import '../../core/database/local_database.dart';
import '../../domain/entities/comanda.dart';

class ComandaLocalDataSource {
  final LocalDatabase databaseProvider;

  ComandaLocalDataSource({LocalDatabase? database})
      : databaseProvider = database ?? LocalDatabase.instance;

  Future<void> inicializarComandasPadrao({
    required int empresaId,
    required int quantidade,
  }) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> existentes = await db.query(
      'TB_COMANDA',
      where: 'COM_EMPRESA = ?',
      whereArgs: [empresaId],
      limit: 1,
    );

    if (existentes.isEmpty) {
      final batch = db.batch();
      for (int i = 1; i <= quantidade; i++) {
        final String codigo = i.toString().padLeft(3, '0');
        batch.insert('TB_COMANDA', {
          'COM_ID': i,
          'COM_EMPRESA': empresaId,
          'COM_CODIGO': codigo,
          'COM_DESCRICAO': 'Comanda $codigo',
          'COM_STATUS': 'A',
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<Comanda>> listarComandas({required int empresaId}) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'TB_COMANDA',
      where: 'COM_EMPRESA = ?',
      whereArgs: [empresaId],
      orderBy: 'COM_ID ASC',
    );

    return maps.map((map) {
      final bool isOcupada = (map['COM_STATUS'] as String? ?? 'A') == 'O';
      return Comanda(
        id: map['COM_ID'] as int,
        empresaId: map['COM_EMPRESA'] as int,
        codigo: map['COM_CODIGO'] as String,
        descricao: map['COM_DESCRICAO'] as String?,
        isOcupada: isOcupada,
      );
    }).toList();
  }

  Future<void> atualizarStatusComanda({
    required int comandaId,
    required bool isOcupada,
  }) async {
    final db = await databaseProvider.database;
    await db.update(
      'TB_COMANDA',
      {'COM_STATUS': isOcupada ? 'O' : 'A'},
      where: 'COM_ID = ?',
      whereArgs: [comandaId],
    );
  }
}
