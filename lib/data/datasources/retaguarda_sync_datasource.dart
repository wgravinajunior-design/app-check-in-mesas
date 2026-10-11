import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/time_formatter.dart';
import '../models/ingresso_model.dart';

class RetaguardaSyncDataSource {
  final http.Client httpClient;

  RetaguardaSyncDataSource({http.Client? client})
      : httpClient = client ?? http.Client();

  /// Gera a instrução SQL DML completa e formatada pronta para execução direta no Firebird
  String gerarSqlInsercaoFirebird(IngressoModel ingresso) {
    final String dtLancamento = TimeFormatter.formatDateTime(ingresso.dtLancamento);
    final String dtEmissao = ingresso.dtEmissao != null ? TimeFormatter.formatDateSql(ingresso.dtEmissao!) : '';
    final String dtEvento = ingresso.dtEvento != null ? TimeFormatter.formatDateSql(ingresso.dtEvento!) : '';
    final String dtEntrada = TimeFormatter.formatDateTime(ingresso.dtEntrada);

    return '''
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
    ${ingresso.empresaId},
    ${ingresso.id},
    '${ingresso.status}',
    ${ingresso.usuarioId ?? 1},
    '$dtLancamento',
    '$dtEmissao',
    '$dtEvento',
    '${ingresso.hrEvento ?? '00:00:00'}',
    '$dtEntrada',
    NULL,
    0,
    NULL,
    ${ingresso.tipoIngressoId ?? 1},
    ${ingresso.valor.toStringAsFixed(2)},
    '${ingresso.observacao?.replaceAll("'", "''") ?? ''}',
    NULL,
    '${ingresso.codigoMesa}',
    ${ingresso.totalRecebido.toStringAsFixed(2)},
    ${ingresso.totalProdutos.toStringAsFixed(2)},
    ${ingresso.valorDiferenca.toStringAsFixed(2)},
    ${ingresso.caixaId ?? 1},
    NULL,
    ${ingresso.troco.toStringAsFixed(2)},
    NULL,
    '${ingresso.gerarFinanceiro}'
);
''';
  }

  /// Gera a instrução SQL UPDATE completa para encerramento de permanência na retaguarda Firebird
  String gerarSqlCheckOutFirebird(IngressoModel ingresso) {
    final String dtSaida = TimeFormatter.formatDateTime(ingresso.dtSaida);

    return '''
UPDATE TB_INGRESSO
SET ING_STATUS = 'F',
    ING_DT_SAIDA = '$dtSaida',
    ING_DURACAO = ${ingresso.duracaoMinutos ?? 0}
WHERE ING_EMPRESA = ${ingresso.empresaId}
  AND ING_ID = ${ingresso.id};
''';
  }

  /// Sincronização via API REST quando configurada
  Future<bool> sincronizarViaApi({
    required String apiUrl,
    required IngressoModel ingresso,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$apiUrl/ingressos/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ingresso.toJson()),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // Falhas de rede mantêm a integridade local offline
      return false;
    }
  }
}
