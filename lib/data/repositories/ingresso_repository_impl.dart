import '../../core/constants/app_constants.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/ingresso.dart';
import '../../domain/repositories/ingresso_repository.dart';
import '../datasources/ingresso_local_datasource.dart';
import '../datasources/retaguarda_sync_datasource.dart';
import '../models/ingresso_model.dart';

class IngressoRepositoryImpl implements IngressoRepository {
  final IngressoLocalDataSource localDataSource;
  final RetaguardaSyncDataSource? syncDataSource;

  IngressoRepositoryImpl({
    IngressoLocalDataSource? localDataSource,
    this.syncDataSource,
  }) : localDataSource = localDataSource ?? IngressoLocalDataSource();

  @override
  Future<int> obterProximoId(int empresaId) {
    return localDataSource.obterProximoId(empresaId);
  }

  @override
  Future<Ingresso> realizarCheckIn({
    required int empresaId,
    required String codigoMesa,
    required DateTime dataHoraEntrada,
    String? observacao,
  }) async {
    final int proximoId = await localDataSource.obterProximoId(empresaId);
    final String horaAtual = TimeFormatter.formatTime(dataHoraEntrada);

    final novoIngresso = IngressoModel(
      empresaId: empresaId,
      id: proximoId,
      status: AppConstants.statusIngressoAberto,
      usuarioId: 1,
      dtLancamento: dataHoraEntrada,
      dtEmissao: dataHoraEntrada,
      dtEvento: dataHoraEntrada,
      hrEvento: horaAtual,
      dtEntrada: dataHoraEntrada,
      dtSaida: null,
      duracaoMinutos: 0,
      pessoaId: null,
      tipoIngressoId: 1,
      valor: 0.0,
      observacao: observacao ?? 'Permanência iniciada na Mesa $codigoMesa',
      pedidoId: null,
      codigoMesa: codigoMesa,
      totalRecebido: 0.0,
      totalProdutos: 0.0,
      valorDiferenca: 0.0,
      caixaId: 1,
      fechamentoId: null,
      troco: 0.0,
      tipoTroco: null,
      gerarFinanceiro: 'N',
    );

    await localDataSource.inserir(novoIngresso);
    return novoIngresso;
  }

  @override
  Future<Ingresso> realizarCheckOut({
    required int empresaId,
    required int ingressoId,
    required DateTime dataHoraSaida,
  }) async {
    final List<IngressoModel> historico = await localDataSource.listarHistorico(
      empresaId: empresaId,
    );

    final ingressoExistente = historico.firstWhere(
      (ing) => ing.id == ingressoId,
      orElse: () => throw Exception('Ingresso #$ingressoId não localizado.'),
    );

    final DateTime entrada = ingressoExistente.dtEntrada ?? dataHoraSaida;
    final int duracaoMinutos = dataHoraSaida.difference(entrada).inMinutes;

    final ingressoAtualizado = ingressoExistente.copyWith(
      status: AppConstants.statusIngressoFinalizado,
      dtSaida: dataHoraSaida,
      duracaoMinutos: duracaoMinutos,
      observacao: '${ingressoExistente.observacao ?? ''} | Saída: ${TimeFormatter.formatDateTime(dataHoraSaida)} (Duração: ${duracaoMinutos}m)',
    );

    await localDataSource.atualizar(IngressoModel.fromEntity(ingressoAtualizado));
    return ingressoAtualizado;
  }

  @override
  Future<Ingresso?> obterIngressoAbertoPorMesa({
    required int empresaId,
    required String codigoMesa,
  }) {
    return localDataSource.obterIngressoAbertoPorMesa(
      empresaId: empresaId,
      codigoMesa: codigoMesa,
    );
  }

  @override
  Future<List<Ingresso>> listarHistorico({
    required int empresaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return localDataSource.listarHistorico(
      empresaId: empresaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
  }

  @override
  Future<List<Ingresso>> listarIngressosAbertos({
    required int empresaId,
  }) {
    return localDataSource.listarIngressosAbertos(
      empresaId: empresaId,
    );
  }

  @override
  Future<Ingresso> transferirMesa({
    required int empresaId,
    required int ingressoId,
    required String mesaOrigemCodigo,
    required String mesaDestinoCodigo,
    String? motivo,
  }) async {
    final List<IngressoModel> historico = await localDataSource.listarHistorico(
      empresaId: empresaId,
    );

    final ingressoExistente = historico.firstWhere(
      (ing) => ing.id == ingressoId,
      orElse: () => throw Exception('Ingresso #$ingressoId não localizado para transferência.'),
    );

    final String notaTransferencia =
        ' | Transf. da Mesa $mesaOrigemCodigo para Mesa $mesaDestinoCodigo às ${TimeFormatter.formatDateTime(DateTime.now())}${motivo != null && motivo.trim().isNotEmpty ? ' ($motivo)' : ''}';

    final ingressoAtualizado = ingressoExistente.copyWith(
      codigoMesa: mesaDestinoCodigo,
      observacao: '${ingressoExistente.observacao ?? ''}$notaTransferencia',
    );

    await localDataSource.atualizar(IngressoModel.fromEntity(ingressoAtualizado));
    return ingressoAtualizado;
  }
}

