import 'package:flutter_test/flutter_test.dart';
import 'package:apk_check_in/core/constants/app_constants.dart';
import 'package:apk_check_in/core/constants/mesas_padrao_mansao.dart';
import 'package:apk_check_in/core/utils/time_formatter.dart';
import 'package:apk_check_in/domain/entities/app_config.dart';
import 'package:apk_check_in/domain/entities/status_permanencia.dart';

void main() {
  group('Testes de Domínio e Formatação de Permanência', () {
    test('Formatação de cronômetro deve exibir HH:MM:SS com padding zero', () {
      const duracao1 = Duration(hours: 1, minutes: 25, seconds: 40);
      expect(TimeFormatter.formatCronometro(duracao1), equals('01:25:40'));

      const duracao2 = Duration(minutes: 5, seconds: 9);
      expect(TimeFormatter.formatCronometro(duracao2), equals('00:05:09'));
    });

    test('Extensão de StatusPermanencia deve mapear rótulos corretos', () {
      expect(StatusPermanencia.livre.rotulo, equals('LIVRE'));
      expect(StatusPermanencia.normal.rotulo, equals('EM ATENDIMENTO'));
      expect(StatusPermanencia.alertaTolerancia.rotulo, equals('ALERTA TOLERÂNCIA'));
      expect(StatusPermanencia.limiteExcedido.rotulo, equals('TEMPO EXCEDIDO'));
    });

    test('Catálogo oficial da Mansão da Torre deve conter 75 mesas cadastradas', () {
      final mesas = MesasPadraoMansao.obterMesasPadrao(1);
      expect(mesas.length, equals(75));
      expect(mesas.first.codigo, equals('001'));
      expect(AppConstants.defaultTotalMesas, equals(75));
    });

    test('AppConfig deve montar string de conexão Firebird 5.0 corretamente', () {
      const config = AppConfig(
        hostBanco: '192.168.0.109',
        portaBanco: 3060,
        caminhoBanco: r'C:\Users\Walter\OneDrive\DADOS\MANSAO\DADOS.FDB',
      );
      expect(
        config.stringConexaoFirebird,
        equals(r'192.168.0.109/3060:C:\Users\Walter\OneDrive\DADOS\MANSAO\DADOS.FDB'),
      );
    });
  });
}
