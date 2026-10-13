import '../../domain/entities/pedido_resumo.dart';

class PedidoResumoModel extends PedidoResumo {
  const PedidoResumoModel({
    required super.id,
    required super.empresaId,
    required super.mesaId,
    required super.dataHoraLancamento,
    required super.valorTotal,
    super.status = 'F',
  });

  factory PedidoResumoModel.fromDbMap(Map<String, dynamic> map) {
    DateTime dataLancamento;
    final dynamic rawData = map['PEV_DT_LANCAMENTO'];
    if (rawData is DateTime) {
      dataLancamento = rawData;
    } else if (rawData is String) {
      dataLancamento = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      dataLancamento = DateTime.now();
    }

    return PedidoResumoModel(
      id: map['PEV_ID'] is int ? map['PEV_ID'] as int : int.tryParse(map['PEV_ID']?.toString() ?? '0') ?? 0,
      empresaId: map['PEV_EMPRESA'] is int
          ? map['PEV_EMPRESA'] as int
          : int.tryParse(map['PEV_EMPRESA']?.toString() ?? '1') ?? 1,
      mesaId: map['PEV_MESA'] is int
          ? map['PEV_MESA'] as int
          : int.tryParse(map['PEV_MESA']?.toString() ?? '0') ?? 0,
      dataHoraLancamento: dataLancamento,
      valorTotal: (map['PEV_VALOR_TOTAL'] is num)
          ? (map['PEV_VALOR_TOTAL'] as num).toDouble()
          : double.tryParse(map['PEV_VALOR_TOTAL']?.toString() ?? '0.0') ?? 0.0,
      status: (map['PEV_STATUS']?.toString() ?? 'F').trim(),
    );
  }

  factory PedidoResumoModel.fromFirebirdRow(Map<String, dynamic> row) {
    DateTime dataLancamento;
    final dynamic rawData = row['PEV_DT_LANCAMENTO'];
    if (rawData is DateTime) {
      dataLancamento = rawData;
    } else if (rawData != null) {
      final str = rawData.toString().trim();
      dataLancamento = DateTime.tryParse(str) ??
          DateTime.tryParse(str.replaceAll(' ', 'T')) ??
          DateTime.now();
    } else {
      dataLancamento = DateTime.now();
    }

    return PedidoResumoModel(
      id: int.tryParse(row['PEV_ID']?.toString() ?? '0') ?? 0,
      empresaId: int.tryParse(row['PEV_EMPRESA']?.toString() ?? '1') ?? 1,
      mesaId: int.tryParse(row['PEV_MESA']?.toString() ?? '0') ?? 0,
      dataHoraLancamento: dataLancamento,
      valorTotal: double.tryParse(row['PEV_VALOR_TOTAL']?.toString() ?? '0.0') ?? 0.0,
      status: (row['PEV_STATUS']?.toString() ?? 'F').trim(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'PEV_ID': id,
      'PEV_EMPRESA': empresaId,
      'PEV_MESA': mesaId,
      'PEV_DT_LANCAMENTO': dataHoraLancamento.toIso8601String(),
      'PEV_VALOR_TOTAL': valorTotal,
      'PEV_STATUS': status,
    };
  }
}
