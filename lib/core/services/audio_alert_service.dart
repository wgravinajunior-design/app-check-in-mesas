import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serviço dedicado para reprodução de sons de notificação de alta intensidade (alerta sonoro alto)
class AudioAlertService {
  static AudioPlayer? _player;

  static AudioPlayer get _instanciaPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Toca um som alto e chamativo para notificar mesa liberada
  static Future<void> tocarSomMesaLiberada() async {
    try {
      // 1. Feedback tátil/vibração imediata
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();

      // 2. Tenta reproduzir o arquivo WAV percussivo de sino/chime em volume máximo
      final player = _instanciaPlayer;
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/mesa_liberada.wav'));

      // 3. Fallback auditivo garantido do sistema caso os drivers de áudio do dispositivo demorem
      SystemSound.play(SystemSoundType.alert);
      Future.delayed(const Duration(milliseconds: 300), () {
        SystemSound.play(SystemSoundType.alert);
      });

      // 4. No Windows, aciona também o beep nativo de sistema via Process se em desktop
      if (!kIsWeb && Platform.isWindows) {
        _tocarBeepNativoWindows();
      }
    } catch (e) {
      debugPrint('Falha ao reproduzir áudio com audioplayers: $e. Usando som do sistema.');
      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Aciona som audível no Windows caso o sistema esteja com áudio de aplicativo atenuado
  static void _tocarBeepNativoWindows() {
    try {
      Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '[System.Media.SystemSounds]::Asterisk.Play(); [Console]::Beep(1200, 200); [Console]::Beep(1600, 350)',
      ]).ignore();
    } catch (_) {}
  }
}
