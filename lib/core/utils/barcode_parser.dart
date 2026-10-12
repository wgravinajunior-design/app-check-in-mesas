/// Utilitário inteligente para extração e normalização de códigos de mesas e comandas
/// obtidos a partir de leituras de QR Code ou Códigos de Barras.
class BarcodeParser {
  /// Extrai e limpa o código ou identificador numérico de um valor lido.
  ///
  /// Exemplos de entrada suportados:
  /// - "15" -> "15"
  /// - "015" -> "015"
  /// - "Mesa 15" -> "15"
  /// - "M-04" -> "4"
  /// - "COMANDA 042" -> "42"
  /// - "https://app.restaurante.com/mesa?num=15" -> "15"
  /// - "https://app.restaurante.com/comanda/42" -> "42"
  static String? extrairIdentificador(String? raw) {
    if (raw == null) return null;
    final valor = raw.trim();
    if (valor.isEmpty) return null;

    // Se for URL, tenta extrair parâmetros ou segmento final
    if (valor.startsWith('http://') || valor.startsWith('https://')) {
      final uri = Uri.tryParse(valor);
      if (uri != null) {
        // Verifica parâmetros de query como ?mesa=15, ?num=15, ?comanda=42
        for (final chave in ['mesa', 'num', 'numero', 'comanda', 'id', 'codigo']) {
          final param = uri.queryParameters[chave];
          if (param != null && param.isNotEmpty) {
            return _limparDigitosOuTexto(param);
          }
        }
        // Verifica o último segmento do caminho (ex.: /mesa/15 -> 15)
        if (uri.pathSegments.isNotEmpty) {
          final ultimo = uri.pathSegments.last;
          if (RegExp(r'\d+').hasMatch(ultimo)) {
            return _limparDigitosOuTexto(ultimo);
          }
        }
      }
    }

    // Se contiver prefixos como "MESA", "COM.", "CMD", "M-", "C-", extrai os números
    final regexNumeros = RegExp(r'\d+');
    final match = regexNumeros.firstMatch(valor);
    if (match != null) {
      return match.group(0);
    }

    // Caso seja um código alfanumérico (ex.: "VIP-A")
    return valor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
  }

  static String _limparDigitosOuTexto(String texto) {
    final match = RegExp(r'\d+').firstMatch(texto);
    if (match != null) {
      return match.group(0)!;
    }
    return texto.trim();
  }

  /// Converte para o padrão de código de 3 dígitos (ex.: "15" -> "015")
  static String formatarCodigoTresDigitos(String identificador) {
    final numero = int.tryParse(identificador);
    if (numero != null) {
      return numero.toString().padLeft(3, '0');
    }
    return identificador;
  }
}
