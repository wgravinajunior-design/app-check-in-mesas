import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fbdb/fbdb.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/mesas_padrao_mansao.dart';
import '../../core/utils/time_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/consumo_mesa_resumo.dart';
import '../../domain/entities/ingresso.dart';
import '../../domain/entities/mesa.dart';
import '../../domain/entities/pedido_resumo.dart';
import '../../domain/entities/produto.dart';
import '../../domain/entities/status_permanencia.dart';
import '../models/mesa_model.dart';
import '../models/pedido_resumo_model.dart';
import '../models/produto_model.dart';

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
        sql: 'SELECT MSA_ID, MSA_EMPRESA, MSA_CODIGO, '
            'CAST(CAST(MSA_DESCRICAO AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8) AS MSA_DESCRICAO, '
            'MSA_NR_PESSOAS, MSA_STATUS '
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
    COALESCE(TRIM(CAST(CAST(MSA_DESCRICAO AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8)), '') || ';' ||
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

          final rawBytes = await process.stdout.fold<List<int>>([], (prev, element) => prev..addAll(element));
          final output = utf8.decode(rawBytes, allowMalformed: true);
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

  StatusPermanencia _calcularStatus(Duration duracao, AppConfig config, {int? minutosUltimoPedido}) {
    final int minutos = minutosUltimoPedido ?? duracao.inMinutes;
    if (minutos <= config.tempoVerdeMinutos) {
      return StatusPermanencia.normal;
    } else if (minutos <= config.tempoAmareloMinutos) {
      return StatusPermanencia.alertaTolerancia;
    } else {
      return StatusPermanencia.limiteExcedido;
    }
  }

  /// Executa comandos SQL diretamente na base Firebird 5.0 (INSERT / UPDATE em TB_INGRESSO)
  Future<void> executarSqlDiretoNoFirebird({
    required AppConfig config,
    required String sql,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;

    try {
      final db = await FbDb.attach(
        host: hostLimpo,
        port: porta,
        database: config.caminhoBanco.trim(),
        user: config.usuarioBanco.trim(),
        password: config.senhaBanco.trim(),
      );

      try {
        final stmts = sql
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.toUpperCase() != 'COMMIT')
            .toList();

        for (final stmt in stmts) {
          await db.execute(sql: stmt);
        }
        return;
      } finally {
        await db.detach();
      }
    } catch (e) {
      debugPrint('FbDb nativo falhou: $e. Tentando contingência via ISQL...');
      if (!kIsWeb && Platform.isWindows) {
        final isqlPath = _obterCaminhoIsql();
        if (isqlPath != null) {
          final stringConexao = _montarStringConexao(config);
          final user = config.usuarioBanco.trim();
          final password = config.senhaBanco.trim();
          try {
            final process = await Process.start(
              isqlPath,
              ['-u', user, '-p', password, '-q', stringConexao],
              runInShell: false,
            );
            process.stdin.writeln(sql);
            process.stdin.writeln('COMMIT;');
            process.stdin.writeln('QUIT;');
            await process.stdin.flush();
            await process.stdin.close();
            final exitCode = await process.exitCode;
            if (exitCode == 0) return;
          } catch (isqlErr) {
            debugPrint('ISQL fallback falhou: $isqlErr');
          }
        }
      }
      rethrow;
    }
  }

  /// Executa a consulta consolidada oficial fornecida pela equipe do ERP (Lucas Dagnoni):
  /// - CTE de Mesas ativas (TB_MESA WHERE MSA_STATUS = 'A')
  /// - CTE de Ingressos abertos (TB_INGRESSO WHERE ING_STATUS = 'E' AND ING_DT_SAIDA IS NULL)
  /// - Subqueries com Total Consumido, Último Consumo e Quantidade de Pessoas
  Future<List<Mesa>> consultarMesasComIngressosEConsumoFirebird({
    required AppConfig config,
  }) async {
    const sqlOficial = '''
WITH MESAS AS (
  SELECT
    MES.MSA_ID,
    MES.MSA_CODIGO
  FROM TB_MESA MES
  WHERE MES.MSA_STATUS = 'A'
),
INGRESSOS AS (
  SELECT
    ING.ING_CODIGO,
    ING.ING_DT_ENTRADA
  FROM TB_INGRESSO ING
  WHERE ING.ING_STATUS = 'E' AND ING.ING_DT_SAIDA IS NULL
)
SELECT
  MSA_ID,
  MSA_CODIGO,
  ING_CODIGO,
  ING_DT_ENTRADA,
  (SELECT SUM(PV.PEV_VALOR_TOTAL)
   FROM TB_PEDIDO_VENDA PV
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA)
     AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS TOTAL_CONSUMIDO,
  (SELECT COALESCE(MAX(I.PEVI_DT_LANCAMENTO), MAX(PV.PEV_DT_LANCAMENTO))
   FROM TB_PEDIDO_VENDA PV
   LEFT JOIN TB_PEDIDO_VENDA_ITEM I ON I.PEVI_PEDIDO_VENDA = PV.PEV_ID AND (I.PEVI_EMPRESA = PV.PEV_EMPRESA OR I.PEVI_EMPRESA IS NULL)
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA)
     AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS ULTIMO_CONSUMO,
  (SELECT SUM(PV.PEV_QTDE_PESSOAS)
   FROM TB_PEDIDO_VENDA PV
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA)
     AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS QTDE_PESSOAS
FROM MESAS
LEFT JOIN INGRESSOS ON (INGRESSOS.ING_CODIGO = CAST(MESAS.MSA_ID AS VARCHAR(20)) OR INGRESSOS.ING_CODIGO = MESAS.MSA_CODIGO)
ORDER BY MSA_ID;
''';

    final agora = DateTime.now();
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();

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
      await q.openCursor(sql: sqlOficial);

      final List<Mesa> lista = [];
      await for (final row in q.rows()) {
        final int id = int.tryParse(row['MSA_ID']?.toString() ?? '0') ?? 0;
        final String codigo = (row['MSA_CODIGO']?.toString() ?? '').trim();
        if (id <= 0 && codigo.isEmpty) continue;

        final dtEntradaBruta = row['ING_DT_ENTRADA'];
        DateTime? dtEntrada;
        if (dtEntradaBruta is DateTime) {
          dtEntrada = dtEntradaBruta;
        } else if (dtEntradaBruta != null) {
          final str = dtEntradaBruta.toString().trim();
          dtEntrada = DateTime.tryParse(str) ?? DateTime.tryParse(str.replaceAll(' ', 'T'));
        }

        final double totalConsumido = double.tryParse(row['TOTAL_CONSUMIDO']?.toString().replaceAll(',', '.') ?? '0.0') ?? 0.0;
        
        final dtUltimoConsumoBruta = row['ULTIMO_CONSUMO'];
        DateTime? dtUltimoConsumo;
        if (dtUltimoConsumoBruta is DateTime) {
          dtUltimoConsumo = dtUltimoConsumoBruta;
        } else if (dtUltimoConsumoBruta != null) {
          final str = dtUltimoConsumoBruta.toString().trim();
          dtUltimoConsumo = DateTime.tryParse(str) ?? DateTime.tryParse(str.replaceAll(' ', 'T'));
        }

        final int qtdPessoas = int.tryParse(row['QTDE_PESSOAS']?.toString() ?? '0') ?? 0;

        final bool isOcupada = dtEntrada != null;
        Duration decorrido = Duration.zero;
        StatusPermanencia statusPerm = StatusPermanencia.livre;
        Ingresso? ingresso;
        ConsumoMesaResumo? consumoResumo;

        if (isOcupada) {
          decorrido = agora.difference(dtEntrada);
          // Se houver consumo registrado mas data do item for nula, recorre à data de entrada como fallback
          final DateTime? dtConsumoEfetivo = dtUltimoConsumo ?? (totalConsumido > 0 ? dtEntrada : null);
          final int? minutosDesdeUltimo = dtConsumoEfetivo != null
              ? agora.difference(dtConsumoEfetivo).inMinutes
              : null;
          statusPerm = _calcularStatus(decorrido, config, minutosUltimoPedido: minutosDesdeUltimo);
          ingresso = Ingresso(
            empresaId: config.empresaId,
            id: id,
            status: 'E',
            dtEntrada: dtEntrada,
            codigoMesa: codigo,
            observacao: 'Check-in ativo retaguarda',
          );

          PedidoResumo? ultimoPedido;
          if (dtConsumoEfetivo != null) {
            ultimoPedido = PedidoResumo(
              id: 1,
              empresaId: config.empresaId,
              mesaId: id,
              dataHoraLancamento: dtConsumoEfetivo,
              valorTotal: totalConsumido,
              status: 'F',
            );
          }

          consumoResumo = ConsumoMesaResumo(
            mesaId: id,
            codigoMesa: codigo,
            dataCheckIn: dtEntrada,
            ultimoPedido: ultimoPedido,
            minutosDesdeUltimoPedido: minutosDesdeUltimo,
            valorUltimoPedido: totalConsumido,
            valorTotalPedidos: totalConsumido,
            quantidadePedidos: (totalConsumido > 0 || dtConsumoEfetivo != null) ? 1 : 0,
          );
        }

        lista.add(
          Mesa(
            id: id,
            codigo: codigo.isNotEmpty ? codigo : id.toString(),
            descricao: 'Mesa $codigo',
            numeroPessoas: qtdPessoas,
            isOcupada: isOcupada,
            ingressoAtual: ingresso,
            tempoDecorrido: decorrido,
            statusPermanencia: statusPerm,
            consumoResumo: consumoResumo,
          ),
        );
      }

      await q.close();
      await db.detach();

      if (lista.isNotEmpty) {
        return lista;
      }
    } catch (e) {
      debugPrint('FbDb nativo: erro ao consultar CTE mesas/ingressos: $e');
    }

    // 2. Se for Windows Desktop, tenta via ISQL como contingência
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        const sqlIsql = '''
SET HEADING OFF;
WITH MESAS AS (
  SELECT MES.MSA_ID, MES.MSA_CODIGO FROM TB_MESA MES WHERE MES.MSA_STATUS = 'A'
),
INGRESSOS AS (
  SELECT ING.ING_CODIGO, ING.ING_DT_ENTRADA FROM TB_INGRESSO ING WHERE ING.ING_STATUS = 'E' AND ING.ING_DT_SAIDA IS NULL
)
SELECT
  MSA_ID || ';' ||
  TRIM(MSA_CODIGO) || ';' ||
  COALESCE(TRIM(ING_CODIGO), '') || ';' ||
  COALESCE(CAST(ING_DT_ENTRADA AS VARCHAR(30)), '') || ';' ||
  COALESCE(CAST((SELECT SUM(PV.PEV_VALOR_TOTAL) FROM TB_PEDIDO_VENDA PV WHERE PV.PEV_STATUS <> 'C' AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA) AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS VARCHAR(30)), '0') || ';' ||
  COALESCE(CAST((SELECT COALESCE(MAX(I.PEVI_DT_LANCAMENTO), MAX(PV.PEV_DT_LANCAMENTO)) FROM TB_PEDIDO_VENDA PV LEFT JOIN TB_PEDIDO_VENDA_ITEM I ON I.PEVI_PEDIDO_VENDA = PV.PEV_ID AND (I.PEVI_EMPRESA = PV.PEV_EMPRESA OR I.PEVI_EMPRESA IS NULL) WHERE PV.PEV_STATUS <> 'C' AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA) AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS VARCHAR(30)), '') || ';' ||
  COALESCE(CAST((SELECT SUM(PV.PEV_QTDE_PESSOAS) FROM TB_PEDIDO_VENDA PV WHERE PV.PEV_STATUS <> 'C' AND PV.PEV_DT_LANCAMENTO >= DATEADD(-2 MINUTE TO INGRESSOS.ING_DT_ENTRADA) AND (PV.PEV_MESA = MESAS.MSA_ID OR PV.PEV_MESA = MESAS.MSA_CODIGO OR PV.PEV_MESA = INGRESSOS.ING_CODIGO)) AS VARCHAR(10)), '0')
FROM MESAS
LEFT JOIN INGRESSOS ON (INGRESSOS.ING_CODIGO = CAST(MESAS.MSA_ID AS VARCHAR(20)) OR INGRESSOS.ING_CODIGO = MESAS.MSA_CODIGO)
ORDER BY MSA_ID;
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
            final List<Mesa> lista = [];
            final linhas = const LineSplitter().convert(output);
            for (final linha in linhas) {
              final trim = linha.trim();
              if (trim.isEmpty || trim.startsWith('Database:') || trim.startsWith('SQL>')) continue;

              final partes = trim.split(';');
              if (partes.length >= 7) {
                final int id = int.tryParse(partes[0].trim()) ?? 0;
                final String codigo = partes[1].trim();
                final String dtEntradaStr = partes[3].trim();
                final DateTime? dtEntrada = dtEntradaStr.isNotEmpty
                    ? (DateTime.tryParse(dtEntradaStr) ?? DateTime.tryParse(dtEntradaStr.replaceAll(' ', 'T')))
                    : null;
                final double totalConsumido = double.tryParse(partes[4].trim().replaceAll(',', '.')) ?? 0.0;
                final String dtUltimoConsumoStr = partes[5].trim();
                final DateTime? dtUltimoConsumo = dtUltimoConsumoStr.isNotEmpty
                    ? (DateTime.tryParse(dtUltimoConsumoStr) ?? DateTime.tryParse(dtUltimoConsumoStr.replaceAll(' ', 'T')))
                    : null;
                final int qtdPessoas = int.tryParse(partes[6].trim()) ?? 0;

                if (id <= 0 && codigo.isEmpty) continue;

                final bool isOcupada = dtEntrada != null;
                Duration decorrido = Duration.zero;
                StatusPermanencia statusPerm = StatusPermanencia.livre;
                Ingresso? ingresso;
                ConsumoMesaResumo? consumoResumo;

                if (isOcupada) {
                  decorrido = agora.difference(dtEntrada);
                  final DateTime? dtConsumoEfetivo = dtUltimoConsumo ?? (totalConsumido > 0 ? dtEntrada : null);
                  final int? minutosDesdeUltimo = dtConsumoEfetivo != null
                      ? agora.difference(dtConsumoEfetivo).inMinutes
                      : null;
                  statusPerm = _calcularStatus(decorrido, config, minutosUltimoPedido: minutosDesdeUltimo);
                  ingresso = Ingresso(
                    empresaId: config.empresaId,
                    id: id,
                    status: 'E',
                    dtEntrada: dtEntrada,
                    codigoMesa: codigo,
                    observacao: 'Check-in ativo retaguarda',
                  );

                  PedidoResumo? ultimoPedido;
                  if (dtConsumoEfetivo != null) {
                    ultimoPedido = PedidoResumo(
                      id: 1,
                      empresaId: config.empresaId,
                      mesaId: id,
                      dataHoraLancamento: dtConsumoEfetivo,
                      valorTotal: totalConsumido,
                      status: 'F',
                    );
                  }

                  consumoResumo = ConsumoMesaResumo(
                    mesaId: id,
                    codigoMesa: codigo,
                    dataCheckIn: dtEntrada,
                    ultimoPedido: ultimoPedido,
                    minutosDesdeUltimoPedido: minutosDesdeUltimo,
                    valorUltimoPedido: totalConsumido,
                    valorTotalPedidos: totalConsumido,
                    quantidadePedidos: (totalConsumido > 0 || dtConsumoEfetivo != null) ? 1 : 0,
                  );
                }

                lista.add(
                  Mesa(
                    id: id,
                    codigo: codigo.isNotEmpty ? codigo : id.toString(),
                    descricao: 'Mesa $codigo',
                    numeroPessoas: qtdPessoas,
                    isOcupada: isOcupada,
                    ingressoAtual: ingresso,
                    tempoDecorrido: decorrido,
                    statusPermanencia: statusPerm,
                    consumoResumo: consumoResumo,
                  ),
                );
              }
            }

            if (lista.isNotEmpty) {
              return lista;
            }
          }
        } catch (e) {
          debugPrint('ISQL fallback: erro ao consultar CTE mesas/ingressos: $e');
        }
      }
    }

    return [];
  }

  /// Executa o INSERT diretamente na TB_INGRESSO do Firebird no momento do Check-in:
  /// - Status = 'E'
  /// - Data/hora de entrada preenchida
  /// - ING_CODIGO = mesa.id (para o JOIN do CTE: ingressos.ing_codigo = mesas.msa_id)
  Future<void> executarCheckInFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraEntrada,
    String? observacao,
  }) async {
    final dtEntradaSql = TimeFormatter.formatDateTimeSql(dataHoraEntrada);
    final dtEmissaoSql = TimeFormatter.formatDateSql(dataHoraEntrada);
    final hrEventoSql = TimeFormatter.formatTime(dataHoraEntrada);
    final obs = (observacao ?? 'Check-in efetuado via App').replaceAll("'", "''");

    final sql = '''
INSERT INTO TB_INGRESSO (
    ING_EMPRESA,
    ING_ID,
    ING_STATUS,
    ING_USUARIO,
    ING_DT_LANCAMENTO,
    ING_DT_EMISSAO,
    ING_DT_EVENTO,
    ING_HR_EVENTO,
    ING_DT_ENTRADA,
    ING_DT_SAIDA,
    ING_DURACAO,
    ING_PESSOA,
    ING_TIPO_INGRESSO,
    ING_VALOR,
    ING_OBSERVACAO,
    ING_PEDIDO,
    ING_CODIGO,
    ING_TOTAL_RECEBIDO,
    ING_TOTAL_PRODUTOS,
    ING_VALOR_DIFERENCA,
    ING_CAIXA,
    ING_FECHAMENTO,
    ING_TROCO,
    ING_TIPO_TROCO,
    ING_GERAR_FINANCEIRO
) VALUES (
    ${config.empresaId},
    (SELECT COALESCE(MAX(ING_ID), 0) + 1 FROM TB_INGRESSO WHERE ING_EMPRESA = ${config.empresaId}),
    'E',
    1,
    '$dtEntradaSql',
    '$dtEmissaoSql',
    '$dtEmissaoSql',
    '$hrEventoSql',
    '$dtEntradaSql',
    NULL,
    0,
    NULL,
    1,
    0.00,
    '$obs',
    NULL,
    '${mesa.id}',
    0.00,
    0.00,
    0.00,
    1,
    NULL,
    0.00,
    NULL,
    'N'
);
''';

    await executarSqlDiretoNoFirebird(config: config, sql: sql);
  }

  /// Executa o UPDATE diretamente na TB_INGRESSO do Firebird no momento do Check-out:
  /// - Status = 'F'
  /// - Data/hora de saída preenchida
  /// - Duração em minutos preenchida
  Future<void> executarCheckOutFirebird({
    required AppConfig config,
    required Mesa mesa,
    required DateTime dataHoraSaida,
  }) async {
    final DateTime dataEntrada = mesa.horaEntrada ?? dataHoraSaida;
    final int duracaoMinutos = dataHoraSaida.difference(dataEntrada).inMinutes;
    final dtSaidaSql = TimeFormatter.formatDateTimeSql(dataHoraSaida);

    final sql = '''
UPDATE TB_INGRESSO
SET ING_STATUS = 'F',
    ING_DT_SAIDA = '$dtSaidaSql',
    ING_DURACAO = $duracaoMinutos,
    ING_OBSERVACAO = COALESCE(ING_OBSERVACAO, '') || ' | Saída registrada via App'
WHERE ING_EMPRESA = ${config.empresaId}
  AND (ING_CODIGO = '${mesa.id}' OR ING_CODIGO = '${mesa.codigo}')
  AND (ING_STATUS = 'E' OR ING_STATUS = 'A')
  AND ING_DT_SAIDA IS NULL;
''';

    await executarSqlDiretoNoFirebird(config: config, sql: sql);
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
    final String dtSql = TimeFormatter.formatDateTimeSql(
      dataCheckIn.subtract(const Duration(minutes: 2)),
    );

    final sql = '''
SELECT
    PEV_ID,
    PEV_EMPRESA,
    PEV_MESA,
    PEV_DT_LANCAMENTO,
    COALESCE(PEV_VALOR_TOTAL, 0.0) AS PEV_VALOR_TOTAL,
    PEV_STATUS
FROM TB_PEDIDO_VENDA
WHERE (PEV_EMPRESA = ${config.empresaId} OR PEV_EMPRESA IS NULL)
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
WHERE (PEV_EMPRESA = ${config.empresaId} OR PEV_EMPRESA IS NULL)
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
    final String dtSql = TimeFormatter.formatDateTimeSql(
      menorCheckIn.subtract(const Duration(minutes: 2)),
    );
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
WHERE (PEV_EMPRESA = ${config.empresaId} OR PEV_EMPRESA IS NULL)
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
WHERE (PEV_EMPRESA = ${config.empresaId} OR PEV_EMPRESA IS NULL)
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

  /// Consulta todos os produtos cadastrados na TB_PRODUTO da retaguarda Firebird 5.0
  Future<List<ProdutoModel>> listarProdutosDaBaseFirebird({
    required AppConfig config,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco > 0 ? config.portaBanco : AppConstants.defaultPortaFirebird;
    final databasePath = config.caminhoBanco.trim();
    final user = config.usuarioBanco.trim();
    final password = config.senhaBanco.trim();

    final sql = '''
SELECT
    P.PRD_ID,
    COALESCE(P.PRD_EMPRESA, ${config.empresaId}) AS PRD_EMPRESA,
    COALESCE(P.PRD_CODIGO, CAST(P.PRD_ID AS VARCHAR(20))) AS PRD_CODIGO,
    CAST(CAST(P.PRD_DESCRICAO AS VARCHAR(200) CHARACTER SET WIN1252) AS VARCHAR(200) CHARACTER SET UTF8) AS PRD_DESCRICAO,
    COALESCE(P.PRD_STATUS, 'A') AS PRD_STATUS,
    COALESCE(P.PRD_PRECO_VENDA, 0.0) AS PRD_PRECO_VENDA,
    CAST(CAST(G.PGRU_DESCRICAO AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8) AS PGRU_DESCRICAO,
    CAST(CAST(P.PRD_REFERENCIA AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8) AS PRD_REFERENCIA,
    CAST(CAST(P.PRD_UN_VENDA AS VARCHAR(20) CHARACTER SET WIN1252) AS VARCHAR(20) CHARACTER SET UTF8) AS PRD_UN_VENDA
FROM TB_PRODUTO P
LEFT JOIN TB_PROD_GRUPO G ON G.PGRU_ID = P.PRD_GRUPO AND (G.PGRU_EMPRESA = P.PRD_EMPRESA OR G.PGRU_EMPRESA IS NULL)
WHERE (P.PRD_EMPRESA = ${config.empresaId} OR P.PRD_EMPRESA IS NULL)
ORDER BY P.PRD_DESCRICAO ASC;
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

      final List<ProdutoModel> produtos = [];
      await for (final row in q.rows()) {
        final prod = ProdutoModel.fromFirebirdRow(row);
        if (prod.id > 0 && prod.descricao.isNotEmpty) {
          produtos.add(prod);
        }
      }

      await q.close();
      await db.detach();

      if (produtos.isNotEmpty) {
        return produtos;
      }
    } catch (e) {
      debugPrint('FbDb nativo: erro ao listar produtos: $e');
    }

    // 2. Fallback via ISQL no Windows
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        final sqlIsql = '''
SET HEADING OFF;
SELECT
    P.PRD_ID || ';' ||
    COALESCE(P.PRD_EMPRESA, ${config.empresaId}) || ';' ||
    COALESCE(P.PRD_CODIGO, CAST(P.PRD_ID AS VARCHAR(20))) || ';' ||
    COALESCE(CAST(CAST(P.PRD_DESCRICAO AS VARCHAR(200) CHARACTER SET WIN1252) AS VARCHAR(200) CHARACTER SET UTF8), '') || ';' ||
    COALESCE(P.PRD_STATUS, 'A') || ';' ||
    COALESCE(P.PRD_PRECO_VENDA, 0.0) || ';' ||
    COALESCE(CAST(CAST(G.PGRU_DESCRICAO AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8), '') || ';' ||
    COALESCE(CAST(CAST(P.PRD_REFERENCIA AS VARCHAR(100) CHARACTER SET WIN1252) AS VARCHAR(100) CHARACTER SET UTF8), '') || ';' ||
    COALESCE(CAST(CAST(P.PRD_UN_VENDA AS VARCHAR(20) CHARACTER SET WIN1252) AS VARCHAR(20) CHARACTER SET UTF8), '')
FROM TB_PRODUTO P
LEFT JOIN TB_PROD_GRUPO G ON G.PGRU_ID = P.PRD_GRUPO AND (G.PGRU_EMPRESA = P.PRD_EMPRESA OR G.PGRU_EMPRESA IS NULL)
WHERE (P.PRD_EMPRESA = ${config.empresaId} OR P.PRD_EMPRESA IS NULL)
ORDER BY P.PRD_DESCRICAO ASC;
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

          final rawBytes = await process.stdout.fold<List<int>>([], (prev, element) => prev..addAll(element));
          final output = utf8.decode(rawBytes, allowMalformed: true);
          final exitCode = await process.exitCode;

          if (exitCode == 0) {
            final List<ProdutoModel> produtos = [];
            final linhas = const LineSplitter().convert(output);
            for (final linha in linhas) {
              final trim = linha.trim();
              if (trim.isEmpty || trim.startsWith('Database:') || trim.startsWith('SQL>')) continue;
              final partes = trim.split(';');
              if (partes.length >= 6) {
                final id = int.tryParse(partes[0].trim()) ?? 0;
                final emp = int.tryParse(partes[1].trim()) ?? config.empresaId;
                final cod = partes[2].trim();
                final desc = partes[3].trim();
                final st = partes[4].trim();
                final preco = double.tryParse(partes[5].trim()) ?? 0.0;
                final grupo = partes.length > 6 && partes[6].trim().isNotEmpty ? partes[6].trim() : null;
                final ref = partes.length > 7 && partes[7].trim().isNotEmpty ? partes[7].trim() : null;
                final un = partes.length > 8 && partes[8].trim().isNotEmpty ? partes[8].trim() : null;

                if (id > 0 && desc.isNotEmpty) {
                  produtos.add(ProdutoModel(
                    id: id,
                    empresaId: emp,
                    codigo: cod.isEmpty ? id.toString() : cod,
                    descricao: desc,
                    status: st.isEmpty ? 'A' : st,
                    precoVenda: preco,
                    grupoDescricao: grupo,
                    referencia: ref,
                    unidadeVenda: un,
                  ));
                }
              }
            }
            if (produtos.isNotEmpty) {
              return produtos;
            }
          }
        } catch (e) {
          debugPrint('ISQL fallback: erro ao listar produtos: $e');
        }
      }
    }

    return [];
  }

  /// Altera o status do produto ('A' ou 'I') na TB_PRODUTO e grava a auditoria na TB_AUDITORIA e TB_AUDITORIA_ITEM
  Future<void> alterarStatusProdutoFirebird({
    required AppConfig config,
    required Produto produto,
    required bool ativar,
    int usuarioId = 1,
  }) async {
    final String novoStatus = ativar ? 'A' : 'I';
    final String statusAntigo = produto.status.trim().toUpperCase();
    final String descSafe = produto.descricao.replaceAll("'", "''");

    final sql = '''
UPDATE TB_PRODUTO
SET PRD_STATUS = '$novoStatus',
    PRD_ULTIMA_ALTERACAO = CURRENT_TIMESTAMP
WHERE PRD_EMPRESA = ${config.empresaId} AND PRD_ID = ${produto.id};

INSERT INTO TB_AUDITORIA (
    AUD_EMPRESA,
    AUD_TABELA,
    AUD_ID_REGISTRO,
    AUD_SEQUENCIA,
    AUD_TABELA_DESC,
    AUD_ACAO,
    AUD_DT_LANCAMENTO,
    AUD_DT_ACAO,
    AUD_USUARIO,
    AUD_DESC_REGISTRO,
    AUD_VERSAO,
    AUD_VERSAO_SERVIDOR
) VALUES (
    ${config.empresaId},
    'TB_PRODUTO',
    '${produto.id}',
    (SELECT COALESCE(MAX(AUD_SEQUENCIA), 0) + 1 FROM TB_AUDITORIA WHERE AUD_EMPRESA = ${config.empresaId}),
    'PRODUTOS',
    'A',
    CURRENT_TIMESTAMP,
    CURRENT_DATE,
    $usuarioId,
    '$descSafe',
    'CheckMesa',
    'CheckMesa'
);

INSERT INTO TB_AUDITORIA_ITEM (
    AUDI_EMPRESA,
    AUDI_TABELA,
    AUDI_ID_REGISTRO,
    AUDI_AUDITORIA,
    AUDI_CAMPO,
    AUDI_CAMPO_DESC,
    AUDI_VALOR_ANTIGO,
    AUDI_VALOR_NOVO
) VALUES (
    ${config.empresaId},
    'TB_PRODUTO',
    '${produto.id}',
    (SELECT MAX(AUD_SEQUENCIA) FROM TB_AUDITORIA WHERE AUD_EMPRESA = ${config.empresaId} AND AUD_TABELA = 'TB_PRODUTO' AND AUD_ID_REGISTRO = '${produto.id}'),
    'PRD_STATUS',
    'Status',
    '$statusAntigo',
    '$novoStatus'
);
COMMIT;
''';

    await executarSqlDiretoNoFirebird(config: config, sql: sql);
  }
}

