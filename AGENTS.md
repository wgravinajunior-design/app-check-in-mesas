# Regras e Diretrizes do Projeto CheckMesa

## 📌 Regra Obrigatória de Build e Release Multiplataforma

> **REGRA DE OURO:** Sempre que gerar um APK (Android), deve-se obrigatoriamente gerar também a versão Windows Desktop (`CheckMesa.exe` / `CheckMesa-Windows.zip`).

### Requisitos Contínuos:
1. **Mesma Release e Build:** O número de versão e código de build (`version` no `pubspec.yaml`, `versaoAtualApp` no `AppUpdateService.dart`, git tag e título da release no GitHub) devem ser rigorosamente idênticos para as duas plataformas.
2. **Publicação no GitHub:** Toda release no GitHub deve conter tanto os binários Android (`CheckMesa-vX.X.X.apk` / `app-release.apk`) quanto os binários Windows (`CheckMesa-vX.X.X-Windows.zip` / `CheckMesa.exe`).
3. **Atualização Automática:** O aplicativo deve oferecer suporte à verificação e download automático tanto no Android (instalando o pacote `.apk`) quanto no Windows (baixando e abrindo o pacote `.zip` / `.exe`).
4. **CI/CD no GitHub Actions:** O workflow `.github/workflows/build_and_release.yml` deve compilar em paralelo os jobs `build-apk` (Android) e `build-windows` (Windows Desktop), publicando ambos na release.

## 📋 Regras de Negócio do Módulo de Pedidos (Modelo Pré-pago)
- **Modelo pré-pago:** Não considerar status de pedido em aberto nem abertura formal de mesa; cada pedido é pago no ato.
- **Filtro temporal:** Considerar apenas os pedidos feitos após o momento do check-in da mesa informada.
- **Último pedido:** Ordenar pela data/hora de forma decrescente para capturar a transação mais recente.
- **Tempo decorrido:** Calcular a diferença em minutos entre a data/hora do último pedido e a data/hora atual (há quantos minutos o cliente pediu pela última vez).
- **Valores:** Exibir o valor do último pedido e o somatório total de todos os pedidos realizados nessa mesa desde o check-in.
