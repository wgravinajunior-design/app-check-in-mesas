import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';

/// Modal animado com barra de progresso em tempo real que baixa o APK,
/// aciona a instalação automática do Android e encerra o app antigo.
class DownloadUpdateDialog extends StatefulWidget {
  final AtualizacaoInfo info;

  const DownloadUpdateDialog({
    super.key,
    required this.info,
  });

  static Future<void> iniciarAtualizacao(
    BuildContext context,
    AtualizacaoInfo info,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DownloadUpdateDialog(info: info),
    );
  }

  @override
  State<DownloadUpdateDialog> createState() => _DownloadUpdateDialogState();
}

class _DownloadUpdateDialogState extends State<DownloadUpdateDialog> {
  double _progresso = 0.0;
  int _bytesRecebidos = 0;
  int _totalBytes = 0;
  String _statusTexto = 'Conectando ao servidor do CheckMesa...';
  bool _emDownload = true;
  bool _erro = false;
  String? _mensagemErro;
  StreamSubscription<List<int>>? _subscription;
  http.Client? _client;
  IOSink? _fileSink;

  @override
  void initState() {
    super.initState();
    _iniciarDownload();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fileSink?.close();
    _client?.close();
    super.dispose();
  }

  Future<void> _iniciarDownload() async {
    final url = widget.info.urlDownloadApk;
    if (url == null || url.isEmpty) {
      setState(() {
        _erro = true;
        _emDownload = false;
        _mensagemErro = 'URL do arquivo APK não encontrada na release.';
      });
      return;
    }

    try {
      setState(() {
        _statusTexto = 'Iniciando download da atualização...';
        _erro = false;
      });

      _client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'CheckMesa-App/${AppUpdateService.versaoAtualApp}';
      request.headers['Accept'] = 'application/octet-stream';

      final response = await _client!.send(request);

      if (response.statusCode >= 400) {
        throw Exception(
            'Servidor respondeu com código HTTP ${response.statusCode}');
      }

      _totalBytes = response.contentLength ?? 0;

      final tempDir = await getTemporaryDirectory();
      final nomeArquivo = 'CheckMesa-v${widget.info.versaoRemota}.apk';
      final arquivoApk = File('${tempDir.path}/$nomeArquivo');

      if (await arquivoApk.exists()) {
        await arquivoApk.delete();
      }

      _fileSink = arquivoApk.openWrite();

      _subscription = response.stream.listen(
        (chunk) {
          _bytesRecebidos += chunk.length;
          _fileSink?.add(chunk);

          if (mounted) {
            setState(() {
              if (_totalBytes > 0) {
                _progresso = _bytesRecebidos / _totalBytes;
              }
              _statusTexto = 'Baixando arquivo de atualização...';
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _erro = true;
              _emDownload = false;
              _mensagemErro = 'Falha durante o download: $err';
            });
          }
        },
        onDone: () async {
          await _fileSink?.flush();
          await _fileSink?.close();
          _fileSink = null;

          if (mounted) {
            setState(() {
              _progresso = 1.0;
              _emDownload = false;
              _statusTexto = 'Download concluído! Abrindo instalador...';
            });

            await _instalarApkEFechar(arquivoApk.path);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _emDownload = false;
          _mensagemErro = 'Não foi possível baixar o APK: $e';
        });
      }
    }
  }

  Future<void> _instalarApkEFechar(String caminhoApk) async {
    try {
      final resultado = await OpenFilex.open(
        caminhoApk,
        type: 'application/vnd.android.package-archive',
      );

      if (resultado.type == ResultType.done) {
        // Aguarda 1.5s para o instalador nativo do Android assumir a tela e fecha o app antigo
        await Future.delayed(const Duration(milliseconds: 1500));
        SystemNavigator.pop();
      } else {
        // Caso o Android precise de permissão especial de fontes desconhecidas ou retorne erro
        if (mounted) {
          setState(() {
            _erro = true;
            _mensagemErro =
                'Instalador do Android acionado (${resultado.message}). Se o instalador não abriu, instale manualmente pelo arquivo baixado.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _mensagemErro = 'Falha ao iniciar instalador: $e';
        });
      }
    }
  }

  void _abrirNavegadorFallback() async {
    if (widget.info.urlDownloadApk != null) {
      final uri = Uri.parse(widget.info.urlDownloadApk!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mbRecebidos = (_bytesRecebidos / (1024 * 1024)).toStringAsFixed(1);
    final mbTotal = (_totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final porcentagem = (_progresso * 100).toInt();

    return PopScope(
      canPop: !_emDownload,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado/destacado
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _erro
                      ? Colors.red.shade50
                      : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _erro
                      ? Icons.error_outline_rounded
                      : (_progresso >= 1.0
                          ? Icons.check_circle_rounded
                          : Icons.download_rounded),
                  color: _erro
                      ? Colors.red
                      : const Color(0xFF0284C7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _erro
                    ? 'Erro na Atualização'
                    : (_progresso >= 1.0
                        ? 'Atualização Pronta!'
                        : 'Atualizando CheckMesa'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                'Versão v${widget.info.versaoRemota}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              if (!_erro) ...[
                // Barra de progresso linear
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _totalBytes > 0 ? _progresso : null,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.corMesaNormal,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Informação de Porcentagem e MBs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _totalBytes > 0 ? '$porcentagem%' : 'Baixando...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.corMesaNormal,
                      ),
                    ),
                    Text(
                      _totalBytes > 0
                          ? '$mbRecebidos MB de $mbTotal MB'
                          : '$mbRecebidos MB transferidos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  _statusTexto,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _mensagemErro ?? 'Ocorreu um erro inesperado.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_erro) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _abrirNavegadorFallback,
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Baixar no Navegador'),
                    ),
                  ] else if (_emDownload) ...[
                    TextButton(
                      onPressed: () {
                        _subscription?.cancel();
                        _client?.close();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.corMesaNormal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      icon: const Icon(Icons.exit_to_app, size: 16),
                      label: const Text('Fechar App'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
