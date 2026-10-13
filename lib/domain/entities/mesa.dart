import 'package:equatable/equatable.dart';
import 'consumo_mesa_resumo.dart';
import 'ingresso.dart';
import 'status_permanencia.dart';

/// Entidade de Negócio representando uma Mesa do restaurante
class Mesa extends Equatable {
  final int id;
  final String codigo;
  final String? descricao;
  final int numeroPessoas;
  final bool isOcupada;
  final Ingresso? ingressoAtual;
  final Duration tempoDecorrido;
  final StatusPermanencia statusPermanencia;
  final ConsumoMesaResumo? consumoResumo;

  const Mesa({
    required this.id,
    required this.codigo,
    this.descricao,
    this.numeroPessoas = 0,
    required this.isOcupada,
    this.ingressoAtual,
    this.tempoDecorrido = Duration.zero,
    this.statusPermanencia = StatusPermanencia.livre,
    this.consumoResumo,
  });

  /// Identificador legível para o usuário (ex: "Mesa 01" ou "Mesa 005")
  String get nomeExibicao {
    if (descricao != null && descricao!.trim().isNotEmpty) {
      return descricao!;
    }
    final int? numero = int.tryParse(codigo);
    if (numero != null) {
      return 'Mesa ${numero.toString().padLeft(2, '0')}';
    }
    return 'Mesa $codigo';
  }

  /// Data/Hora exata de entrada se a mesa estiver ocupada
  DateTime? get horaEntrada => ingressoAtual?.dtEntrada;

  /// Retorna true se houver pedidos registrados para a mesa após o check-in
  bool get temConsumo => consumoResumo != null && consumoResumo!.temPedidos;

  /// Quantidade de minutos desde o último pedido efetuado
  int? get minutosDesdeUltimoPedido => consumoResumo?.minutosDesdeUltimoPedido;

  /// Valor do último pedido registrado
  double get valorUltimoPedido => consumoResumo?.valorUltimoPedido ?? 0.0;

  /// Somatório total de todos os pedidos realizados nessa mesa desde o check-in
  double get valorTotalConsumo => consumoResumo?.valorTotalPedidos ?? 0.0;

  /// Quantidade total de pedidos realizados na mesa desde o check-in
  int get quantidadePedidos => consumoResumo?.quantidadePedidos ?? 0;

  Mesa copyWith({
    int? id,
    String? codigo,
    String? descricao,
    int? numeroPessoas,
    bool? isOcupada,
    Ingresso? ingressoAtual,
    bool clearIngressoAtual = false,
    Duration? tempoDecorrido,
    StatusPermanencia? statusPermanencia,
    ConsumoMesaResumo? consumoResumo,
    bool clearConsumoResumo = false,
  }) {
    return Mesa(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      numeroPessoas: numeroPessoas ?? this.numeroPessoas,
      isOcupada: isOcupada ?? this.isOcupada,
      ingressoAtual: clearIngressoAtual ? null : (ingressoAtual ?? this.ingressoAtual),
      tempoDecorrido: tempoDecorrido ?? this.tempoDecorrido,
      statusPermanencia: statusPermanencia ?? this.statusPermanencia,
      consumoResumo: clearConsumoResumo ? null : (consumoResumo ?? this.consumoResumo),
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        descricao,
        numeroPessoas,
        isOcupada,
        ingressoAtual,
        tempoDecorrido,
        statusPermanencia,
        consumoResumo,
      ];
}
