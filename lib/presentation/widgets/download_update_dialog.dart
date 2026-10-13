import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_theme.dart';

/// Modal animado com barra de progresso em tempo real que baixa o pacote de atualização,
/// aciona a instalação no Android ou extrai os arquivos no Windows.
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
  String? _caminhoArquivoSalvo;
  String? _pastaAbertaWindows;
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
    final url = widget.info.urlDownloadApropriada ??
        widget.info.urlDownloadApk ??
        widget.info.urlReleaseHtml;
    if (url == null || url.isEmpty) {
      setState(() {
        _erro = true;
        _emDownload = false;
        _mensagemErro = 'URL de download da atualização não encontrada na release.';
      });
      return;
    }

    try {
      setState(() {
        _statusTexto = 'Iniciando download da atualização...';
        _erro = false;
        _emDownload = true;
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

      final bool isWindows = !kIsWeb && Platform.isWindows;
      final String extensao = isWindows
          ? (url.toLowerCase().contains('.zip') ? '.zip' : '.exe')
          : '.apk';
      final String prefixo = isWindows
          ? 'CheckMesa-v${widget.info.versaoRemota}-Windows'
          : 'CheckMesa-v${widget.info.versaoRemota}';
      final nomeArquivo = '$prefixo$extensao';

      Directory pastaDestino = await getTemporaryDirectory();
      if (isWindows) {
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            pastaDestino = downloadsDir;
          }
        } catch (_) {}
      }

      final arquivoBaixado = File('${pastaDestino.path}/$nomeArquivo');

      if (await arquivoBaixado.exists()) {
        try {
          await arquivoBaixado.delete();
        } catch (_) {}
      }

      _fileSink = arquivoBaixado.openWrite();

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
              _caminhoArquivoSalvo = arquivoBaixado.path;
              _statusTexto = isWindows
                  ? 'Download concluído! Processando pacote...'
                  : 'Download concluído! Abrindo instalador...';
            });

            if (isWindows) {
              await _instalarWindowsEConcluir(arquivoBaixado.path, extensao == '.zip');
            } else {
              await _instalarApk(arquivoBaixado.path);
            }
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _emDownload = false;
          _mensagemErro = 'Não foi possível baixar a atualização: $e';
        });
      }
    }
  }

  Future<void> _instalarWindowsEConcluir(String caminhoArquivo, bool isZip) async {
    try {
      if (isZip) {
        final arquivo = File(caminhoArquivo);
        final pastaPai = arquivo.parent.path;
        final pastaExtraida = '$pastaPai\\CheckMesa-v${widget.info.versaoRemota}';

        bool extraido = false;
        try {
          final resTar = await Process.run('tar', ['-xf', caminhoArquivo, '-C', pastaPai]);
          if (resTar.exitCode == 0) extraido = true;
        } catch (_) {}

        if (!extraido) {
          try {
            final resPs = await Process.run('powershell', [
              '-NoProfile',
              '-Command',
              'Expand-Archive -Path "$caminhoArquivo" -DestinationPath "$pastaExtraida" -Force'
            ]);
            if (resPs.exitCode == 0) extraido = true;
          } catch (_) {}
        }

        final pastaAbrir = (extraido && await Directory(pastaExtraida).exists())
            ? pastaExtraida
            : pastaPai;
        _pastaAbertaWindows = pastaAbrir;

        await Process.run('explorer.exe', [pastaAbrir]);

        if (mounted) {
          setState(() {
            _statusTexto = extraido
                ? 'Atualização baixada e extraída com sucesso na pasta:\n$pastaExtraida\n\nAbra o novo CheckMesa.exe nesta pasta para usar.'
                : 'Pacote ZIP baixado com sucesso em:\n$caminhoArquivo\n\nA pasta foi aberta. Extraia e execute o novo CheckMesa.exe atualizado.';
          });
        }
      } else {
        final resultado = await OpenFilex.open(caminhoArquivo);
        if (mounted) {
          setState(() {
            _statusTexto = 'Instalador acionado (${resultado.message}).';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusTexto = 'Arquivo salvo em: $caminhoArquivo. Você pode abri-lo manualmente no Explorer.';
        });
      }
    }
  }

  Future<void> _instalarApk(String caminhoApk) async {
    try {
      final resultado = await OpenFilex.open(
        caminhoApk,
        type: 'application/vnd.android.package-archive',
      );

      if (mounted) {
        if (resultado.type == ResultType.done) {
          setState(() {
            _statusTexto =
                'Instalador do Android iniciado!\nConfirme a instalação na tela do aparelho para atualizar o CheckMesa.';
          });
        } else {
          setState(() {
            _statusTexto =
                'Instalador do Android acionado (${resultado.message}). Se a instalação não abrir, use o botão "Abrir Instalador" abaixo ou baixe pelo navegador.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = true;
          _mensagemErro = 'Falha ao iniciar o instalador do Android: $e';
        });
      }
    }
  }

  void _abrirNavegadorFallback() async {
    final url = widget.info.urlDownloadApropriada ?? widget.info.urlReleaseHtml;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
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
    final bool isWindows = !kIsWeb && Platform.isWindows;

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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusTexto,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_erro) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
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
                    // Download concluído com sucesso
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _abrirNavegadorFallback,
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Baixar no Navegador'),
                    ),
                    if (isWindows)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.corMesaNormal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final destino = _pastaAbertaWindows ?? _caminhoArquivoSalvo;
                          if (destino != null) {
                            Process.run('explorer.exe', [destino]);
                          }
                        },
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Abrir Pasta'),
                      )
                    else if (_caminhoArquivoSalvo != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.corMesaNormal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _instalarApk(_caminhoArquivoSalvo!);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reabrir Instalador'),
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
