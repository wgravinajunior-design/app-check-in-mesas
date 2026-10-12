import 'package:equatable/equatable.dart';
import 'ingresso.dart';
import 'status_permanencia.dart';

class Comanda extends Equatable {
  final int id;
  final int empresaId;
  final String codigo;
  final String? descricao;
  final bool isOcupada;
  final Ingresso? ingressoAtual;
  final Duration tempoDecorrido;
  final StatusPermanencia statusPermanencia;
  final double valorConsumo;

  const Comanda({
    required this.id,
    required this.empresaId,
    required this.codigo,
    this.descricao,
    this.isOcupada = false,
    this.ingressoAtual,
    this.tempoDecorrido = Duration.zero,
    this.statusPermanencia = StatusPermanencia.livre,
    this.valorConsumo = 0.0,
  });

  String get nomeExibicao => descricao != null && descricao!.isNotEmpty
      ? descricao!
      : 'Comanda $codigo';

  DateTime? get horaEntrada => ingressoAtual?.dtEntrada;

  Comanda copyWith({
    int? id,
    int? empresaId,
    String? codigo,
    String? descricao,
    bool? isOcupada,
    Ingresso? ingressoAtual,
    bool clearIngressoAtual = false,
    Duration? tempoDecorrido,
    StatusPermanencia? statusPermanencia,
    double? valorConsumo,
  }) {
    return Comanda(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      isOcupada: isOcupada ?? this.isOcupada,
      ingressoAtual: clearIngressoAtual ? null : (ingressoAtual ?? this.ingressoAtual),
      tempoDecorrido: tempoDecorrido ?? this.tempoDecorrido,
      statusPermanencia: statusPermanencia ?? this.statusPermanencia,
      valorConsumo: valorConsumo ?? this.valorConsumo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        codigo,
        descricao,
        isOcupada,
        ingressoAtual,
        tempoDecorrido,
        statusPermanencia,
        valorConsumo,
      ];
}
