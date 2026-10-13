import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../presentation/widgets/download_update_dialog.dart';
import '../theme/app_theme.dart';

class AtualizacaoInfo {
  final bool temAtualizacao;
  final String versaoAtual;
  final String versaoRemota;
  final String tituloRelease;
  final String notasMelhorias;
  final String? urlDownloadApk;
  final String? urlDownloadWindows;
  final String? urlReleaseHtml;
  final bool erroConexao;
  final String? mensagemErro;

  const AtualizacaoInfo({
    required this.temAtualizacao,
    required this.versaoAtual,
    required this.versaoRemota,
    required this.tituloRelease,
    required this.notasMelhorias,
    this.urlDownloadApk,
    this.urlDownloadWindows,
    this.urlReleaseHtml,
    this.erroConexao = false,
    this.mensagemErro,
  });

  /// URL de download apropriada de acordo com a plataforma em execução
  String? get urlDownloadApropriada {
    if (!kIsWeb && Platform.isWindows) {
      return urlDownloadWindows ?? urlDownloadApk ?? urlReleaseHtml;
    }
    return urlDownloadApk ?? urlReleaseHtml;
  }
}

class AppUpdateService {
  static const String repositorioOwner = 'wgravinajunior-design';
  static const String repositorioNome = 'app-check-in-mesas';
  static const String versaoAtualApp = '1.0.14';

  static Future<AtualizacaoInfo> verificarAtualizacao() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$repositorioOwner/$repositorioNome/releases/latest?t=${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'CheckMesa-App/$versaoAtualApp',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String rawTag = data['tag_name'] as String? ?? '';
        final String tagName = rawTag.replaceAll(RegExp(r'[^0-9.]'), '').trim();
        final String titulo = data['name'] as String? ?? 'Atualização Disponível';
        final String body = data['body'] as String? ?? 'Melhorias de desempenho e correções gerais.';
        final String htmlUrl = data['html_url'] as String? ?? '';

        String? downloadApk;
        String? downloadWindows;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final String nomeArquivo = (asset['name'] as String? ?? '').toLowerCase();
            final String? downloadUrl = asset['browser_download_url'] as String?;
            if (nomeArquivo.endsWith('.apk')) {
              downloadApk = downloadUrl;
            } else if (nomeArquivo.contains('windows') || nomeArquivo.endsWith('.zip') || nomeArquivo.endsWith('.exe')) {
              downloadWindows = downloadUrl;
            }
          }
        }

        final bool precisaAtualizar = _compararVersoes(tagName, versaoAtualApp);

        return AtualizacaoInfo(
          temAtualizacao: precisaAtualizar,
          versaoAtual: versaoAtualApp,
          versaoRemota: tagName.isNotEmpty ? tagName : rawTag,
          tituloRelease: titulo,
          notasMelhorias: body,
          urlDownloadApk: downloadApk ?? htmlUrl,
          urlDownloadWindows: downloadWindows,
          urlReleaseHtml: htmlUrl,
        );
      } else {
        return AtualizacaoInfo(
          temAtualizacao: false,
          versaoAtual: versaoAtualApp,
          versaoRemota: versaoAtualApp,
          tituloRelease: '',
          notasMelhorias: '',
          erroConexao: true,
          mensagemErro: 'Resposta do servidor GitHub: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      String msgAmigavel = 'Falha ao conectar com o servidor de atualizações.';
      final strErro = e.toString();
      if (strErro.contains('SocketException') ||
          strErro.contains('Failed host lookup') ||
          strErro.contains('errno = 7')) {
        msgAmigavel = 'Sem conexão com a internet ou servidor inacessível. Verifique sua rede.';
      } else if (strErro.contains('TimeoutException')) {
        msgAmigavel = 'Tempo limite de resposta excedido ao consultar atualizações.';
      }

      return AtualizacaoInfo(
        temAtualizacao: false,
        versaoAtual: versaoAtualApp,
        versaoRemota: versaoAtualApp,
        tituloRelease: '',
        notasMelhorias: '',
        erroConexao: true,
        mensagemErro: msgAmigavel,
      );
    }
  }

  /// Retorna true se a versão remota for maior que a local
  static bool _compararVersoes(String remota, String local) {
    if (remota.isEmpty) return false;
    final remotaLimpa = remota.replaceAll(RegExp(r'[^0-9.]'), '');
    final localLimpa = local.replaceAll(RegExp(r'[^0-9.]'), '');

    final partesRemota = remotaLimpa.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partesLocal = localLimpa.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final int numRemoto = i < partesRemota.length ? partesRemota[i] : 0;
      final int numLocal = i < partesLocal.length ? partesLocal[i] : 0;

      if (numRemoto > numLocal) return true;
      if (numRemoto < numLocal) return false;
    }
    return false;
  }


  /// Exibe diálogo modal com as notas de melhoria e botão para download do APK
  static void exibirDialogAtualizacao(BuildContext context, AtualizacaoInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.corMesaNormalClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.system_update_rounded, color: AppTheme.corMesaNormal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nova Versão Disponível!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    'v${info.versaoRemota} (Sua versão: v${info.versaoAtual})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O que há de novo nesta versão:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  info.notasMelhorias.isNotEmpty
                      ? info.notasMelhorias
                      : 'Melhorias de desempenho, estabilidade e atualização do sistema.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ao tocar em "Atualizar Automaticamente", o download do novo APK será exibido com barra de progresso e a instalação iniciará na tela.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mais Tarde'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.corMesaNormal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.system_update_rounded, size: 18),
            label: const Text('Atualizar Automaticamente'),
            onPressed: () {
              Navigator.of(ctx).pop();
              DownloadUpdateDialog.iniciarAtualizacao(context, info);
            },
          ),
        ],
      ),
    );
  }
}
