# Diretriz de Geração de Builds Multiplataforma

Sempre que gerar APK para Android, obrigatoriamente gere também a versão Windows Desktop executável (`CheckMesa.exe` / `CheckMesa-Windows.zip`).

1. Manter a mesma release (ex: `v1.0.11`) e build (ex: `1.0.11+12`) para Android e Windows.
2. Atualizar `pubspec.yaml`, `windows/runner/Runner.rc` e `AppUpdateService.dart`.
3. Anexar ambos os artefatos na GitHub Release.
4. Manter a lógica de atualização automática compatível com ambas as plataformas.
