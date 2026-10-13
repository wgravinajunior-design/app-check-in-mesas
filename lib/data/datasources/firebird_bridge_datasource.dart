import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fbdb/fbdb.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/mesas_padrao_mansao.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/mesa.dart';
import '../models/mesa_model.dart';
import '../models/pedido_resumo_model.dart';

/// DataSource para conexão direta nativa com a base de dados Firebird 5.0
/// Utiliza o driver nativo oficial do Firebird (fbdb + libfbclient.so no Android / fbclient.dll no Windows)
class FirebirdBridgeDataSource {
  /// Procura o executável do utilitário isql do Firebird instalado na máquina Windows (fallback)
  String? _obterCaminhoIsql() {
    if (!kIsWeb && Platform.isWindows) {
      final caminhosPossiveis = [
        r'C:\Program Files\Firebird\Firebird_5_0\isql.exe',
        r'C:\Program Files\Firebird\Firebird_4_0\bin\isql.exe',
        r'C:\Program Files\Firebird\Firebird_3_0\bin\isql.exe',
        r'C:\Program Files (x86)\Firebird\Firebird_2_5\bin\isql.exe',
        'isql.exe',
      ];

      for (final caminho in caminhosPossiveis) {
        if (File(caminho).existsSync()) {
          return caminho;
        }
      }
    }
    return null;
  }

  /// Constrói o identificador de conexão compatível com Firebird 5.0
  String _montarStringConexao(AppConfig config) {
    return config.stringConexaoFirebird;
  }

  /// Testa a conexão direta nativa com o Firebird 5.0 (sem servidores intermediários)
  Future<String> testarConexaoDirectFirebird(AppConfig config) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();

    // Se estiver no mobile e usuário digitou localhost
    if (!kIsWeb && Platform.isAndroid && (hostLimpo == 'localhost' || hostLimpo == '127.0.0.1')) {
      throw Exception(
        'No celular, "localhost" aponta para o próprio smartphone.\n'
        'Toque em "Aplicar IP" para conectar ao IP do seu computador na rede Wi-Fi (${AppConstants.defaultHostFirebird}).',
      );
    }

