import 'package:equatable/equatable.dart';

/// Representa um pedido lançado para a mesa no modelo pré-pago ou PDV
class PedidoResumo extends Equatable {
  final int id;
  final int empresaId;
  final int mesaId;
  final DateTime dataHoraLancamento;
  final double valorTotal;
  final String status;

  const PedidoResumo({
    required this.id,
    required this.empresaId,
    required this.mesaId,
    required this.dataHoraLancamento,
    required this.valorTotal,
    this.status = 'F',
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        mesaId,
        dataHoraLancamento,
        valorTotal,
        status,
      ];
}
