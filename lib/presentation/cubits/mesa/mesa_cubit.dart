import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_config.dart';
import '../../../domain/entities/ingresso.dart';
import '../../../domain/entities/mesa.dart';
import '../../../domain/entities/status_permanencia.dart';
import '../../../domain/repositories/ingresso_repository.dart';
import '../../../domain/repositories/mesa_repository.dart';
import 'mesa_state.dart';

class MesaCubit extends Cubit<MesaState> {
  final MesaRepository mesaRepository;
  final IngressoRepository ingressoRepository;

  Timer? _timerTicker;
  AppConfig _config = const AppConfig();

  MesaCubit({
    required this.mesaRepository,
    required this.ingressoRepository,
  }) : super(MesaInitial()) {
    _iniciarTimerCronometro();
  }

  void _iniciarTimerCronometro() {
    _timerTicker?.cancel();
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _atualizarCronometros();
    });
  }

  void definirConfiguracao(AppConfig config) {
    _config = config;
    if (state is MesaLoaded) {
      _atualizarCronometros();
    }
  }

  Future<void> carregarMesas({AppConfig? config}) async {
    if (config != null) {
      _config = config;
    }

    emit(MesaLoading());
    try {
      // Garante a existência do lote de mesas se for a primeira execução
      await mesaRepository.inicializarMesasPadrao(
        empresaId: _config.empresaId,
        quantidade: _config.totalMesas,
      );

      final List<Mesa> listaMesasBase =
          await mesaRepository.listarMesas(empresaId: _config.empresaId);

      // Carrega os ingressos atualmente abertos na TB_INGRESSO
      final List<Ingresso> ingressosAbertos =
          await ingressoRepository.listarIngressosAbertos(
        empresaId: _config.empresaId,
      );

      final agora = DateTime.now();
      final List<Mesa> mesasCompletas = listaMesasBase.map((mesa) {
        // Localiza ingresso em aberto vinculado a este código de mesa
        final Ingresso? ingressoMesa = ingressosAbertos.cast<Ingresso?>().firstWhere(
              (ing) => ing?.codigoMesa == mesa.codigo,
              orElse: () => null,
            );

        if (ingressoMesa != null && ingressoMesa.dtEntrada != null) {
          final Duration decorrido = agora.difference(ingressoMesa.dtEntrada!);
          final StatusPermanencia status = _calcularStatusPermanencia(decorrido);

          return mesa.copyWith(
            isOcupada: true,
            ingressoAtual: ingressoMesa,
            tempoDecorrido: decorrido,
            statusPermanencia: status,
          );
        } else {
          return mesa.copyWith(
            isOcupada: false,
            clearIngressoAtual: true,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.livre,
          );
        }
      }).toList();

      emit(MesaLoaded(
        mesas: mesasCompletas,
        ultimoTick: agora,
      ));
    } catch (e) {
      emit(MesaError('Falha ao carregar mesas e status de permanência: ${e.toString()}'));
    }
  }

  /// Testa a conexão direta com o Firebird 5.0
  Future<String> testarConexaoFirebird(AppConfig config) async {
    return mesaRepository.testarConexaoFirebird(config: config);
  }

  /// Importa e sincroniza as mesas reais cadastradas diretamente na base de dados Firebird
  Future<int> importarMesasDoFirebird(AppConfig config) async {
    _config = config;
    emit(MesaLoading());
    try {
      final int totalImportadas = await mesaRepository.importarMesasDaBaseFirebird(
        config: config,
      );

      _config = _config.copyWith(totalMesas: totalImportadas);
      await carregarMesas(config: _config);
      return totalImportadas;
    } catch (e) {
      emit(MesaError('Erro ao importar mesas da base Firebird: ${e.toString()}'));
      await carregarMesas(config: _config);
      rethrow;
    }
  }

  void _atualizarCronometros() {
    final estadoAtual = state;
    if (estadoAtual is! MesaLoaded) return;

    final agora = DateTime.now();
    bool houveMudanca = false;

    final List<Mesa> mesasAtualizadas = estadoAtual.mesas.map((mesa) {
      if (!mesa.isOcupada || mesa.ingressoAtual?.dtEntrada == null) {
        return mesa;
      }

      final Duration novoDecorrido = agora.difference(mesa.ingressoAtual!.dtEntrada!);
      final StatusPermanencia novoStatus = _calcularStatusPermanencia(novoDecorrido);

      houveMudanca = true;
      return mesa.copyWith(
        tempoDecorrido: novoDecorrido,
        statusPermanencia: novoStatus,
      );
    }).toList();

    if (houveMudanca || mesasAtualizadas.any((m) => m.isOcupada)) {
      emit(MesaLoaded(
        mesas: mesasAtualizadas,
        ultimoTick: agora,
      ));
    }
  }

  StatusPermanencia _calcularStatusPermanencia(Duration duracao) {
    final int minutos = duracao.inMinutes;

    if (minutos <= _config.tempoAlertaMinutos) {
      return StatusPermanencia.normal; // Até 1h30m -> Azul / Neutro
    } else if (minutos <= _config.tempoLimiteMinutos) {
      return StatusPermanencia.alertaTolerancia; // 1h30m a 2h00m -> Amarelo / Laranja
    } else {
      return StatusPermanencia.limiteExcedido; // Mais de 2h00m -> Vermelho em destaque
    }
  }

  /// Realiza o Check-in na mesa selecionada
  Future<void> realizarCheckIn({
    required Mesa mesa,
    String? observacao,
  }) async {
    final estadoAtual = state;
    if (estadoAtual is! MesaLoaded) return;

    try {
      final DateTime dataEntrada = DateTime.now();

      // Grava diretamente na estrutura de TB_INGRESSO
      final Ingresso novoIngresso = await ingressoRepository.realizarCheckIn(
        empresaId: _config.empresaId,
        codigoMesa: mesa.codigo,
        dataHoraEntrada: dataEntrada,
        observacao: observacao,
      );

      // Atualiza o estado da mesa na retaguarda
      await mesaRepository.atualizarStatusMesa(
        mesaId: mesa.id,
        isOcupada: true,
      );

      final List<Mesa> novasMesas = estadoAtual.mesas.map((m) {
        if (m.id == mesa.id) {
          return m.copyWith(
            isOcupada: true,
            ingressoAtual: novoIngresso,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.normal,
          );
        }
        return m;
      }).toList();

      emit(MesaLoaded(
        mesas: novasMesas,
        ultimoTick: DateTime.now(),
      ));
    } catch (e) {
      emit(MesaError('Erro ao realizar Check-in na Mesa ${mesa.codigo}: ${e.toString()}'));
      // Recarrega para manter a consistência com a base de dados
      await carregarMesas();
    }
  }

  /// Realiza o Check-out e libera a mesa
  Future<void> realizarCheckOut({required Mesa mesa}) async {
    final estadoAtual = state;
    if (estadoAtual is! MesaLoaded) return;

    final ingressoAtual = mesa.ingressoAtual;
    if (ingressoAtual == null) {
      emit(const MesaError('Não há registro de ingresso ativo para esta mesa.'));
      return;
    }

    try {
      final DateTime dataSaida = DateTime.now();

      // Atualiza o ingresso com a saída e duração
      await ingressoRepository.realizarCheckOut(
        empresaId: _config.empresaId,
        ingressoId: ingressoAtual.id,
        dataHoraSaida: dataSaida,
      );

      // Atualiza o status da mesa para livre
      await mesaRepository.atualizarStatusMesa(
        mesaId: mesa.id,
        isOcupada: false,
      );

      final List<Mesa> novasMesas = estadoAtual.mesas.map((m) {
        if (m.id == mesa.id) {
          return m.copyWith(
            isOcupada: false,
            clearIngressoAtual: true,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.livre,
          );
        }
        return m;
      }).toList();

      emit(MesaLoaded(
        mesas: novasMesas,
        ultimoTick: DateTime.now(),
      ));
    } catch (e) {
      emit(MesaError('Erro ao realizar Check-out na Mesa ${mesa.codigo}: ${e.toString()}'));
      await carregarMesas();
    }
  }

  @override
  Future<void> close() {
    _timerTicker?.cancel();
    return super.close();
  }
}
