import '../../domain/entities/ingresso.dart';

class IngressoModel extends Ingresso {
  const IngressoModel({
    required super.empresaId,
    required super.id,
    required super.status,
    super.usuarioId,
    super.dtLancamento,
    super.dtEmissao,
    super.dtEvento,
    super.hrEvento,
    super.dtEntrada,
    super.dtSaida,
    super.duracaoMinutos,
    super.pessoaId,
    super.tipoIngressoId,
    super.valor,
    super.observacao,
    super.pedidoId,
    required super.codigoMesa,
    super.totalRecebido,
    super.totalProdutos,
    super.valorDiferenca,
    super.caixaId,
    super.fechamentoId,
    super.troco,
    super.tipoTroco,
    super.gerarFinanceiro,
  });

  factory IngressoModel.fromEntity(Ingresso entity) {
    return IngressoModel(
      empresaId: entity.empresaId,
      id: entity.id,
      status: entity.status,
      usuarioId: entity.usuarioId,
      dtLancamento: entity.dtLancamento,
      dtEmissao: entity.dtEmissao,
      dtEvento: entity.dtEvento,
      hrEvento: entity.hrEvento,
      dtEntrada: entity.dtEntrada,
      dtSaida: entity.dtSaida,
      duracaoMinutos: entity.duracaoMinutos,
      pessoaId: entity.pessoaId,
      tipoIngressoId: entity.tipoIngressoId,
      valor: entity.valor,
      observacao: entity.observacao,
      pedidoId: entity.pedidoId,
      codigoMesa: entity.codigoMesa,
      totalRecebido: entity.totalRecebido,
      totalProdutos: entity.totalProdutos,
      valorDiferenca: entity.valorDiferenca,
      caixaId: entity.caixaId,
      fechamentoId: entity.fechamentoId,
      troco: entity.troco,
      tipoTroco: entity.tipoTroco,
      gerarFinanceiro: entity.gerarFinanceiro,
    );
  }

  /// Converte a partir de um registro do banco de dados (SQLite ou retorno de API Firebird)
  factory IngressoModel.fromDbMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return IngressoModel(
      empresaId: parseInt(map['ING_EMPRESA']) ?? 1,
      id: parseInt(map['ING_ID']) ?? 0,
      status: map['ING_STATUS'] as String? ?? 'E',
      usuarioId: parseInt(map['ING_USUARIO']) ?? 1,
      dtLancamento: parseDate(map['ING_DT_LANCAMENTO']),
      dtEmissao: parseDate(map['ING_DT_EMISSAO']),
      dtEvento: parseDate(map['ING_DT_EVENTO']),
      hrEvento: map['ING_HR_EVENTO'] as String?,
      dtEntrada: parseDate(map['ING_DT_ENTRADA']),
      dtSaida: parseDate(map['ING_DT_SAIDA']),
      duracaoMinutos: parseInt(map['ING_DURACAO']),
      pessoaId: parseInt(map['ING_PESSOA']),
      tipoIngressoId: parseInt(map['ING_TIPO_INGRESSO']) ?? 1,
      valor: parseDouble(map['ING_VALOR']),
      observacao: map['ING_OBSERVACAO'] as String?,
      pedidoId: parseInt(map['ING_PEDIDO']),
      codigoMesa: map['ING_CODIGO'] as String? ?? '',
      totalRecebido: parseDouble(map['ING_TOTAL_RECEBIDO']),
      totalProdutos: parseDouble(map['ING_TOTAL_PRODUTOS']),
      valorDiferenca: parseDouble(map['ING_VALOR_DIFERENCA']),
      caixaId: parseInt(map['ING_CAIXA']) ?? 1,
      fechamentoId: parseInt(map['ING_FECHAMENTO']),
      troco: parseDouble(map['ING_TROCO']),
      tipoTroco: map['ING_TIPO_TROCO'] as String?,
      gerarFinanceiro: map['ING_GERAR_FINANCEIRO'] as String? ?? 'N',
    );
  }

  /// Mapeia para inserção ou atualização no banco de dados com os nomes exatos das colunas da TB_INGRESSO
  Map<String, dynamic> toDbMap() {
    String? formatDate(DateTime? date) => date?.toIso8601String();

    return {
      'ING_EMPRESA': empresaId,
      'ING_ID': id,
      'ING_STATUS': status,
      'ING_USUARIO': usuarioId,
      'ING_DT_LANCAMENTO': formatDate(dtLancamento),
      'ING_DT_EMISSAO': formatDate(dtEmissao),
      'ING_DT_EVENTO': formatDate(dtEvento),
      'ING_HR_EVENTO': hrEvento,
      'ING_DT_ENTRADA': formatDate(dtEntrada),
      'ING_DT_SAIDA': formatDate(dtSaida),
      'ING_DURACAO': duracaoMinutos,
      'ING_PESSOA': pessoaId,
      'ING_TIPO_INGRESSO': tipoIngressoId,
      'ING_VALOR': valor,
      'ING_OBSERVACAO': observacao,
      'ING_PEDIDO': pedidoId,
      'ING_CODIGO': codigoMesa,
      'ING_TOTAL_RECEBIDO': totalRecebido,
      'ING_TOTAL_PRODUTOS': totalProdutos,
      'ING_VALOR_DIFERENCA': valorDiferenca,
      'ING_CAIXA': caixaId,
      'ING_FECHAMENTO': fechamentoId,
      'ING_TROCO': troco,
      'ING_TIPO_TROCO': tipoTroco,
      'ING_GERAR_FINANCEIRO': gerarFinanceiro,
    };
  }

  Map<String, dynamic> toJson() => toDbMap();

  factory IngressoModel.fromJson(Map<String, dynamic> json) => IngressoModel.fromDbMap(json);
}
