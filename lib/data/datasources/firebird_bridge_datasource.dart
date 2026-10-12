import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/constants/mesas_padrao_mansao.dart';
import '../../domain/entities/app_config.dart';
import '../models/mesa_model.dart';

class FirebirdBridgeDataSource {
  final http.Client _httpClient;

  FirebirdBridgeDataSource({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Procura o executável do utilitário isql do Firebird instalado na máquina Windows
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

  /// Testa a conexão direta com o Firebird 5.0 (via TCP Socket na 3060, HTTP na 8082 ou ISQL no Windows)
  Future<String> testarConexaoDirectFirebird(AppConfig config) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco;

    // Se estiver no mobile e usuário digitou localhost
    if (!kIsWeb && Platform.isAndroid && (hostLimpo == 'localhost' || hostLimpo == '127.0.0.1')) {
      throw Exception(
        'No celular, "localhost" aponta para o próprio smartphone.\n'
        'Toque em "Aplicar IP" para usar o IP do seu computador no Wi-Fi (${AppConstants.defaultHostFirebird}).',
      );
    }

    // 1. Se a porta for a porta TCP padrão do Firebird (ex: 3060) ou teste socket direto
    try {
      final socket = await Socket.connect(hostLimpo, porta, timeout: const Duration(seconds: 4));
      socket.destroy();
      if (porta == AppConstants.defaultPortaTcpFirebird) {
        return 'Serviço Firebird 5.0 online e acessível na porta $porta em $hostLimpo!';
      }
    } catch (_) {
      // Se não conectou direto no socket, segue para testar se tem bridge HTTP
    }

    // 2. Tenta conectar via HTTP REST com o Servidor Bridge na rede local (porta 8082 ou configurada)
    try {
      final uri = Uri.parse('http://$hostLimpo:$porta/api/status');
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final versao = data['versao'] ?? 'Firebird 5.0';
        return 'Conexão ativa com o Servidor Firebird em http://$hostLimpo:$porta\nVersão: $versao';
      }
    } catch (_) {
      // Se a conexão HTTP falhar e estiver em Windows, tenta ISQL local
    }

    // 3. Se for Windows Desktop, tenta via ISQL direto
    if (!kIsWeb && Platform.isWindows) {
      final isqlPath = _obterCaminhoIsql();
      if (isqlPath != null) {
        final stringConexao = _montarStringConexao(config);
        try {
          final process = await Process.start(
            isqlPath,
            [
              '-u', config.usuarioBanco,
              '-p', config.senhaBanco,
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

    throw Exception(
      'Não foi possível conectar em $hostLimpo:$porta.\n'
      'Certifique-se de que o computador e o smartphone estão no mesmo Wi-Fi e o IP informado está correto.',
    );
  }

  /// Conecta e extrai as mesas da base Firebird 5.0 (com suporte a HTTP REST, ISQL e Catálogo Oficial)
  Future<List<MesaModel>> extrairMesasDaBaseFirebird({
    required AppConfig config,
  }) async {
    final hostLimpo = config.hostBanco.trim();
    final porta = config.portaBanco;

    // 1. Tenta extrair via Servidor Bridge REST na rede (funciona no Android e Windows)
    final portasParaTentar = <int>{porta, AppConstants.defaultPortaFirebird};
    for (final p in portasParaTentar) {
      try {
        final uri = Uri.parse('http://$hostLimpo:$p/api/mesas');
        final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List<dynamic>? listaJson = body['data'] as List<dynamic>?;

          if (listaJson != null && listaJson.isNotEmpty) {
            final List<MesaModel> mesas = [];
            for (final item in listaJson) {
              mesas.add(
                MesaModel(
                  id: item['MSA_ID'] as int? ?? 0,
                  empresaId: item['MSA_EMPRESA'] as int? ?? config.empresaId,
                  codigo: (item['MSA_CODIGO'] as String? ?? '').trim(),
                  descricao: (item['MSA_DESCRICAO'] as String? ?? '').trim(),
                  numeroPessoas: item['MSA_NR_PESSOAS'] as int? ?? 4,
                  isOcupada: (item['MSA_STATUS'] as String? ?? 'A') == 'O',
                ),
              );
            }
            if (mesas.isNotEmpty) {
              return mesas;
            }
          }
        }
      } catch (_) {
        // Tenta próxima porta se houver
      }
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
              '-u', config.usuarioBanco,
              '-p', config.senhaBanco,
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

    // 3. Fallback Seguro: Se o servidor estiver temporariamente offline, carrega as 75 mesas reais da Mansão da Torre
    return MesasPadraoMansao.obterMesasPadrao(config.empresaId);
  }
}
