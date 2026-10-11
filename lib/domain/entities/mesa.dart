import 'package:equatable/equatable.dart';
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

  const Mesa({
    required this.id,
    required this.codigo,
    this.descricao,
    this.numeroPessoas = 4,
    required this.isOcupada,
    this.ingressoAtual,
    this.tempoDecorrido = Duration.zero,
    this.statusPermanencia = StatusPermanencia.livre,
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
      ];
}
