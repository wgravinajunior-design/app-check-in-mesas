import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_config.dart';

abstract class ConfigState extends Equatable {
  const ConfigState();

  @override
  List<Object?> get props => [];
}

class ConfigInitial extends ConfigState {}

class ConfigLoading extends ConfigState {}

class ConfigLoaded extends ConfigState {
  final AppConfig config;

  const ConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

class ConfigError extends ConfigState {
  final String mensagem;

  const ConfigError(this.mensagem);

  @override
  List<Object?> get props => [mensagem];
}
