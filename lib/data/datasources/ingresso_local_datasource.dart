import 'package:sqflite/sqflite.dart';
import '../../core/database/local_database.dart';
import '../models/ingresso_model.dart';

class IngressoLocalDataSource {
  final LocalDatabase databaseProvider;

  IngressoLocalDataSource({LocalDatabase? database})
      : databaseProvider = database ?? LocalDatabase.instance;

  Future<int> obterProximoId(int empresaId) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> resultado = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(ING_ID), 0) + 1 AS PROXIMO_ID
      FROM TB_INGRESSO
      WHERE ING_EMPRESA = ?
      ''',
      [empresaId],
    );

    if (resultado.isNotEmpty && resultado.first['PROXIMO_ID'] != null) {
      return resultado.first['PROXIMO_ID'] as int;
    }
    return 1;
  }

  Future<IngressoModel> inserir(IngressoModel ingresso) async {
    final db = await databaseProvider.database;
    await db.insert(
      'TB_INGRESSO',
      ingresso.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return ingresso;
  }

  Future<void> atualizar(IngressoModel ingresso) async {
    final db = await databaseProvider.database;
    await db.update(
      'TB_INGRESSO',
      ingresso.toDbMap(),
      where: 'ING_EMPRESA = ? AND ING_ID = ?',
      whereArgs: [ingresso.empresaId, ingresso.id],
    );
  }

  Future<IngressoModel?> obterIngressoAbertoPorMesa({
    required int empresaId,
    required String codigoMesa,
  }) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        ING_EMPRESA,
        ING_ID,
        ING_STATUS,
        ING_USUARIO,
        ING_DT_LANCAMENTO,
        ING_DT_EMISSAO,
        ING_DT_EVENTO,
        ING_HR_EVENTO,
        ING_DT_ENTRADA,
        ING_DT_SAIDA,
        ING_DURACAO,
        ING_PESSOA,
        ING_TIPO_INGRESSO,
        ING_VALOR,
        ING_OBSERVACAO,
        ING_PEDIDO,
        ING_CODIGO,
        ING_TOTAL_RECEBIDO,
        ING_TOTAL_PRODUTOS,
        ING_VALOR_DIFERENCA,
        ING_CAIXA,
        ING_FECHAMENTO,
        ING_TROCO,
        ING_TIPO_TROCO,
        ING_GERAR_FINANCEIRO
      FROM TB_INGRESSO
      WHERE ING_EMPRESA = ?
        AND ING_CODIGO = ?
        AND ING_STATUS = 'A'
      ORDER BY ING_ID DESC
      LIMIT 1
      ''',
      [empresaId, codigoMesa],
    );

    if (maps.isNotEmpty) {
      return IngressoModel.fromDbMap(maps.first);
    }
    return null;
  }

  Future<List<IngressoModel>> listarHistorico({
    required int empresaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final db = await databaseProvider.database;
    String sql = '''
      SELECT
        ING_EMPRESA,
        ING_ID,
        ING_STATUS,
        ING_USUARIO,
        ING_DT_LANCAMENTO,
        ING_DT_EMISSAO,
        ING_DT_EVENTO,
        ING_HR_EVENTO,
        ING_DT_ENTRADA,
        ING_DT_SAIDA,
        ING_DURACAO,
        ING_PESSOA,
        ING_TIPO_INGRESSO,
        ING_VALOR,
        ING_OBSERVACAO,
        ING_PEDIDO,
        ING_CODIGO,
        ING_TOTAL_RECEBIDO,
        ING_TOTAL_PRODUTOS,
        ING_VALOR_DIFERENCA,
        ING_CAIXA,
        ING_FECHAMENTO,
        ING_TROCO,
        ING_TIPO_TROCO,
        ING_GERAR_FINANCEIRO
      FROM TB_INGRESSO
      WHERE ING_EMPRESA = ?
    ''';
    final List<dynamic> params = [empresaId];

    if (dataInicio != null) {
      sql += ' AND ING_DT_ENTRADA >= ?';
      params.add(dataInicio.toIso8601String());
    }

    if (dataFim != null) {
      sql += ' AND ING_DT_ENTRADA <= ?';
      params.add(dataFim.toIso8601String());
    }

    sql += ' ORDER BY ING_DT_ENTRADA DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, params);
    return maps.map((map) => IngressoModel.fromDbMap(map)).toList();
  }

  Future<List<IngressoModel>> listarIngressosAbertos({
    required int empresaId,
  }) async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        ING_EMPRESA,
        ING_ID,
        ING_STATUS,
        ING_USUARIO,
        ING_DT_LANCAMENTO,
        ING_DT_EMISSAO,
        ING_DT_EVENTO,
        ING_HR_EVENTO,
        ING_DT_ENTRADA,
        ING_DT_SAIDA,
        ING_DURACAO,
        ING_PESSOA,
        ING_TIPO_INGRESSO,
        ING_VALOR,
        ING_OBSERVACAO,
        ING_PEDIDO,
        ING_CODIGO,
        ING_TOTAL_RECEBIDO,
        ING_TOTAL_PRODUTOS,
        ING_VALOR_DIFERENCA,
        ING_CAIXA,
        ING_FECHAMENTO,
        ING_TROCO,
        ING_TIPO_TROCO,
        ING_GERAR_FINANCEIRO
      FROM TB_INGRESSO
      WHERE ING_EMPRESA = ?
        AND ING_STATUS = 'A'
      ORDER BY ING_ID ASC
      ''',
      [empresaId],
    );

    return maps.map((map) => IngressoModel.fromDbMap(map)).toList();
  }
}
