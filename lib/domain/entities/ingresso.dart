import 'package:equatable/equatable.dart';

/// Entidade de Domínio representando o registro na tabela TB_INGRESSO
class Ingresso extends Equatable {
  final int empresaId;
  final int id;
  final String status; // 'A' = Aberto (em atendimento), 'F' = Finalizado (checkout)
  final int? usuarioId;
  final DateTime? dtLancamento;
  final DateTime? dtEmissao;
  final DateTime? dtEvento;
  final String? hrEvento;
  final DateTime? dtEntrada; // Check-in
  final DateTime? dtSaida; // Check-out
  final int? duracaoMinutos; // Total de permanência em minutos
  final int? pessoaId;
  final int? tipoIngressoId;
  final double valor;
  final String? observacao;
  final int? pedidoId;
  final String codigoMesa; // Número/Identificador da mesa associada (ex: '001', '005')
  final double totalRecebido;
  final double totalProdutos;
  final double valorDiferenca;
  final int? caixaId;
  final int? fechamentoId;
  final double troco;
  final String? tipoTroco;
  final String gerarFinanceiro; // 'S' ou 'N'

  const Ingresso({
    required this.empresaId,
    required this.id,
    required this.status,
    this.usuarioId = 1,
    this.dtLancamento,
    this.dtEmissao,
    this.dtEvento,
    this.hrEvento,
    this.dtEntrada,
    this.dtSaida,
    this.duracaoMinutos,
    this.pessoaId,
    this.tipoIngressoId = 1,
    this.valor = 0.0,
    this.observacao,
    this.pedidoId,
    required this.codigoMesa,
    this.totalRecebido = 0.0,
    this.totalProdutos = 0.0,
    this.valorDiferenca = 0.0,
    this.caixaId = 1,
    this.fechamentoId,
    this.troco = 0.0,
    this.tipoTroco,
    this.gerarFinanceiro = 'N',
  });

  bool get isAberto => status == 'A';
  bool get isFinalizado => status == 'F';

  Ingresso copyWith({
    int? empresaId,
    int? id,
    String? status,
    int? usuarioId,
    DateTime? dtLancamento,
    DateTime? dtEmissao,
    DateTime? dtEvento,
    String? hrEvento,
    DateTime? dtEntrada,
    DateTime? dtSaida,
    int? duracaoMinutos,
    int? pessoaId,
    int? tipoIngressoId,
    double? valor,
    String? observacao,
    int? pedidoId,
    String? codigoMesa,
    double? totalRecebido,
    double? totalProdutos,
    double? valorDiferenca,
    int? caixaId,
    int? fechamentoId,
    double? troco,
    String? tipoTroco,
    String? gerarFinanceiro,
  }) {
    return Ingresso(
      empresaId: empresaId ?? this.empresaId,
      id: id ?? this.id,
      status: status ?? this.status,
      usuarioId: usuarioId ?? this.usuarioId,
      dtLancamento: dtLancamento ?? this.dtLancamento,
      dtEmissao: dtEmissao ?? this.dtEmissao,
      dtEvento: dtEvento ?? this.dtEvento,
      hrEvento: hrEvento ?? this.hrEvento,
      dtEntrada: dtEntrada ?? this.dtEntrada,
      dtSaida: dtSaida ?? this.dtSaida,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      pessoaId: pessoaId ?? this.pessoaId,
      tipoIngressoId: tipoIngressoId ?? this.tipoIngressoId,
      valor: valor ?? this.valor,
      observacao: observacao ?? this.observacao,
      pedidoId: pedidoId ?? this.pedidoId,
      codigoMesa: codigoMesa ?? this.codigoMesa,
      totalRecebido: totalRecebido ?? this.totalRecebido,
      totalProdutos: totalProdutos ?? this.totalProdutos,
      valorDiferenca: valorDiferenca ?? this.valorDiferenca,
      caixaId: caixaId ?? this.caixaId,
      fechamentoId: fechamentoId ?? this.fechamentoId,
      troco: troco ?? this.troco,
      tipoTroco: tipoTroco ?? this.tipoTroco,
      gerarFinanceiro: gerarFinanceiro ?? this.gerarFinanceiro,
    );
  }

  @override
  List<Object?> get props => [
        empresaId,
        id,
        status,
        usuarioId,
        dtLancamento,
        dtEmissao,
        dtEvento,
        hrEvento,
        dtEntrada,
        dtSaida,
        duracaoMinutos,
        pessoaId,
        tipoIngressoId,
        valor,
        observacao,
        pedidoId,
        codigoMesa,
        totalRecebido,
        totalProdutos,
        valorDiferenca,
        caixaId,
        fechamentoId,
        troco,
        tipoTroco,
        gerarFinanceiro,
      ];
}
