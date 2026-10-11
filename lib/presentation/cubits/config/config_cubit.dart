import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_config.dart';
import '../../../domain/repositories/config_repository.dart';
import 'config_state.dart';

class ConfigCubit extends Cubit<ConfigState> {
  final ConfigRepository configRepository;

  ConfigCubit({required this.configRepository}) : super(ConfigInitial());

  Future<void> carregarConfiguracoes() async {
    emit(ConfigLoading());
    try {
      final config = await configRepository.carregarConfiguracoes();
      emit(ConfigLoaded(config));
    } catch (e) {
      emit(ConfigError('Erro ao carregar configurações: ${e.toString()}'));
    }
  }

  Future<void> salvarConfiguracoes(AppConfig novaConfig) async {
    try {
      await configRepository.salvarConfiguracoes(novaConfig);
      emit(ConfigLoaded(novaConfig));
    } catch (e) {
      emit(ConfigError('Erro ao salvar configurações: ${e.toString()}'));
    }
  }
}
