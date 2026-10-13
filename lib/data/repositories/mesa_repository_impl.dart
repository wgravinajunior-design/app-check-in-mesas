import '../../domain/entities/app_config.dart';
import '../../domain/entities/consumo_mesa_resumo.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/firebird_bridge_datasource.dart';
import '../datasources/mesa_local_datasource.dart';
import '../datasources/pedido_local_datasource.dart';
import '../models/mesa_model.dart';
import '../models/pedido_resumo_model.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaLocalDataSource localDataSource;
  final FirebirdBridgeDataSource firebirdBridgeDataSource;
  final PedidoLocalDataSource pedidoLocalDataSource;

  MesaRepositoryImpl({
    MesaLocalDataSource? localDataSource,
    FirebirdBridgeDataSource? firebirdBridgeDataSource,
    PedidoLocalDataSource? pedidoLocalDataSource,
  })  : localDataSource = localDataSource ?? MesaLocalDataSource(),
        firebirdBridgeDataSource =
            firebirdBridgeDataSource ?? FirebirdBridgeDataSource(),
        pedidoLocalDataSource =
            pedidoLocalDataSource ?? PedidoLocalDataSource();

  @override
  Future<List<Mesa>> listarMesas({required int empresaId}) {
    return localDataSource.listarMesas(empresaId: empresaId);
  }

  @override
  Future<void> inicializarMesasPadrao({
    required int empresaId,
    required int quantidade,
  }) {
    return localDataSource.inicializarMesasSeVazio(
      empresaId: empresaId,
      quantidade: quantidade,
    );
  }

  @override
  Future<String> testarConexaoFirebird({required AppConfig config}) {
    return firebirdBridgeDataSource.testarConexaoDirectFirebird(config);
  }

  @override
  Future<int> importarMesasDaBaseFirebird({
    required AppConfig config,
  }) async {
    final List<MesaModel> mesasFirebird =
        await firebirdBridgeDataSource.extrairMesasDaBaseFirebird(
      config: config,
    );

    await localDataSource.sincronizarMesasEmLote(
      empresaId: config.empresaId,
      novasMesas: mesasFirebird,
    );

    return mesasFirebird.length;
  }

  @override
  Future<void> atualizarStatusMesa({
    required int mesaId,
    required bool isOcupada,
  }) {
    return localDataSource.atualizarStatusMesa(
      mesaId: mesaId,
      isOcupada: isOcupada,
    );
  }

  @override
  Future<ConsumoMesaResumo> obterConsumoMesa({
    required int empresaId,
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
    required AppConfig config,
  }) async {
    // 1. Tenta buscar diretamente da retaguarda Firebird se configurada
    if (config.caminhoBanco.trim().isNotEmpty) {
      try {
        final List<PedidoResumoModel> pedidosFirebird =
            await firebirdBridgeDataSource.buscarPedidosMesaFirebird(
          config: config,
          mesaId: mesaId,
          codigoMesa: codigoMesa,
          dataCheckIn: dataCheckIn,
        );

        if (pedidosFirebird.isNotEmpty) {
          // Faz cache no SQLite local
          await pedidoLocalDataSource.salvarPedidosEmLote(pedidos: pedidosFirebird);
        }

        return ConsumoMesaResumo.processar(
          mesaId: mesaId,
          codigoMesa: codigoMesa,
          dataCheckIn: dataCheckIn,
          pedidosFiltrados: pedidosFirebird,
        );
      } catch (_) {}
    }

    // 2. Fallback para base SQLite local offline
    return pedidoLocalDataSource.obterConsumoMesa(
      empresaId: empresaId,
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      dataCheckIn: dataCheckIn,
    );
  }

  @override
  Future<Map<int, ConsumoMesaResumo>> obterConsumoMesasOcupadas({
    required int empresaId,
    required List<Mesa> mesasOcupadas,
    required AppConfig config,
  }) async {
    final Map<int, ConsumoMesaResumo> mapaResumo = {};
    if (mesasOcupadas.isEmpty) return mapaResumo;

    // 1. Tenta busca em lote de alta performance no Firebird
    if (config.caminhoBanco.trim().isNotEmpty) {
      try {
        final Map<int, List<PedidoResumoModel>> pedidosPorMesa =
            await firebirdBridgeDataSource.buscarPedidosMesasOcupadasFirebird(
          config: config,
          mesasOcupadas: mesasOcupadas,
        );

        final List<PedidoResumoModel> todosPedidos = [];
        for (final mesa in mesasOcupadas) {
          final DateTime? dtEntrada = mesa.horaEntrada;
          if (dtEntrada == null) continue;

          final int? codInt = int.tryParse(mesa.codigo);
          final List<PedidoResumoModel> pedidosMesa = [
            ...?pedidosPorMesa[mesa.id],
            if (codInt != null && codInt != mesa.id) ...?pedidosPorMesa[codInt],
          ];

          // Remove possíveis duplicados
          final idsVistos = <int>{};
          final pedidosUnicos = pedidosMesa.where((p) => idsVistos.add(p.id)).toList();

          todosPedidos.addAll(pedidosUnicos);

          // Filtra estritamente após o check-in desta mesa específica
          final filtradosCheckIn = pedidosUnicos
              .where((p) => p.dataHoraLancamento.isAfter(dtEntrada) ||
                  p.dataHoraLancamento.isAtSameMomentAs(dtEntrada))
              .toList();

          mapaResumo[mesa.id] = ConsumoMesaResumo.processar(
            mesaId: mesa.id,
            codigoMesa: mesa.codigo,
            dataCheckIn: dtEntrada,
            pedidosFiltrados: filtradosCheckIn,
          );
        }

        if (todosPedidos.isNotEmpty) {
          await pedidoLocalDataSource.salvarPedidosEmLote(pedidos: todosPedidos);
        }

        return mapaResumo;
      } catch (_) {}
    }

    // 2. Fallback para base SQLite local
    for (final mesa in mesasOcupadas) {
      final DateTime? dtEntrada = mesa.horaEntrada;
      if (dtEntrada == null) continue;

      final resumo = await pedidoLocalDataSource.obterConsumoMesa(
        empresaId: empresaId,
        mesaId: mesa.id,
        codigoMesa: mesa.codigo,
        dataCheckIn: dtEntrada,
      );
      mapaResumo[mesa.id] = resumo;
    }

    return mapaResumo;
  }

  @override
  Future<List<Mesa>> carregarMesasCompletasFirebird({required AppConfig config}) {
    return firebirdBridgeDataSource.consultarMesasComIngressosEConsumoFirebird(
      config: config,
    );
  }

  @override
  Future<void> executarCheckInFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraEntrada,
    String? observacao,
  }) {
    return firebirdBridgeDataSource.executarCheckInFirebird(
      config: config,
      mesa: mesa,
      dataHoraEntrada: dataHoraEntrada,
      observacao: observacao,
    );
  }

  @override
  Future<void> executarCheckOutFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraSaida,
  }) {
    return firebirdBridgeDataSource.executarCheckOutFirebird(
      config: config,
      mesa: mesa,
      dataHoraSaida: dataHoraSaida,
    );
  }
}
