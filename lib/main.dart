import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/comanda_local_datasource.dart';
import 'data/datasources/ingresso_local_datasource.dart';
import 'data/datasources/mesa_local_datasource.dart';
import 'data/datasources/produto_local_datasource.dart';
import 'data/datasources/retaguarda_sync_datasource.dart';
import 'data/repositories/comanda_repository_impl.dart';
import 'data/repositories/config_repository_impl.dart';
import 'data/repositories/ingresso_repository_impl.dart';
import 'data/repositories/mesa_repository_impl.dart';
import 'data/repositories/produto_repository_impl.dart';
import 'domain/repositories/comanda_repository.dart';
import 'domain/repositories/config_repository.dart';
import 'domain/repositories/ingresso_repository.dart';
import 'domain/repositories/mesa_repository.dart';
import 'domain/repositories/produto_repository.dart';
import 'presentation/cubits/comanda/comanda_cubit.dart';
import 'presentation/cubits/config/config_cubit.dart';
import 'presentation/cubits/config/config_state.dart';
import 'presentation/cubits/mesa/mesa_cubit.dart';
import 'presentation/cubits/produto/produto_cubit.dart';
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
  final ComandaRepository comandaRepository = ComandaRepositoryImpl(
    localDataSource: ComandaLocalDataSource(),
  );
  final ProdutoRepository produtoRepository = ProdutoRepositoryImpl(
    localDataSource: ProdutoLocalDataSource(),
  );

  runApp(
    CheckMesaApp(
      configRepository: configRepository,
      ingressoRepository: ingressoRepository,
      mesaRepository: mesaRepository,
      comandaRepository: comandaRepository,
      produtoRepository: produtoRepository,
    ),
  );
}

class CheckMesaApp extends StatelessWidget {
  final ConfigRepository configRepository;
  final IngressoRepository ingressoRepository;
  final MesaRepository mesaRepository;
  final ComandaRepository comandaRepository;
  final ProdutoRepository produtoRepository;

  const CheckMesaApp({
    super.key,
    required this.configRepository,
    required this.ingressoRepository,
    required this.mesaRepository,
    required this.comandaRepository,
    required this.produtoRepository,
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
            configRepository.carregarConfiguracoes().then((config) {
              mesaCubit.carregarMesas(config: config);
            });
            return mesaCubit;
          },
        ),
        BlocProvider<ComandaCubit>(
          create: (context) {
            final comandaCubit = ComandaCubit(
              comandaRepository: comandaRepository,
              ingressoRepository: ingressoRepository,
            );
            configRepository.carregarConfiguracoes().then((config) {
              comandaCubit.carregarComandas(config: config);
            });
            return comandaCubit;
          },
        ),
        BlocProvider<ProdutoCubit>(
          create: (_) => ProdutoCubit(
            produtoRepository: produtoRepository,
          ),
        ),
      ],
      child: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final bool modoEscuro = state is ConfigLoaded ? state.config.modoEscuro : false;

          return MaterialApp(
            title: 'CheckMesa',
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
