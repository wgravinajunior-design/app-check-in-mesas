import 'package:equatable/equatable.dart';
import '../../../domain/entities/mesa.dart';
import '../../../domain/entities/status_permanencia.dart';

abstract class MesaState extends Equatable {
  const MesaState();

  @override
  List<Object?> get props => [];
}

class MesaInitial extends MesaState {}

class MesaLoading extends MesaState {}

class MesaLoaded extends MesaState {
  final List<Mesa> mesas;
  final DateTime ultimoTick;

  const MesaLoaded({
    required this.mesas,
    required this.ultimoTick,
  });

  int get totalMesas => mesas.length;

  int get totalLivres => mesas.where((m) => !m.isOcupada).length;

  int get totalOcupadas => mesas.where((m) => m.isOcupada).length;

  int get totalEmAtendimento => mesas
      .where((m) => m.isOcupada && m.statusPermanencia == StatusPermanencia.normal)
      .length;

  int get totalEmAlerta => mesas
      .where((m) =>
          m.isOcupada && m.statusPermanencia == StatusPermanencia.alertaTolerancia)
      .length;

  int get totalExcedidas => mesas
      .where((m) =>
          m.isOcupada && m.statusPermanencia == StatusPermanencia.limiteExcedido)
      .length;

  MesaLoaded copyWith({
    List<Mesa>? mesas,
    DateTime? ultimoTick,
  }) {
    return MesaLoaded(
      mesas: mesas ?? this.mesas,
      ultimoTick: ultimoTick ?? this.ultimoTick,
    );
  }

  @override
  List<Object?> get props => [mesas, ultimoTick];
}

class MesaError extends MesaState {
  final String mensagem;

  const MesaError(this.mensagem);

  @override
  List<Object?> get props => [mensagem];
}
