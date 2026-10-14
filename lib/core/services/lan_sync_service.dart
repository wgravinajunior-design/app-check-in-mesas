import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Modelo de evento distribuído via UDP na rede local (Wi-Fi/Ethernet)
class LanSyncEvento {
  final String tipo;
  final String origemId;
  final int? mesaId;
  final String codigoMesa;
  final String nomeExibicao;
  final int timestamp;

  const LanSyncEvento({
    required this.tipo,
    required this.origemId,
    this.mesaId,
    required this.codigoMesa,
    required this.nomeExibicao,
    required this.timestamp,
  });

  factory LanSyncEvento.fromJson(Map<String, dynamic> json) {
    return LanSyncEvento(
      tipo: json['tipo']?.toString() ?? '',
      origemId: json['origemId']?.toString() ?? '',
      mesaId: json['mesaId'] is int
          ? json['mesaId'] as int
          : int.tryParse(json['mesaId']?.toString() ?? ''),
      codigoMesa: json['codigoMesa']?.toString() ?? '',
      nomeExibicao: json['nomeExibicao']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : (int.tryParse(json['timestamp']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'origemId': origemId,
        'mesaId': mesaId,
        'codigoMesa': codigoMesa,
        'nomeExibicao': nomeExibicao,
        'timestamp': timestamp,
      };
}

/// Serviço de sincronização em tempo real peer-to-peer na rede local (LAN UDP Broadcast)
/// Permite que múltiplos celulares e computadores na mesma rede Wi-Fi se comuniquem
/// instantaneamente (< 50ms) sem depender de servidores em nuvem.
class LanSyncService {
  static final LanSyncService _instancia = LanSyncService._interno();
  factory LanSyncService() => _instancia;
  static LanSyncService get instancia => _instancia;

  LanSyncService._interno() {
    _deviceId =
        'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  static const int portaPadrao = 45454;

  late final String _deviceId;
  String get deviceId => _deviceId;

  RawDatagramSocket? _socket;
  StreamSubscription? _socketSub;
  bool _iniciado = false;

  final StreamController<LanSyncEvento> _eventoController =
      StreamController<LanSyncEvento>.broadcast();
  Stream<LanSyncEvento> get eventoStream => _eventoController.stream;

  /// Stream filtrado para eventos de mesa liberada
  Stream<LanSyncEvento> get mesaLiberadaStream =>
      _eventoController.stream.where((e) => e.tipo == 'MESA_LIBERADA');

  /// Cache para deduplicação de mensagens recebidas
  final Map<String, DateTime> _mensagensProcessadas = {};

  /// Inicializa o socket UDP para escutar eventos na rede local
  Future<void> iniciar() async {
    if (_iniciado && _socket != null) return;
    _iniciado = true;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        portaPadrao,
        reuseAddress: true,
        reusePort: false, // Windows não suporta SO_REUSEPORT, deve ser false
      );
      _socket?.broadcastEnabled = true;

      _socketSub?.cancel();
      _socketSub = _socket?.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              _processarDatagram(datagram);
            }
          }
        },
        onError: (err) {
          debugPrint('LanSyncService: erro no socket UDP: $err');
        },
      );
      debugPrint(
          'LanSyncService inicializado com sucesso na porta $portaPadrao (Device: $_deviceId)');
    } catch (e) {
      debugPrint('LanSyncService: aviso ao vincular porta $portaPadrao: $e');
    }
  }

  void _processarDatagram(Datagram datagram) {
    try {
      final str = utf8.decode(datagram.data);
      final json = jsonDecode(str) as Map<String, dynamic>;
      final evento = LanSyncEvento.fromJson(json);

      // Ignora mensagens originadas por este mesmo aparelho
      if (evento.origemId == _deviceId) {
        return;
      }

      // Deduplicação: ignora repetições do mesmo evento em menos de 15 segundos
      final agora = DateTime.now();
      final chave =
          '${evento.tipo}_${evento.mesaId}_${evento.codigoMesa}_${evento.timestamp}';

      _limparMensagensAntigas(agora);

      if (_mensagensProcessadas.containsKey(chave)) {
        return;
      }
      _mensagensProcessadas[chave] = agora;

      debugPrint(
          'LanSyncService: evento recebido de outro dispositivo: ${evento.tipo} - ${evento.nomeExibicao}');
      if (!_eventoController.isClosed) {
        _eventoController.add(evento);
      }
    } catch (e) {
      debugPrint('LanSyncService: falha ao decodificar datagrama: $e');
    }
  }

  void _limparMensagensAntigas(DateTime agora) {
    _mensagensProcessadas.removeWhere(
      (_, hora) => agora.difference(hora).inSeconds > 15,
    );
  }

  /// Notifica todos os aparelhos na rede local que a mesa foi liberada (Check-Out)
  Future<void> broadcastMesaLiberada({
    required int? mesaId,
    required String codigoMesa,
    required String nomeExibicao,
  }) async {
    final evento = LanSyncEvento(
      tipo: 'MESA_LIBERADA',
      origemId: _deviceId,
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      nomeExibicao: nomeExibicao,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _enviarBroadcast(evento);
  }

  /// Notifica todos os aparelhos na rede local que a mesa foi ocupada (Check-In)
  Future<void> broadcastMesaOcupada({
    required int? mesaId,
    required String codigoMesa,
    required String nomeExibicao,
  }) async {
    final evento = LanSyncEvento(
      tipo: 'MESA_OCUPADA',
      origemId: _deviceId,
      mesaId: mesaId,
      codigoMesa: codigoMesa,
      nomeExibicao: nomeExibicao,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _enviarBroadcast(evento);
  }

  Future<void> _enviarBroadcast(LanSyncEvento evento) async {
    try {
      if (_socket == null) {
        await iniciar();
      }
      if (_socket == null) return;

      final data = utf8.encode(jsonEncode(evento.toJson()));

      // 1. Envio para o broadcast geral da rede (255.255.255.255)
      try {
        _socket?.send(data, InternetAddress('255.255.255.255'), portaPadrao);
      } catch (_) {}

      // 2. Envio direcionado para as sub-redes ativas (ex: 192.168.1.255)
      try {
        final interfaces =
            await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnetBroadcast =
                  '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                _socket?.send(
                    data, InternetAddress(subnetBroadcast), portaPadrao);
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // 3. Redundância anti-perda UDP (envia uma segunda vez após 70ms)
      await Future.delayed(const Duration(milliseconds: 70));
      try {
        _socket?.send(data, InternetAddress('255.255.255.255'), portaPadrao);
      } catch (_) {}
    } catch (e) {
      debugPrint('LanSyncService: erro ao emitir broadcast: $e');
    }
  }

  void dispose() {
    _socketSub?.cancel();
    _socket?.close();
    _socket = null;
    _iniciado = false;
  }
}