    // 1. Conexão Nativa Direta via FbDb (libfbclient)
    try {
      final db = await FbDb.attach(
        host: hostLimpo,
        port: porta,
        database: databasePath,
        user: user,
        password: password,
      );

      final q = db.query();
      await q.openCursor(sql: 'SELECT COUNT(*) AS TOTAL FROM TB_MESA');
      int totalMesas = 0;
      await for (final row in q.rows()) {
        totalMesas = int.tryParse(row['TOTAL']?.toString() ?? '0') ?? 0;
      }
      await q.close();
      await db.detach();

      return 'Conexão direta estabelecida com o Firebird 5.0!\n'
          'Host: $hostLimpo:$porta\n'
          'Base: $databasePath\n'
          'Status: OK ($totalMesas mesas localizadas em TB_MESA).';
    } catch (e) {
      // Se falhar via driver nativo, testa se a porta TCP está acessível
      try {
        final socket = await Socket.connect(hostLimpo, porta, timeout: const Duration(seconds: 4));
        socket.destroy();
      } catch (_) {
        throw Exception(
          'Não foi possível alcançar a porta $porta no IP $hostLimpo.\n'
          'Verifique se o computador e o celular estão no mesmo Wi-Fi e se a porta $porta está liberada no Firewall.',
        );
      }

      // 2. Se estiver em Windows Desktop, tenta via ISQL como contingência
      if (!kIsWeb && Platform.isWindows) {
        final isqlPath = _obterCaminhoIsql();
        if (isqlPath != null) {
          final stringConexao = _montarStringConexao(config);
          try {
            final process = await Process.start(
              isqlPath,
              [
                '-u', user,
                '-p', password,
                '-q',
                stringConexao,
              ],
              runInShell: false,
            );

            process.stdin.writeln('SHOW DATABASE;');
            process.stdin.writeln('QUIT;');
            await process.stdin.flush();
            await process.stdin.close();

            final output = await process.stdout.transform(systemEncoding.decoder).join();
            final exitCode = await process.exitCode;

            if (exitCode == 0 && (output.contains('ODS') || output.contains('Database:'))) {
              return 'Conexão direta estabelecida com o Firebird 5.0 via ISQL local!';
            }
          } catch (_) {}
        }
      }

      throw Exception('Erro ao autenticar no Firebird 5.0 ($hostLimpo:$porta):\n$e');
    }
  }

  /// Conecta diretamente e extrai as mesas de TB_MESA via Firebird nativo
  Future<List<MesaModel>> extrairMesasDaBaseFirebird({
    required AppConfig config,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();

    // 1. Tenta extrair diretamente via driver nativo Firebird 5.0
    try {
      final db = await FbDb.attach(
        host: hostLimpo,
        port: porta,
        database: databasePath,
        user: user,
        password: password,
      );

      final q = db.query();
      await q.openCursor(
        sql: 'SELECT MSA_ID, MSA_EMPRESA, MSA_CODIGO, MSA_DESCRICAO, MSA_NR_PESSOAS, MSA_STATUS '
            'FROM TB_MESA '
            'ORDER BY MSA_ID',
      );

      final List<MesaModel> mesas = [];
      await for (final row in q.rows()) {
        final id = int.tryParse(row['MSA_ID']?.toString() ?? '0') ?? 0;
        final emp = int.tryParse(row['MSA_EMPRESA']?.toString() ?? '1') ?? config.empresaId;
        final cod = (row['MSA_CODIGO']?.toString() ?? '').trim();
        final desc = (row['MSA_DESCRICAO']?.toString() ?? '').trim();
        final nrPessoas = int.tryParse(row['MSA_NR_PESSOAS']?.toString() ?? '4') ?? 4;
        final status = (row['MSA_STATUS']?.toString() ?? 'A').trim();

        if (id > 0 && cod.isNotEmpty) {
          mesas.add(
            MesaModel(
              id: id,
              empresaId: emp,
              codigo: cod,
              descricao: desc.isNotEmpty ? desc : 'Mesa $cod',
              numeroPessoas: nrPessoas,
              isOcupada: status == 'O',
            ),
          );
        }
      }

      await q.close();
      await db.detach();

      if (mesas.isNotEmpty) {
        return mesas;
      }
    } catch (_) {
      // Se o driver nativo não conseguir carregar no momento, segue para contingências
    }

    // 2. Se for Windows Desktop, tenta via ISQL direto
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        const comandoSql = '''
SET HEADING OFF;
SELECT
    MSA_ID || ';' ||
    COALESCE(MSA_EMPRESA, 1) || ';' ||
    TRIM(MSA_CODIGO) || ';' ||
    COALESCE(TRIM(MSA_DESCRICAO), '') || ';' ||
    COALESCE(MSA_NR_PESSOAS, 4) || ';' ||
    COALESCE(MSA_STATUS, 'A')
FROM TB_MESA
ORDER BY MSA_ID;
''';
        try {
          final process = await Process.start(
            isqlPath,
            [
              '-u', user,
              '-p', password,
              '-q',
              stringConexao,
            ],
            runInShell: false,
          );

          process.stdin.writeln(comandoSql);
          process.stdin.writeln('QUIT;');
          await process.stdin.flush();
          await process.stdin.close();

          final output = await process.stdout.transform(systemEncoding.decoder).join();
          final exitCode = await process.exitCode;

          if (exitCode == 0) {
            final List<MesaModel> mesas = [];
            final linhas = const LineSplitter().convert(output);

            for (final linha in linhas) {
              final linhaTrim = linha.trim();
              if (linhaTrim.isEmpty || linhaTrim.startsWith('Database:') || linhaTrim.startsWith('SQL>')) {
                continue;
              }

              final partes = linhaTrim.split(';');
              if (partes.length >= 6) {
                final int id = int.tryParse(partes[0].trim()) ?? 0;
                final int emp = int.tryParse(partes[1].trim()) ?? config.empresaId;
                final String codigo = partes[2].trim();
                final String desc = partes[3].trim();
                final int nrPessoas = int.tryParse(partes[4].trim()) ?? 4;
                final String status = partes[5].trim();

                if (id > 0 && codigo.isNotEmpty) {
                  mesas.add(
                    MesaModel(
                      id: id,
                      empresaId: emp,
                      codigo: codigo,
                      descricao: desc.isNotEmpty ? desc : 'Mesa $codigo',
                      numeroPessoas: nrPessoas,
                      isOcupada: status == 'O',
                    ),
                  );
                }
              }
            }

            if (mesas.isNotEmpty) {
              return mesas;
            }
          }
        } catch (_) {}
      }
    }

    // 3. Fallback Seguro: Se o banco estiver offline no momento, carrega as 75 mesas reais da Mansão da Torre
    return MesasPadraoMansao.obterMesasPadrao(config.empresaId);
  }

  /// Executa comandos SQL diretamente na base Firebird 5.0 (INSERT / UPDATE em TB_INGRESSO)
  Future<void> executarSqlDiretoNoFirebird({
    required AppConfig config,
    required String sql,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;

    final db = await FbDb.attach(
      host: hostLimpo,
      port: porta,
      database: config.caminhoBanco.trim(),
      user: config.usuarioBanco.trim(),
      password: config.senhaBanco.trim(),
    );

    try {
      await db.execute(sql: sql);
    } finally {
      await db.detach();
    }
  }

  /// Consulta pedidos da mesa na retaguarda Firebird 5.0 no modelo pré-pago:
  /// - Filtro temporal: apenas pedidos feitos após dataHoraCheckIn
  /// - Último pedido: ordenados decrescente pela data/hora
  /// - Valores: ID, data/hora, valor total e status
  Future<List<PedidoResumoModel>> buscarPedidosMesaFirebird({
    required AppConfig config,
    required int mesaId,
    required String codigoMesa,
    required DateTime dataCheckIn,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();
    final int codigoInt = int.tryParse(codigoMesa) ?? mesaId;
    final String dtSql = TimeFormatter.formatDateTimeSql(dataCheckIn);

    final sql = '''
SELECT
    PEV_ID,
    PEV_EMPRESA,
    PEV_MESA,
    PEV_DT_LANCAMENTO,
    COALESCE(PEV_VALOR_TOTAL, 0.0) AS PEV_VALOR_TOTAL,
    PEV_STATUS
FROM TB_PEDIDO_VENDA
WHERE PEV_EMPRESA = ${config.empresaId}
  AND (PEV_MESA = $mesaId OR PEV_MESA = $codigoInt)
  AND PEV_DT_LANCAMENTO >= '$dtSql'
  AND COALESCE(PEV_STATUS, '') != 'C'
ORDER BY PEV_DT_LANCAMENTO DESC;
''';

    // 1. Tenta via FbDb nativo
    try {
      final db = await FbDb.attach(
        host: hostLimpo,
        port: porta,
        database: databasePath,
        user: user,
        password: password,
      );

      final q = db.query();
      await q.openCursor(sql: sql);

      final List<PedidoResumoModel> pedidos = [];
      await for (final row in q.rows()) {
        pedidos.add(PedidoResumoModel.fromFirebirdRow(row));
      }

      await q.close();
      await db.detach();
      return pedidos;
    } catch (_) {}

    // 2. Fallback via ISQL no Windows
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        final sqlIsql = '''
SET HEADING OFF;
SELECT
    PEV_ID || ';' ||
    COALESCE(PEV_EMPRESA, 1) || ';' ||
    PEV_MESA || ';' ||
    PEV_DT_LANCAMENTO || ';' ||
    COALESCE(PEV_VALOR_TOTAL, 0.0) || ';' ||
    COALESCE(PEV_STATUS, 'F')
FROM TB_PEDIDO_VENDA
WHERE PEV_EMPRESA = ${config.empresaId}
  AND (PEV_MESA = $mesaId OR PEV_MESA = $codigoInt)
  AND PEV_DT_LANCAMENTO >= '$dtSql'
  AND COALESCE(PEV_STATUS, '') != 'C'
ORDER BY PEV_DT_LANCAMENTO DESC;
''';
        try {
          final process = await Process.start(
            isqlPath,
            ['-u', user, '-p', password, '-q', stringConexao],
            runInShell: false,
          );

          process.stdin.writeln(sqlIsql);
          process.stdin.writeln('QUIT;');
          await process.stdin.flush();
          await process.stdin.close();

          final output = await process.stdout.transform(systemEncoding.decoder).join();
          final exitCode = await process.exitCode;

          if (exitCode == 0) {
            final List<PedidoResumoModel> pedidos = [];
            final linhas = const LineSplitter().convert(output);
            for (final linha in linhas) {
              final trim = linha.trim();
              if (trim.isEmpty || trim.startsWith('Database:') || trim.startsWith('SQL>')) continue;
              final partes = trim.split(';');
              if (partes.length >= 6) {
                final id = int.tryParse(partes[0].trim()) ?? 0;
                final emp = int.tryParse(partes[1].trim()) ?? config.empresaId;
                final mesa = int.tryParse(partes[2].trim()) ?? mesaId;
                final dt = DateTime.tryParse(partes[3].trim()) ?? DateTime.now();
                final valor = double.tryParse(partes[4].trim()) ?? 0.0;
                final st = partes[5].trim();
                if (id > 0) {
                  pedidos.add(PedidoResumoModel(
                    id: id,
                    empresaId: emp,
                    mesaId: mesa,
                    dataHoraLancamento: dt,
                    valorTotal: valor,
                    status: st,
                  ));
                }
              }
            }
            return pedidos;
          }
        } catch (_) {}
      }
    }

    return [];
  }

  /// Consulta em lote os pedidos de todas as mesas ocupadas na retaguarda Firebird 5.0
  /// Otimizado para uma única ida ao banco de dados com filtro temporal a partir do menor check-in
  Future<Map<int, List<PedidoResumoModel>>> buscarPedidosMesasOcupadasFirebird({
    required AppConfig config,
    required List<Mesa> mesasOcupadas,
  }) async {
    if (mesasOcupadas.isEmpty) return {};

    DateTime? menorCheckIn;
    final Set<int> identificadoresMesas = {};

    for (final mesa in mesasOcupadas) {
      identificadoresMesas.add(mesa.id);
      final int? codInt = int.tryParse(mesa.codigo);
      if (codInt != null) identificadoresMesas.add(codInt);

      final entrada = mesa.horaEntrada;
      if (entrada != null) {
        if (menorCheckIn == null || entrada.isBefore(menorCheckIn)) {
          menorCheckIn = entrada;
        }
      }
    }

    if (menorCheckIn == null || identificadoresMesas.isEmpty) return {};

    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();
    final String dtSql = TimeFormatter.formatDateTimeSql(menorCheckIn);
    final String listaIds = identificadoresMesas.join(',');

    final sql = '''
SELECT
    PEV_ID,
    PEV_EMPRESA,
    PEV_MESA,
    PEV_DT_LANCAMENTO,
    COALESCE(PEV_VALOR_TOTAL, 0.0) AS PEV_VALOR_TOTAL,
    PEV_STATUS
FROM TB_PEDIDO_VENDA
WHERE PEV_EMPRESA = ${config.empresaId}
  AND PEV_MESA IN ($listaIds)
  AND PEV_DT_LANCAMENTO >= '$dtSql'
  AND COALESCE(PEV_STATUS, '') != 'C'
ORDER BY PEV_DT_LANCAMENTO DESC;
''';

    final Map<int, List<PedidoResumoModel>> resultado = {};

    // 1. Tenta via FbDb nativo
    try {
      final db = await FbDb.attach(
        host: hostLimpo,
        port: porta,
        database: databasePath,
        user: user,
        password: password,
      );

      final q = db.query();
      await q.openCursor(sql: sql);

      await for (final row in q.rows()) {
        final pedido = PedidoResumoModel.fromFirebirdRow(row);
        if (pedido.id > 0) {
          resultado.putIfAbsent(pedido.mesaId, () => []).add(pedido);
        }
      }

      await q.close();
      await db.detach();
      return resultado;
    } catch (_) {}

    // 2. Fallback via ISQL no Windows
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        final sqlIsql = '''
SET HEADING OFF;
SELECT
    PEV_ID || ';' ||
    COALESCE(PEV_EMPRESA, 1) || ';' ||
    PEV_MESA || ';' ||
    PEV_DT_LANCAMENTO || ';' ||
    COALESCE(PEV_VALOR_TOTAL, 0.0) || ';' ||
    COALESCE(PEV_STATUS, 'F')
FROM TB_PEDIDO_VENDA
WHERE PEV_EMPRESA = ${config.empresaId}
  AND PEV_MESA IN ($listaIds)
  AND PEV_DT_LANCAMENTO >= '$dtSql'
  AND COALESCE(PEV_STATUS, '') != 'C'
ORDER BY PEV_DT_LANCAMENTO DESC;
''';
        try {
          final process = await Process.start(
            isqlPath,
            ['-u', user, '-p', password, '-q', stringConexao],
            runInShell: false,
          );

          process.stdin.writeln(sqlIsql);
          process.stdin.writeln('QUIT;');
          await process.stdin.flush();
          await process.stdin.close();

          final output = await process.stdout.transform(systemEncoding.decoder).join();
          final exitCode = await process.exitCode;

          if (exitCode == 0) {
            final linhas = const LineSplitter().convert(output);
            for (final linha in linhas) {
              final trim = linha.trim();
              if (trim.isEmpty || trim.startsWith('Database:') || trim.startsWith('SQL>')) continue;
              final partes = trim.split(';');
              if (partes.length >= 6) {
                final id = int.tryParse(partes[0].trim()) ?? 0;
                final emp = int.tryParse(partes[1].trim()) ?? config.empresaId;
                final mesa = int.tryParse(partes[2].trim()) ?? 0;
                final dt = DateTime.tryParse(partes[3].trim()) ?? DateTime.now();
                final valor = double.tryParse(partes[4].trim()) ?? 0.0;
                final st = partes[5].trim();
                if (id > 0 && mesa > 0) {
                  final pedido = PedidoResumoModel(
                    id: id,
                    empresaId: emp,
                    mesaId: mesa,
                    dataHoraLancamento: dt,
                    valorTotal: valor,
                    status: st,
                  );
                  resultado.putIfAbsent(mesa, () => []).add(pedido);
                }
              }
            }
            return resultado;
          }
        } catch (_) {}
      }
    }

    return resultado;
  }
}
