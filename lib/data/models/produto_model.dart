import '../../domain/entities/produto.dart';

class ProdutoModel extends Produto {
  const ProdutoModel({
    required super.id,
    required super.empresaId,
    required super.codigo,
    required super.descricao,
    required super.status,
    required super.precoVenda,
    super.grupoDescricao,
    super.referencia,
    super.unidadeVenda,
  });

  factory ProdutoModel.fromEntity(Produto entity) {
    return ProdutoModel(
      id: entity.id,
      empresaId: entity.empresaId,
      codigo: entity.codigo,
      descricao: entity.descricao,
      status: entity.status,
      precoVenda: entity.precoVenda,
      grupoDescricao: entity.grupoDescricao,
      referencia: entity.referencia,
      unidadeVenda: entity.unidadeVenda,
    );
  }

  factory ProdutoModel.fromFirebirdRow(Map<String, dynamic> row) {
    final int id = int.tryParse(row['PRD_ID']?.toString() ?? '0') ?? 0;
    final int empresaId = int.tryParse(row['PRD_EMPRESA']?.toString() ?? '1') ?? 1;
    final String codigo = (row['PRD_CODIGO']?.toString() ?? id.toString()).trim();
    final String descricao = (row['PRD_DESCRICAO']?.toString() ?? '').trim();
    final String status = (row['PRD_STATUS']?.toString() ?? 'A').trim();
    final double precoVenda = double.tryParse(row['PRD_PRECO_VENDA']?.toString() ?? '0.0') ?? 0.0;
    final String? grupoDescricao = row['PGRU_DESCRICAO']?.toString().trim();
    final String? referencia = row['PRD_REFERENCIA']?.toString().trim();
    final String? unidadeVenda = row['PRD_UN_VENDA']?.toString().trim();

    return ProdutoModel(
      id: id,
      empresaId: empresaId,
      codigo: codigo.isEmpty ? id.toString() : codigo,
      descricao: descricao,
      status: status.isEmpty ? 'A' : status,
      precoVenda: precoVenda,
      grupoDescricao: (grupoDescricao != null && grupoDescricao.isNotEmpty) ? grupoDescricao : null,
      referencia: (referencia != null && referencia.isNotEmpty) ? referencia : null,
      unidadeVenda: (unidadeVenda != null && unidadeVenda.isNotEmpty) ? unidadeVenda : null,
    );
  }

  factory ProdutoModel.fromLocalDb(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['PRD_ID'] as int? ?? 0,
      empresaId: map['PRD_EMPRESA'] as int? ?? 1,
      codigo: (map['PRD_CODIGO'] as String? ?? '').trim(),
      descricao: (map['PRD_DESCRICAO'] as String? ?? '').trim(),
      status: (map['PRD_STATUS'] as String? ?? 'A').trim(),
      precoVenda: (map['PRD_PRECO_VENDA'] as num?)?.toDouble() ?? 0.0,
      grupoDescricao: map['PRD_GRUPO_DESC'] as String?,
      referencia: map['PRD_REFERENCIA'] as String?,
      unidadeVenda: map['PRD_UN_VENDA'] as String?,
    );
  }

  Map<String, dynamic> toMapLocalDb() {
    return {
      'PRD_ID': id,
      'PRD_EMPRESA': empresaId,
      'PRD_CODIGO': codigo,
      'PRD_DESCRICAO': descricao,
      'PRD_STATUS': status,
      'PRD_PRECO_VENDA': precoVenda,
      'PRD_GRUPO_DESC': grupoDescricao,
      'PRD_REFERENCIA': referencia,
      'PRD_UN_VENDA': unidadeVenda,
    };
  }
}
