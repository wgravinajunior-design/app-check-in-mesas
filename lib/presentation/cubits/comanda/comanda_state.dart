import 'package:equatable/equatable.dart';
import '../../../domain/entities/comanda.dart';

abstract class ComandaState extends Equatable {
  const ComandaState();

  @override
  List<Object?> get props => [];
}

class ComandaInitial extends ComandaState {}

class ComandaLoading extends ComandaState {}

class ComandaLoaded extends ComandaState {
  final List<Comanda> comandas;
  final DateTime ultimoTick;

  const ComandaLoaded({
    required this.comandas,
    required this.ultimoTick,
  });

  int get totalComandas => comandas.length;
  int get comandasOcupadas => comandas.where((c) => c.isOcupada).length;
  int get comandasLivres => totalComandas - comandasOcupadas;

  @override
  List<Object?> get props => [comandas, ultimoTick];
}

class ComandaError extends ComandaState {
  final String mensagem;

  const ComandaError(this.mensagem);

  @override
  List<Object?> get props => [mensagem];
}
