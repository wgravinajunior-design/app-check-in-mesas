import 'package:equatable/equatable.dart';

/// Entidade que representa um Produto da retaguarda Firebird (TB_PRODUTO)
class Produto extends Equatable {
  final int id;
  final int empresaId;
  final String codigo;
  final String descricao;
  final String status; // 'A' = Ativo, 'I' = Inativo, etc.
  final double precoVenda;
  final String? grupoDescricao;
  final String? referencia;
  final String? unidadeVenda;

  const Produto({
    required this.id,
    required this.empresaId,
    required this.codigo,
    required this.descricao,
    required this.status,
    required this.precoVenda,
    this.grupoDescricao,
    this.referencia,
    this.unidadeVenda,
  });

  /// Retorna se o produto está ativo para venda/pedidos
  bool get isAtivo => status.trim().toUpperCase() == 'A';

  /// Retorna o nome amigável do status
  String get statusDescricao => isAtivo ? 'Ativo' : 'Inativo';

  Produto copyWith({
    int? id,
    int? empresaId,
    String? codigo,
    String? descricao,
    String? status,
    double? precoVenda,
    String? grupoDescricao,
    String? referencia,
    String? unidadeVenda,
  }) {
    return Produto(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      precoVenda: precoVenda ?? this.precoVenda,
      grupoDescricao: grupoDescricao ?? this.grupoDescricao,
      referencia: referencia ?? this.referencia,
      unidadeVenda: unidadeVenda ?? this.unidadeVenda,
    );
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        codigo,
        descricao,
        status,
        precoVenda,
        grupoDescricao,
        referencia,
        unidadeVenda,
      ];
}
