import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apk_check_in/core/constants/app_constants.dart';
import 'package:apk_check_in/core/constants/mesas_padrao_mansao.dart';
import 'package:apk_check_in/core/services/lan_sync_service.dart';
import 'package:apk_check_in/core/theme/app_theme.dart';
import 'package:apk_check_in/core/utils/barcode_parser.dart';
import 'package:apk_check_in/core/utils/time_formatter.dart';
import 'package:apk_check_in/data/models/config_model.dart';
import 'package:apk_check_in/domain/entities/app_config.dart';
import 'package:apk_check_in/domain/entities/comanda.dart';
import 'package:apk_check_in/domain/entities/consumo_mesa_resumo.dart';
import 'package:apk_check_in/domain/entities/mesa.dart';
import 'package:apk_check_in/domain/entities/pedido_resumo.dart';
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

    test('AppConfig deve inicializar e permitir alternar permissões e modo escuro', () {
      const configPadrao = AppConfig();
      expect(configPadrao.permitirTransferirMesas, isTrue);
      expect(configPadrao.alertaSonoro, isTrue);
      expect(configPadrao.modoEscuro, isFalse);

      final configModificada = configPadrao.copyWith(
        permitirTransferirMesas: false,
        alertaSonoro: false,
        modoEscuro: true,
      );
      expect(configModificada.permitirTransferirMesas, isFalse);
      expect(configModificada.alertaSonoro, isFalse);
      expect(configModificada.modoEscuro, isTrue);
    });

    test('TimeFormatter formatDuration e formatDuracaoAmigavel devem formatar corretamente', () {
      const duracao = Duration(hours: 2, minutes: 15, seconds: 30);
      expect(TimeFormatter.formatDuration(duracao), equals('02:15:30'));
      expect(TimeFormatter.formatDuracaoAmigavel(duracao), equals('2h 15m'));
    });

    test('AppConfig deve suportar sincronizarMesas e sincronizarComandas com padroes corretos', () {
      const configPadrao = AppConfig();
      expect(configPadrao.sincronizarMesas, isTrue);
      expect(configPadrao.sincronizarComandas, isFalse);
      expect(configPadrao.totalComandas, equals(50));

      final configModificada = configPadrao.copyWith(
        sincronizarMesas: false,
        sincronizarComandas: true,
        totalComandas: 100,
      );
      expect(configModificada.sincronizarMesas, isFalse);
      expect(configModificada.sincronizarComandas, isTrue);
      expect(configModificada.totalComandas, equals(100));
    });

    test('Entidade Comanda deve suportar campos e transicoes de status', () {
      const comandaLivre = Comanda(
        id: 10,
        empresaId: 1,
        codigo: '010',
        descricao: 'Comanda 010',
        isOcupada: false,
        statusPermanencia: StatusPermanencia.livre,
      );
      expect(comandaLivre.isOcupada, isFalse);
      expect(comandaLivre.statusPermanencia, equals(StatusPermanencia.livre));
      expect(comandaLivre.nomeExibicao, equals('Comanda 010'));

      final comandaOcupada = comandaLivre.copyWith(
        isOcupada: true,
        statusPermanencia: StatusPermanencia.normal,
        tempoDecorrido: const Duration(minutes: 30),
      );
      expect(comandaOcupada.isOcupada, isTrue);
      expect(comandaOcupada.statusPermanencia, equals(StatusPermanencia.normal));
      expect(comandaOcupada.tempoDecorrido.inMinutes, equals(30));
    });

    test('BarcodeParser deve extrair e formatar códigos de mesas e comandas de QR Code e URLs', () {
      expect(BarcodeParser.extrairIdentificador('15'), equals('15'));
      expect(BarcodeParser.extrairIdentificador('015'), equals('015'));
      expect(BarcodeParser.extrairIdentificador('Mesa 15'), equals('15'));
      expect(BarcodeParser.extrairIdentificador('M-05'), equals('05'));
      expect(BarcodeParser.extrairIdentificador('COMANDA 42'), equals('42'));
      expect(BarcodeParser.extrairIdentificador('https://meurestaurante.com/mesa?num=22'), equals('22'));
      expect(BarcodeParser.extrairIdentificador('https://meurestaurante.com/comanda/35'), equals('35'));

      expect(BarcodeParser.formatarCodigoTresDigitos('5'), equals('005'));
      expect(BarcodeParser.formatarCodigoTresDigitos('15'), equals('015'));
      expect(BarcodeParser.formatarCodigoTresDigitos('100'), equals('100'));
    });

    test('ConsumoMesaResumo deve calcular último pedido, minutos decorridos e somatório total (Modelo Pré-pago)', () {
      final dataCheckIn = DateTime(2026, 10, 13, 19, 0, 0);
      final pedido1 = PedidoResumo(
        id: 101,
        empresaId: 1,
        mesaId: 23,
        dataHoraLancamento: DateTime(2026, 10, 13, 19, 15, 0),
        valorTotal: 54.90,
        status: 'F',
      );
      final pedido2 = PedidoResumo(
        id: 102,
        empresaId: 1,
        mesaId: 23,
        dataHoraLancamento: DateTime(2026, 10, 13, 19, 45, 0),
        valorTotal: 120.00,
        status: 'F',
      );
      final pedido3 = PedidoResumo(
        id: 103,
        empresaId: 1,
        mesaId: 23,
        dataHoraLancamento: DateTime(2026, 10, 13, 20, 10, 0),
        valorTotal: 35.00,
        status: 'F',
      );

      // Instante atual: 20:25:00 (15 minutos após o pedido3)
      final agora = DateTime(2026, 10, 13, 20, 25, 0);

      final resumo = ConsumoMesaResumo.processar(
        mesaId: 23,
        codigoMesa: '023',
        dataCheckIn: dataCheckIn,
        pedidosFiltrados: [pedido1, pedido2, pedido3],
        agora: agora,
      );

      expect(resumo.temPedidos, isTrue);
      expect(resumo.quantidadePedidos, equals(3));
      // Último pedido capturado pela ordenação decrescente
      expect(resumo.ultimoPedido?.id, equals(103));
      expect(resumo.valorUltimoPedido, equals(35.00));
      // Diferença em minutos entre 20:25:00 e 20:10:00 = 15 minutos
      expect(resumo.minutosDesdeUltimoPedido, equals(15));
      // Somatório total de todos os pedidos desde o check-in: 54.90 + 120.00 + 35.00 = 209.90
      expect(resumo.valorTotalPedidos, closeTo(209.90, 0.001));

      // Teste com lista vazia (sem pedidos após o check-in)
      final resumoVazio = ConsumoMesaResumo.processar(
        mesaId: 23,
        codigoMesa: '023',
        dataCheckIn: dataCheckIn,
        pedidosFiltrados: [],
        agora: agora,
      );
      expect(resumoVazio.temPedidos, isFalse);
      expect(resumoVazio.quantidadePedidos, equals(0));
      expect(resumoVazio.ultimoPedido, isNull);
      expect(resumoVazio.minutosDesdeUltimoPedido, isNull);
      expect(resumoVazio.valorUltimoPedido, equals(0.0));
      expect(resumoVazio.valorTotalPedidos, equals(0.0));
    });

    test('Status de TB_INGRESSO deve seguir padrão ERP Firebird (E e F)', () {
      expect(AppConstants.statusIngressoAberto, equals('E'));
      expect(AppConstants.statusIngressoFinalizado, equals('F'));
    });

    test('Entidade Mesa deve armazenar campo de pessoas retornado da consulta SQL', () {
      const mesa = Mesa(
        id: 5,
        codigo: '005',
        numeroPessoas: 6,
        isOcupada: true,
      );
      expect(mesa.numeroPessoas, equals(6));
    });

    test('Parsing de datas do Firebird e ISQL com diferentes formatos', () {
      final t1 = DateTime.tryParse('2026-10-13 13:30:00.0000');
      final t2 = DateTime.tryParse('2026-10-13 13:30:00');
      final t3 = DateTime.tryParse('2026-10-13T13:30:00.000');
      expect(t1, isNotNull);
      expect(t2, isNotNull);
      expect(t3, isNotNull);
      expect(t1!.hour, equals(13));
      expect(t1.minute, equals(30));
    });

    test('ConsumoMesaResumo e Mesa devem exibir tempo do ultimo item quando ha pedido ou fallback', () {
      final agora = DateTime.now();
      final dezMinAtras = agora.subtract(const Duration(minutes: 10));

      final resumo = ConsumoMesaResumo(
        mesaId: 1,
        codigoMesa: '01',
        dataCheckIn: agora.subtract(const Duration(minutes: 30)),
        ultimoPedido: PedidoResumo(
          id: 100,
          empresaId: 1,
          mesaId: 1,
          dataHoraLancamento: dezMinAtras,
          valorTotal: 45.50,
          status: 'F',
        ),
        minutosDesdeUltimoPedido: 10,
        valorUltimoPedido: 45.50,
        valorTotalPedidos: 45.50,
        quantidadePedidos: 1,
      );

      final mesa = Mesa(
        id: 1,
        codigo: '01',
        isOcupada: true,
        consumoResumo: resumo,
      );

      expect(mesa.temConsumo, isTrue);
      expect(mesa.minutosDesdeUltimoPedido, equals(10));
      expect(mesa.valorUltimoPedido, equals(45.50));
      expect(mesa.valorTotalConsumo, equals(45.50));
    });

    test('Tolerancia temporal de 2 minutos deve incluir pedidos lancados no instante do check-in', () {
      final agora = DateTime.now();
      final checkIn = agora;
      final pedidoQuaseSimultaneo = agora.subtract(const Duration(seconds: 30));
      final limite = checkIn.subtract(const Duration(minutes: 2));

      final valido = pedidoQuaseSimultaneo.isAfter(limite) ||
          pedidoQuaseSimultaneo.isAtSameMomentAs(limite);
      expect(valido, isTrue);
    });

    test('AppConfig e ConfigModel devem gerenciar os 3 campos de tempo sem pedidos (Verde, Amarelo e Vermelho)', () {
      const configPadrao = AppConfig();
      expect(configPadrao.tempoVerdeMinutos, equals(30));
      expect(configPadrao.tempoAmareloMinutos, equals(60));
      expect(configPadrao.tempoVermelhoMinutos, equals(90));
      // Compatibilidade legada
      expect(configPadrao.tempoAlertaMinutos, equals(60));
      expect(configPadrao.tempoLimiteMinutos, equals(90));

      final configCustom = configPadrao.copyWith(
        tempoVerdeMinutos: 20,
        tempoAmareloMinutos: 40,
        tempoVermelhoMinutos: 60,
      );
      expect(configCustom.tempoVerdeMinutos, equals(20));
      expect(configCustom.tempoAmareloMinutos, equals(40));
      expect(configCustom.tempoVermelhoMinutos, equals(60));

      final model = ConfigModel.fromEntity(configCustom);
      final json = model.toJson();
      expect(json['tempoVerdeMinutos'], equals(20));
      expect(json['tempoAmareloMinutos'], equals(40));
      expect(json['tempoVermelhoMinutos'], equals(60));

      final recriado = ConfigModel.fromJson(json);
      expect(recriado.tempoVerdeMinutos, equals(20));
      expect(recriado.tempoAmareloMinutos, equals(40));
      expect(recriado.tempoVermelhoMinutos, equals(60));
    });

    test('Paleta de cores deve seguir o semáforo: Normal Verde, Alerta Amarelo/Âmbar, Excedido Vermelho e Livre Slate', () {
      expect(AppTheme.corMesaNormal, equals(const Color(0xFF16A34A))); // Verde
      expect(AppTheme.corMesaAlerta, equals(const Color(0xFFD97706))); // Amarelo/Âmbar
      expect(AppTheme.corMesaExcedida, equals(const Color(0xFFDC2626))); // Vermelho
      expect(AppTheme.corMesaLivre, equals(const Color(0xFF64748B))); // Slate
    });

    test('LanSyncEvento deve serializar e desserializar corretamente para broadcast UDP', () {
      const evento = LanSyncEvento(
        tipo: 'MESA_LIBERADA',
        origemId: 'dev_123',
        mesaId: 5,
        codigoMesa: '005',
        nomeExibicao: 'Mesa 005',
        timestamp: 1728900000000,
      );

      final json = evento.toJson();
      expect(json['tipo'], equals('MESA_LIBERADA'));
      expect(json['origemId'], equals('dev_123'));
      expect(json['mesaId'], equals(5));
      expect(json['codigoMesa'], equals('005'));
      expect(json['nomeExibicao'], equals('Mesa 005'));

      final recriado = LanSyncEvento.fromJson(json);
      expect(recriado.tipo, equals(evento.tipo));
      expect(recriado.origemId, equals(evento.origemId));
      expect(recriado.mesaId, equals(evento.mesaId));
      expect(recriado.codigoMesa, equals(evento.codigoMesa));
      expect(recriado.nomeExibicao, equals(evento.nomeExibicao));
      expect(recriado.timestamp, equals(evento.timestamp));
    });

    test('LanSyncService deve manter deviceId único e instanciar singleton', () {
      final s1 = LanSyncService();
      final s2 = LanSyncService.instancia;
      expect(identical(s1, s2), isTrue);
      expect(s1.deviceId.isNotEmpty, isTrue);
      expect(s1.deviceId.startsWith('dev_'), isTrue);
    });
  });
}



