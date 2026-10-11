import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Representa a faixa de permanência calculada em tempo real para a mesa
enum StatusPermanencia {
  livre,
  normal,
  alertaTolerancia,
  limiteExcedido,
}

extension StatusPermanenciaExtension on StatusPermanencia {
  String get rotulo {
    switch (this) {
      case StatusPermanencia.livre:
        return 'LIVRE';
      case StatusPermanencia.normal:
        return 'EM ATENDIMENTO';
      case StatusPermanencia.alertaTolerancia:
        return 'ALERTA TOLERÂNCIA';
      case StatusPermanencia.limiteExcedido:
        return 'TEMPO EXCEDIDO';
    }
  }

  Color get corPrimaria {
    switch (this) {
      case StatusPermanencia.livre:
        return AppTheme.corMesaLivre;
      case StatusPermanencia.normal:
        return AppTheme.corMesaNormal;
      case StatusPermanencia.alertaTolerancia:
        return AppTheme.corMesaAlerta;
      case StatusPermanencia.limiteExcedido:
        return AppTheme.corMesaExcedida;
    }
  }

  Color get corFundoClara {
    switch (this) {
      case StatusPermanencia.livre:
        return AppTheme.corMesaLivreClaro;
      case StatusPermanencia.normal:
        return AppTheme.corMesaNormalClaro;
      case StatusPermanencia.alertaTolerancia:
        return AppTheme.corMesaAlertaClaro;
      case StatusPermanencia.limiteExcedido:
        return AppTheme.corMesaExcedidaClaro;
    }
  }

  IconData get icone {
    switch (this) {
      case StatusPermanencia.livre:
        return Icons.table_bar;
      case StatusPermanencia.normal:
        return Icons.timer_outlined;
      case StatusPermanencia.alertaTolerancia:
        return Icons.warning_amber_rounded;
      case StatusPermanencia.limiteExcedido:
        return Icons.alarm_on_rounded;
    }
  }
}
