import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/mesa_model.dart';

class FirebirdBridgeDataSource {
  /// Procura o executável do utilitário isql do Firebird instalado na máquina
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

  /// Conecta diretamente à base de dados Firebird e extrai todas as mesas cadastradas na TB_MESA
  Future<List<MesaModel>> extrairMesasDaBaseFirebird({
    required String caminhoBanco,
    required String usuario,
    required String senha,
    required int empresaId,
  }) async {
    if (kIsWeb || !Platform.isWindows) {
      throw UnsupportedError(
        'A leitura direta de arquivo .FDB via Firebird ISQL está disponível no Windows Desktop. '
        'Para mobile utilize sincronização via API da retaguarda.',
      );
    }

    final isqlPath = _obterCaminhoIsql();
    if (isqlPath == null) {
      throw Exception(
        'Utilitário isql.exe do Firebird não foi localizado em C:\\Program Files\\Firebird. '
        'Certifique-se de que o Firebird está instalado na máquina.',
      );
    }

    if (!File(caminhoBanco).existsSync()) {
      throw Exception(
        'Arquivo de banco de dados não encontrado no caminho informado: $caminhoBanco',
      );
    }

    // Script SQL para exportar em formato delimitado por ponto e vírgula
    final comandoSql = '''
SET HEADING OFF;
SELECT
    MSA_ID || ';' ||
    COALESCE(MSA_EMPRESA, $empresaId) || ';' ||
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
          '-u', usuario,
          '-p', senha,
          '-q',
          caminhoBanco,
        ],
        runInShell: false,
      );

      process.stdin.writeln(comandoSql);
      process.stdin.writeln('QUIT;');
      await process.stdin.flush();
      await process.stdin.close();

      final output = await process.stdout.transform(systemEncoding.decoder).join();
      final errOutput = await process.stderr.transform(systemEncoding.decoder).join();
      final exitCode = await process.exitCode;

      if (exitCode != 0 && errOutput.trim().isNotEmpty) {
        throw Exception('Erro ao conectar ao Firebird: $errOutput');
      }

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
          final int emp = int.tryParse(partes[1].trim()) ?? empresaId;
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

      if (mesas.isEmpty) {
        throw Exception(
          'A tabela TB_MESA foi consultada com sucesso, mas nenhum registro de mesa foi retornado.',
        );
      }

      return mesas;
    } catch (e) {
      throw Exception('Falha na comunicação com o banco de dados Firebird: ${e.toString()}');
    }
  }
}
