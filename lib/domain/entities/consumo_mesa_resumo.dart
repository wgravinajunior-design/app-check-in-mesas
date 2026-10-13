import 'package:equatable/equatable.dart';
import 'pedido_resumo.dart';

/// Resumo dos pedidos e consumo de uma mesa após o momento do Check-in
///
/// Regras de Negócio e Requisitos:
/// 1. Modelo pré-pago: Não considere status de pedido em aberto nem abertura formal de mesa;
///    cada pedido é pago no ato.
/// 2. Filtro temporal: Considere apenas os pedidos feitos após o momento do check-in da mesa informada.
/// 3. Último pedido: Como uma mesa pode ter vários pedidos ao longo do tempo, ordene pela data/hora
///    de forma decrescente para capturar a transação mais recente.
/// 4. Tempo decorrido: Calcule a diferença em minutos entre a data/hora do último pedido e a data/hora
///    atual (para exibir há quantos minutos o cliente pediu pela última vez).
/// 5. Valores: Traga tanto o valor do último pedido quanto o somatório total de todos os pedidos
///    realizados nessa mesa desde o check-in.
class ConsumoMesaResumo extends Equatable {
  final int mesaId;
  final String codigoMesa;
  final DateTime dataCheckIn;
  final PedidoResumo? ultimoPedido;
  final int? minutosDesdeUltimoPedido;
  final double valorUltimoPedido;
  final double valorTotalPedidos;
  final int quantidadePedidos;
  final List<PedidoResumo> pedidos;

  const ConsumoMesaResumo({
    required this.mesaId,
    required this.codigoMesa,
    required this.dataCheckIn,
    this.ultimoPedido,
    this.minutosDesdeUltimoPedido,
    this.valorUltimoPedido = 0.0,
    this.valorTotalPedidos = 0.0,
    this.quantidadePedidos = 0,
    this.pedidos = const [],
  });

  /// Retorna true se houver ao menos um pedido registrado para a mesa após o check-in
  bool get temPedidos => quantidadePedidos > 0 && ultimoPedido != null;

  /// Recalcula os minutos decorridos desde o último pedido com base no instante fornecido
  ConsumoMesaResumo comHoraAtual(DateTime agora) {
    if (ultimoPedido == null) return this;
    final int minutos = agora.difference(ultimoPedido!.dataHoraLancamento).inMinutes;
    return copyWith(minutosDesdeUltimoPedido: minutos < 0 ? 0 : minutos);
  }

  /// Constrói um resumo a partir de uma lista de pedidos brutos ordenados decrescente
  factory ConsumoMesaResumo.processar({
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
    required List<PedidoResumo> pedidosFiltrados,
    DateTime? agora,
  }) {
    final DateTime momentoAtual = agora ?? DateTime.now();

    if (pedidosFiltrados.isEmpty) {
      return ConsumoMesaResumo(
        mesaId: mesaId,
        codigoMesa: codigoMesa,
        dataCheckIn: dataCheckIn,
        ultimoPedido: null,
        minutosDesdeUltimoPedido: null,
        valorUltimoPedido: 0.0,
        valorTotalPedidos: 0.0,
        quantidadePedidos: 0,
        pedidos: const [],
      );
    }

    // Garante ordenação decrescente pela data/hora de lançamento para capturar a transação mais recente
    final List<PedidoResumo> ordenados = List<PedidoResumo>.from(pedidosFiltrados)
      ..sort((a, b) => b.dataHoraLancamento.compareTo(a.dataHoraLancamento));

    final PedidoResumo maisRecente = ordenados.first;
    final int minutosDecorrido = momentoAtual.difference(maisRecente.dataHoraLancamento).inMinutes;

    final double somatorioTotal = ordenados.fold(
      0.0,
      (total, p) => total + p.valorTotal,
    );

    return ConsumoMesaResumo(
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      dataCheckIn: dataCheckIn,
      ultimoPedido: maisRecente,
      minutosDesdeUltimoPedido: minutosDecorrido < 0 ? 0 : minutosDecorrido,
      valorUltimoPedido: maisRecente.valorTotal,
      valorTotalPedidos: somatorioTotal,
      quantidadePedidos: ordenados.length,
      pedidos: ordenados,
    );
  }

  ConsumoMesaResumo copyWith({
    int? mesaId,
    String? codigoMesa,
    DateTime? dataCheckIn,
    PedidoResumo? ultimoPedido,
    bool clearUltimoPedido = false,
    int? minutosDesdeUltimoPedido,
    double? valorUltimoPedido,
    double? valorTotalPedidos,
    int? quantidadePedidos,
    List<PedidoResumo>? pedidos,
  }) {
    return ConsumoMesaResumo(
      mesaId: mesaId ?? this.mesaId,
      codigoMesa: codigoMesa ?? this.codigoMesa,
      dataCheckIn: dataCheckIn ?? this.dataCheckIn,
      ultimoPedido: clearUltimoPedido ? null : (ultimoPedido ?? this.ultimoPedido),
      minutosDesdeUltimoPedido: minutosDesdeUltimoPedido ?? this.minutosDesdeUltimoPedido,
      valorUltimoPedido: valorUltimoPedido ?? this.valorUltimoPedido,
      valorTotalPedidos: valorTotalPedidos ?? this.valorTotalPedidos,
      quantidadePedidos: quantidadePedidos ?? this.quantidadePedidos,
      pedidos: pedidos ?? this.pedidos,
    );
  }

  @override
  List<Object?> get props => [
        mesaId,
        codigoMesa,
        dataCheckIn,
        ultimoPedido,
        minutosDesdeUltimoPedido,
        valorUltimoPedido,
        valorTotalPedidos,
        quantidadePedidos,
        pedidos,
      ];
}
