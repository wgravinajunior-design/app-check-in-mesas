import 'package:sqflite/sqflite.dart';
import '../../core/database/local_database.dart';
import '../../domain/entities/consumo_mesa_resumo.dart';
import '../models/pedido_resumo_model.dart';

class PedidoLocalDataSource {
  final LocalDatabase databaseProvider;

  PedidoLocalDataSource({LocalDatabase? database})
      : databaseProvider = database ?? LocalDatabase.instance;

  /// Insere ou atualiza pedidos no SQLite local em lote
  Future<void> salvarPedidosEmLote({
    required List<PedidoResumoModel> pedidos,
  }) async {
    if (pedidos.isEmpty) return;
    final db = await databaseProvider.database;
    final batch = db.batch();
    for (final pedido in pedidos) {
      batch.insert(
        'TB_PEDIDO_VENDA',
        pedido.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Consulta pedidos da mesa feitos após o check-in no modelo pré-pago
  /// Ordenados decrescente pela data/hora para capturar o mais recente
  Future<List<PedidoResumoModel>> listarPedidosMesaAposCheckIn({
    required int empresaId,
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
  }) async {
    final db = await databaseProvider.database;
    final int codigoInt = int.tryParse(codigoMesa) ?? mesaId;
    final String isoCheckIn = dataCheckIn.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        PEV_ID,
        PEV_EMPRESA,
        PEV_MESA,
        PEV_DT_LANCAMENTO,
        PEV_VALOR_TOTAL,
        PEV_STATUS
      FROM TB_PEDIDO_VENDA
      WHERE PEV_EMPRESA = ?
        AND (PEV_MESA = ? OR PEV_MESA = ?)
        AND PEV_DT_LANCAMENTO >= ?
        AND PEV_STATUS != 'C'
      ORDER BY PEV_DT_LANCAMENTO DESC
      ''',
      [empresaId, mesaId, codigoInt, isoCheckIn],
    );

    return maps.map((m) => PedidoResumoModel.fromDbMap(m)).toList();
  }

  /// Retorna o resumo consolidado de consumo e último pedido para uma mesa específica
  Future<ConsumoMesaResumo> obterConsumoMesa({
    required int empresaId,
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
    DateTime? agora,
  }) async {
    final List<PedidoResumoModel> pedidos = await listarPedidosMesaAposCheckIn(
      empresaId: empresaId,
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      dataCheckIn: dataCheckIn,
    );

    return ConsumoMesaResumo.processar(
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      dataCheckIn: dataCheckIn,
      pedidosFiltrados: pedidos,
      agora: agora,
    );
  }
}
