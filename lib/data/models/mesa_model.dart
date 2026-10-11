import '../../domain/entities/mesa.dart';
import '../../domain/entities/ingresso.dart';
import '../../domain/entities/status_permanencia.dart';

class MesaModel extends Mesa {
  final int empresaId;

  const MesaModel({
    required super.id,
    required this.empresaId,
    required super.codigo,
    super.descricao,
    super.numeroPessoas,
    required super.isOcupada,
    super.ingressoAtual,
    super.tempoDecorrido,
    super.statusPermanencia,
  });

  factory MesaModel.fromDbMap(
    Map<String, dynamic> map, {
    Ingresso? ingressoAtual,
    Duration tempoDecorrido = Duration.zero,
    StatusPermanencia statusPermanencia = StatusPermanencia.livre,
  }) {
    final status = map['MSA_STATUS'] as String? ?? 'A';
    final isOcupada = (status == 'O') || (ingressoAtual != null);

    return MesaModel(
      id: map['MSA_ID'] as int? ?? 0,
      empresaId: map['MSA_EMPRESA'] as int? ?? 1,
      codigo: map['MSA_CODIGO'] as String? ?? '001',
      descricao: map['MSA_DESCRICAO'] as String?,
      numeroPessoas: map['MSA_NR_PESSOAS'] as int? ?? 4,
      isOcupada: isOcupada,
      ingressoAtual: ingressoAtual,
      tempoDecorrido: tempoDecorrido,
      statusPermanencia: statusPermanencia,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'MSA_ID': id,
      'MSA_EMPRESA': empresaId,
      'MSA_CODIGO': codigo,
      'MSA_DESCRICAO': descricao,
      'MSA_NR_PESSOAS': numeroPessoas,
      'MSA_STATUS': isOcupada ? 'O' : 'A',
    };
  }

  MesaModel copyWithModel({
    int? id,
    int? empresaId,
    String? codigo,
    String? descricao,
    int? numeroPessoas,
    bool? isOcupada,
    Ingresso? ingressoAtual,
    bool clearIngressoAtual = false,
    Duration? tempoDecorrido,
    StatusPermanencia? statusPermanencia,
  }) {
    return MesaModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      numeroPessoas: numeroPessoas ?? this.numeroPessoas,
      isOcupada: isOcupada ?? this.isOcupada,
      ingressoAtual: clearIngressoAtual ? null : (ingressoAtual ?? this.ingressoAtual),
      tempoDecorrido: tempoDecorrido ?? this.tempoDecorrido,
      statusPermanencia: statusPermanencia ?? this.statusPermanencia,
    );
  }
}
