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
    // No Windows, usa o executor nativo do Windows que nunca derruba o processo C++
    if (!kIsWeb && Platform.isWindows) {
      _tocarAlertaWindows();
      return;
    }

    try {
      // 1. Feedback tátil/vibração imediata no mobile
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
    } catch (e) {
      debugPrint('Falha ao reproduzir áudio com audioplayers: $e. Usando som do sistema.');
      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Executa o som de alerta no Windows sem depender do audioplayers (evita falha nativa no C++)
  static void _tocarAlertaWindows() {
    try {
      // Feedback sonoro imediato de sistema Flutter (Win32 MessageBeep)
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    try {
      String? caminhoWav;
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final bundleWav = File('$exeDir\\data\\flutter_assets\\assets\\sounds\\mesa_liberada.wav');
      if (bundleWav.existsSync()) {
        caminhoWav = bundleWav.path;
      } else {
        final devWav = File('${Directory.current.path}\\assets\\sounds\\mesa_liberada.wav');
        if (devWav.existsSync()) {
          caminhoWav = devWav.path;
        }
      }

      if (caminhoWav != null) {
        Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '''
          try {
            \$p = New-Object System.Media.SoundPlayer '$caminhoWav'
            \$p.PlaySync()
          } catch {
            [System.Media.SystemSounds]::Asterisk.Play()
          }
          '''
        ]).ignore();
      } else {
        _tocarBeepNativoWindows();
      }
    } catch (e) {
      debugPrint('Erro ao reproduzir som no Windows: $e');
      _tocarBeepNativoWindows();
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
