import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Cores Dinâmicas Semafóricas para Estados de Mesa e Pedidos
  static const Color corMesaLivre = Color(0xFF64748B); // Slate profissional para mesa livre / desocupada
  static const Color corMesaLivreClaro = Color(0xFFF1F5F9);

  static const Color corMesaNormal = Color(0xFF16A34A); // Verde: Em atendimento / Pedido recente dentro da tolerância
  static const Color corMesaNormalClaro = Color(0xFFDCFCE7);

  static const Color corMesaAlerta = Color(0xFFD97706); // Amarelo/Âmbar: Alerta de tolerância sem pedidos
  static const Color corMesaAlertaClaro = Color(0xFFFEF3C7);

  static const Color corMesaExcedida = Color(0xFFDC2626); // Vermelho: Limite excedido / muito tempo sem pedir
  static const Color corMesaExcedidaClaro = Color(0xFFFEE2E2);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1),
      brightness: Brightness.light,
      primary: const Color(0xFF0D47A1),
      onPrimary: Colors.white,
      secondary: const Color(0xFF00897B),
      surface: const Color(0xFFF8F9FA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.dark,
      primary: const Color(0xFF90CAF9),
      onPrimary: const Color(0xFF003258),
      secondary: const Color(0xFF80CBC4),
      surface: const Color(0xFF1E1E1E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
