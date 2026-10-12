import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/ingresso_local_datasource.dart';
import 'data/datasources/mesa_local_datasource.dart';
import 'data/datasources/retaguarda_sync_datasource.dart';
import 'data/repositories/config_repository_impl.dart';
import 'data/repositories/ingresso_repository_impl.dart';
import 'data/repositories/mesa_repository_impl.dart';
import 'domain/repositories/config_repository.dart';
import 'domain/repositories/ingresso_repository.dart';
import 'domain/repositories/mesa_repository.dart';
import 'presentation/cubits/config/config_cubit.dart';
import 'presentation/cubits/config/config_state.dart';
import 'presentation/cubits/mesa/mesa_cubit.dart';
import 'presentation/screens/mesa_grid_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instanciação da camada de dados
  final ConfigRepository configRepository = ConfigRepositoryImpl();
  final RetaguardaSyncDataSource syncDataSource = RetaguardaSyncDataSource();
  final IngressoRepository ingressoRepository = IngressoRepositoryImpl(
    localDataSource: IngressoLocalDataSource(),
    syncDataSource: syncDataSource,
  );
  final MesaRepository mesaRepository = MesaRepositoryImpl(
    localDataSource: MesaLocalDataSource(),
  );

  runApp(
    AppCheckInPermanencia(
      configRepository: configRepository,
      ingressoRepository: ingressoRepository,
      mesaRepository: mesaRepository,
    ),
  );
}

class AppCheckInPermanencia extends StatelessWidget {
  final ConfigRepository configRepository;
  final IngressoRepository ingressoRepository;
  final MesaRepository mesaRepository;

  const AppCheckInPermanencia({
    super.key,
    required this.configRepository,
    required this.ingressoRepository,
    required this.mesaRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConfigCubit>(
          create: (_) => ConfigCubit(
            configRepository: configRepository,
          )..carregarConfiguracoes(),
        ),
        BlocProvider<MesaCubit>(
          create: (context) {
            final mesaCubit = MesaCubit(
              mesaRepository: mesaRepository,
              ingressoRepository: ingressoRepository,
            );
            // Carrega as mesas assim que o cubit é criado
            configRepository.carregarConfiguracoes().then((config) {
              mesaCubit.carregarMesas(config: config);
            });
            return mesaCubit;
          },
        ),
      ],
      child: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final bool modoEscuro = state is ConfigLoaded ? state.config.modoEscuro : false;

          return MaterialApp(
            title: 'Gestão de Permanência de Mesas',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,
            home: MesaGridScreen(
              ingressoRepository: ingressoRepository,
            ),
          );
        },
      ),
    );
  }
}

