import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/utils/barcode_parser.dart';

/// Modal para leitura de QR Code ou Código de Barras com a câmera do celular.
/// Retorna o código/identificador da mesa ou comanda extraído.
class CameraScannerDialog extends StatefulWidget {
  final String titulo;
  final String subtitulo;

  const CameraScannerDialog({
    super.key,
    this.titulo = 'Escanear Código',
    this.subtitulo = 'Aponte a câmera para o QR Code ou Código de Barras da Mesa ou Comanda',
  });

  /// Método estático auxiliar para abrir o leitor e retornar o código lido
  static Future<String?> abrirLeitor(
    BuildContext context, {
    String titulo = 'Escanear Mesa / Comanda',
    String subtitulo = 'Aponte a câmera para a identificação da Mesa ou Comanda',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CameraScannerDialog(
        titulo: titulo,
        subtitulo: subtitulo,
      ),
    );
  }

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  late final MobileScannerController _scannerController;
  final TextEditingController _manualInputController = TextEditingController();
  bool _jaDetectou = false;
  bool _mostrarCampoManual = false;
  bool _torchLigado = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _aoDetectarCodigo(BarcodeCapture capture) {
    if (_jaDetectou) return;

    for (final barcode in capture.barcodes) {
      final String? valorBruto = barcode.rawValue ?? barcode.displayValue;
      if (valorBruto != null && valorBruto.trim().isNotEmpty) {
        final String? identificado = BarcodeParser.extrairIdentificador(valorBruto);
        if (identificado != null && identificado.isNotEmpty) {
          setState(() {
            _jaDetectou = true;
          });
          Navigator.of(context).pop(identificado);
          break;
        }
      }
    }
  }

  void _confirmarManual() {
    final texto = _manualInputController.text.trim();
    if (texto.isNotEmpty) {
      final String? identificado = BarcodeParser.extrairIdentificador(texto);
      Navigator.of(context).pop(identificado ?? texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double scanAreaSize = screenSize.width * 0.68;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: screenSize.height * 0.72,
        child: Stack(
          children: [
            // Câmera do MobileScanner
            MobileScanner(
              controller: _scannerController,
              onDetect: _aoDetectarCodigo,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off_rounded, size: 54, color: Colors.orange),
                        const SizedBox(height: 14),
                        const Text(
                          'Acesso à câmera não concedido',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Por favor, conceda permissão de câmera nas configurações do Android.\nDetalhes: ${error.errorDetails?.message ?? error.errorCode.name}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _mostrarCampoManual = true;
                            });
                          },
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text('Digitar Número'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Overlay escurecido ao redor da área de mira
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Cantoneiras decorativas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 4),
                                left: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 4),
                                right: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 4),
                                left: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 4),
                                right: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Barra superior com Título e Botões de Controle
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Alternar lanterna
                    IconButton(
                      icon: Icon(
                        _torchLigado ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _torchLigado ? Colors.amber : Colors.white,
                      ),
                      tooltip: 'Lanterna',
                      onPressed: () async {
                        await _scannerController.toggleTorch();
                        setState(() {
                          _torchLigado = !_torchLigado;
                        });
                      },
                    ),
                    // Alternar câmera frontal/traseira
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                      tooltip: 'Inverter Câmera',
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),

            // Barra inferior com Instrução e Opção Manual
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_mostrarCampoManual) ...[
                      Text(
                        widget.subtitulo,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrarCampoManual = true;
                          });
                        },
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 16, color: Colors.amber),
                        label: const Text(
                          'Digitar número manualmente',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualInputController,
                              keyboardType: TextInputType.text,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ex.: 15 ou 015',
                                hintStyle: const TextStyle(color: Colors.white38),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: Colors.white12,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _confirmarManual(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: _confirmarManual,
                            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
