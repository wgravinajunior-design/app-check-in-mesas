import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_config.dart';
import '../../../domain/entities/comanda.dart';
import '../../../domain/entities/ingresso.dart';
import '../../../domain/entities/status_permanencia.dart';
import '../../../domain/repositories/comanda_repository.dart';
import '../../../domain/repositories/ingresso_repository.dart';
import 'comanda_state.dart';

class ComandaCubit extends Cubit<ComandaState> {
  final ComandaRepository comandaRepository;
  final IngressoRepository ingressoRepository;

  Timer? _timerTicker;
  AppConfig _config = const AppConfig();
  final Set<int> _comandasAlertadas = {};
  final Set<int> _comandasExcedidas = {};

  ComandaCubit({
    required this.comandaRepository,
    required this.ingressoRepository,
  }) : super(ComandaInitial()) {
    _iniciarTimerCronometro();
  }

  void _iniciarTimerCronometro() {
    _timerTicker?.cancel();
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _atualizarCronometros();
    });
  }

  void definirConfiguracao(AppConfig config) {
    _config = config;
    if (state is ComandaLoaded) {
      _atualizarCronometros();
    }
  }

  Future<void> carregarComandas({AppConfig? config}) async {
    if (config != null) {
      _config = config;
    }

    emit(ComandaLoading());
    try {
      final int totalQtd = _config.totalComandas > 0 ? _config.totalComandas : 50;
      await comandaRepository.inicializarComandasPadrao(
        empresaId: _config.empresaId,
        quantidade: totalQtd,
      );

      final List<Comanda> listaBase =
          await comandaRepository.listarComandas(empresaId: _config.empresaId);

      final List<Ingresso> ingressosAbertos =
          await ingressoRepository.listarIngressosAbertos(
        empresaId: _config.empresaId,
      );

      final agora = DateTime.now();
      final List<Comanda> comandasCompletas = listaBase.map((comanda) {
        final Ingresso? ingressoComanda = ingressosAbertos.cast<Ingresso?>().firstWhere(
              (ing) => ing?.codigoMesa == 'C-${comanda.codigo}' || ing?.codigoMesa == comanda.codigo,
              orElse: () => null,
            );

        if (ingressoComanda != null && ingressoComanda.dtEntrada != null) {
          final Duration decorrido = agora.difference(ingressoComanda.dtEntrada!);
          final StatusPermanencia status = _calcularStatus(decorrido);

          return comanda.copyWith(
            isOcupada: true,
            ingressoAtual: ingressoComanda,
            tempoDecorrido: decorrido,
            statusPermanencia: status,
          );
        } else {
          return comanda.copyWith(
            isOcupada: false,
            clearIngressoAtual: true,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.livre,
          );
        }
      }).toList();

      emit(ComandaLoaded(
        comandas: comandasCompletas,
        ultimoTick: agora,
      ));
    } catch (e) {
      emit(ComandaError('Falha ao carregar comandas: ${e.toString()}'));
    }
  }

  void _atualizarCronometros() {
    final estadoAtual = state;
    if (estadoAtual is! ComandaLoaded) return;

    final agora = DateTime.now();
    bool houveMudanca = false;

    final List<Comanda> atualizadas = estadoAtual.comandas.map((comanda) {
      if (!comanda.isOcupada || comanda.ingressoAtual?.dtEntrada == null) {
        _comandasAlertadas.remove(comanda.id);
        _comandasExcedidas.remove(comanda.id);
        return comanda;
      }

      final Duration novoDecorrido = agora.difference(comanda.ingressoAtual!.dtEntrada!);
      final StatusPermanencia novoStatus = _calcularStatus(novoDecorrido);

      if (novoStatus == StatusPermanencia.alertaTolerancia && !_comandasAlertadas.contains(comanda.id)) {
        _comandasAlertadas.add(comanda.id);
        if (_config.alertaSonoro) {
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.alert);
        }
      } else if (novoStatus == StatusPermanencia.limiteExcedido && !_comandasExcedidas.contains(comanda.id)) {
        _comandasExcedidas.add(comanda.id);
        if (_config.alertaSonoro) {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
        }
      }

      houveMudanca = true;
      return comanda.copyWith(
        tempoDecorrido: novoDecorrido,
        statusPermanencia: novoStatus,
      );
    }).toList();

    if (houveMudanca || atualizadas.any((c) => c.isOcupada)) {
      emit(ComandaLoaded(
        comandas: atualizadas,
        ultimoTick: agora,
      ));
    }
  }

  StatusPermanencia _calcularStatus(Duration duracao) {
    final int minutos = duracao.inMinutes;
    if (minutos <= _config.tempoAlertaMinutos) {
      return StatusPermanencia.normal;
    } else if (minutos <= _config.tempoLimiteMinutos) {
      return StatusPermanencia.alertaTolerancia;
    } else {
      return StatusPermanencia.limiteExcedido;
    }
  }

  Future<void> realizarCheckIn({
    required Comanda comanda,
    String? observacao,
  }) async {
    final estadoAtual = state;
    if (estadoAtual is! ComandaLoaded) return;

    try {
      final DateTime dataEntrada = DateTime.now();

      final Ingresso novoIngresso = await ingressoRepository.realizarCheckIn(
        empresaId: _config.empresaId,
        codigoMesa: 'C-${comanda.codigo}',
        dataHoraEntrada: dataEntrada,
        observacao: observacao ?? 'Permanência iniciada na Comanda ${comanda.codigo}',
      );

      await comandaRepository.atualizarStatusComanda(
        comandaId: comanda.id,
        isOcupada: true,
      );

      final List<Comanda> novas = estadoAtual.comandas.map((c) {
        if (c.id == comanda.id) {
          return c.copyWith(
            isOcupada: true,
            ingressoAtual: novoIngresso,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.normal,
          );
        }
        return c;
      }).toList();

      emit(ComandaLoaded(
        comandas: novas,
        ultimoTick: DateTime.now(),
      ));
    } catch (e) {
      emit(ComandaError('Erro no Check-in da Comanda ${comanda.codigo}: ${e.toString()}'));
      await carregarComandas();
    }
  }

  Future<void> realizarCheckOut({required Comanda comanda}) async {
    final estadoAtual = state;
    if (estadoAtual is! ComandaLoaded) return;

    final ingressoAtual = comanda.ingressoAtual;
    if (ingressoAtual == null) {
      emit(const ComandaError('Comanda não possui ingresso ativo para encerramento.'));
      return;
    }

    try {
      final DateTime dataSaida = DateTime.now();

      await ingressoRepository.realizarCheckOut(
        empresaId: _config.empresaId,
        ingressoId: ingressoAtual.id,
        dataHoraSaida: dataSaida,
      );

      await comandaRepository.atualizarStatusComanda(
        comandaId: comanda.id,
        isOcupada: false,
      );

      _comandasAlertadas.remove(comanda.id);
      _comandasExcedidas.remove(comanda.id);

      final List<Comanda> novas = estadoAtual.comandas.map((c) {
        if (c.id == comanda.id) {
          return c.copyWith(
            isOcupada: false,
            clearIngressoAtual: true,
            tempoDecorrido: Duration.zero,
            statusPermanencia: StatusPermanencia.livre,
          );
        }
        return c;
      }).toList();

      emit(ComandaLoaded(
        comandas: novas,
        ultimoTick: DateTime.now(),
      ));
    } catch (e) {
      emit(ComandaError('Erro no Check-out da Comanda ${comanda.codigo}: ${e.toString()}'));
      await carregarComandas();
    }
  }

  @override
  Future<void> close() {
    _timerTicker?.cancel();
    return super.close();
  }
}
