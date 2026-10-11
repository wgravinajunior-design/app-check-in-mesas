# Aplicativo Flutter para Gestão de Permanência e Rotatividade de Mesas

Aplicativo multiplataforma em Flutter (Android, iOS e Windows Desktop) projetado para restaurantes e pizzarias, focado em monitoramento de tempo de permanência de clientes em mesas, alertas visuais de tolerância e auditoria na tabela de retaguarda **`TB_INGRESSO`**.

---

## 🎯 Arquitetura & Tecnologias
- **Framework:** Flutter 3.47+ / Dart 3.13+
- **Gerenciamento de Estado:** `flutter_bloc` / `Cubit` reativo com `Timer.periodic` de precisão (1 segundo) para atualização dos cronômetros e recálculo dinâmico de faixas.
- **Padrão Arquitetural:** Clean Architecture desacoplada em camadas (`core`, `domain`, `data`, `presentation`).
- **Persistência Local Offline-First:** SQLite com suporte universal via `sqflite` e `sqflite_common_ffi` (Desktop Windows / Mobile).
- **Banco de Retaguarda Legado:** Firebird 2.5 / 3.0 / 4.0 / 5.0 (`DADOS.FDB` / Pizzaria Mansão da Torre).
- **Design System:** Material 3 responsivo com paleta de cores para tomada de decisão imediata dos garçons e gerentes.

---

## 🚦 Regras de Negócio de Permanência e Alertas

| Faixa de Tempo | Cor Visual | Classificação | Ação Recomendada |
| :--- | :--- | :--- | :--- |
| **0 min (Livre)** | 🟢 Verde (`#2E7D32`) | **LIVRE** | Mesa pronta para recepção de novos clientes |
| **Até 1h30m (90 min)** | 🔵 Azul Neutro (`#1565C0`) | **EM ATENDIMENTO** | Consumo normal em andamento |
| **1h30m a 2h00m (90-120 min)** | 🟠 Laranja (`#EF6C00`) | **ALERTA TOLERÂNCIA** | Aproximação para oferta de sobremesa, café ou conta |
| **Mais de 2h00m (> 120 min)** | 🔴 Vermelho (`#C62828`) | **TEMPO EXCEDIDO** | Alerta prioritário para gestão de fila e rotatividade |

> *Nota: Os tempos de tolerância (padrão 90 min) e tempo limite (padrão 120 min) são configuráveis dinamicamente pela interface sem necessidade de recompilação.*

---

## 🗄️ Estrutura de Integração com a Tabela `TB_INGRESSO`

| Coluna | Tipo Firebird | Mapeamento no Aplicativo | Descrição de Negócio |
| :--- | :--- | :--- | :--- |
| `ING_EMPRESA` | `INTEGER` | `empresaId` | Identificador da empresa no ERP (ex.: 1) |
| `ING_ID` | `INTEGER` | `id` | Sequencial único do atendimento / ingresso |
| `ING_STATUS` | `VARCHAR(1)` | `status` | `'A'` = Em atendimento / Aberto; `'F'` = Finalizado / Check-out |
| `ING_CODIGO` | `VARCHAR(200)` | `codigoMesa` | Número identificador da mesa (ex.: `'001'`, `'005'`) |
| `ING_DT_ENTRADA`| `TIMESTAMP` | `dtEntrada` | Timestamp exato do Check-in do cliente |
| `ING_DT_SAIDA` | `TIMESTAMP` | `dtSaida` | Timestamp exato do Check-out / Liberação da mesa |
| `ING_DURACAO` | `INTEGER` | `duracaoMinutos` | Minutos totais de permanência calculados na saída |
| `ING_OBSERVACAO`| `VARCHAR(2000)`| `observacao` | Registro de histórico, garçom ou detalhes da permanência |
| `ING_VALOR` | `NUMERIC(15,2)`| `valor` | Valor base (0.00 padrão para controle de mesa) |
| `ING_CAIXA` | `INTEGER` | `caixaId` | Identificador do caixa / operador |

---

## 📁 Estrutura de Pastas

```
lib/
├── core/
│   ├── constants/app_constants.dart          # Parâmetros e chaves do sistema
│   ├── database/local_database.dart           # SQLite com suporte multiplataforma FFI
│   ├── theme/app_theme.dart                   # Tema Material 3 e paleta de cores
│   └── utils/time_formatter.dart              # Formatação de cronômetro (HH:mm:ss) e datas
├── data/
│   ├── datasources/
│   │   ├── ingresso_local_datasource.dart     # Consultas e inserções SQL na TB_INGRESSO
│   │   ├── mesa_local_datasource.dart         # Gestão de registros na TB_MESA
│   │   └── retaguarda_sync_datasource.dart    # Geração de SQL Firebird e sync REST
│   ├── models/
│   │   ├── config_model.dart                  # Serialização de configurações
│   │   ├── ingresso_model.dart                # Mapeamento das 25 colunas de TB_INGRESSO
│   │   └── mesa_model.dart                    # Mapeamento de TB_MESA
│   └── repositories/
│       ├── config_repository_impl.dart        # Persistência com SharedPreferences
│       ├── ingresso_repository_impl.dart      # Repositório de histórico e auditoria
│       └── mesa_repository_impl.dart          # Repositório de estado das mesas
├── domain/
│   ├── entities/
│   │   ├── app_config.dart                    # Parâmetros de tempo e limites
│   │   ├── ingresso.dart                      # Entidade pura de negócio TB_INGRESSO
│   │   ├── mesa.dart                          # Entidade de Mesa com cronômetro
│   │   └── status_permanencia.dart            # Enum com cores e regras visuais
│   └── repositories/
│       ├── config_repository.dart             # Contrato de configuração
│       ├── ingresso_repository.dart           # Contrato de auditoria e persistência
│       └── mesa_repository.dart               # Contrato de dados de mesas
├── presentation/
│   ├── cubits/
│   │   ├── config/config_cubit.dart           # Estado das configurações
│   │   └── mesa/mesa_cubit.dart               # Reatividade a cada segundo (Timer)
│   ├── screens/
│   │   ├── historico_ingressos_screen.dart    # Tela de auditoria de registros
│   │   └── mesa_grid_screen.dart              # Grid responsivo de mesas com filtros
│   └── widgets/
│       ├── check_in_dialog.dart               # Modal de confirmação de ocupação
│       ├── check_out_dialog.dart              # Modal com resumo e liberação
│       ├── config_dialog.dart                 # Configuração de limites e tempos
│       ├── mesa_card_widget.dart              # Card com cronômetro em tempo real
│       └── stats_summary_widget.dart          # Filtros rápidos e totais por status
└── main.dart                                  # Injeção de dependências e inicialização
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter SDK 3.47+ instalado
- Extensão Dart habilitada

### Execução no Windows Desktop
```powershell
flutter run -d windows
```

### Execução no Dispositivo Android / Emulador
```powershell
flutter run -d android
```

### Execução dos Testes Automatizados
```powershell
flutter test
```

### Análise Estática de Código
```powershell
flutter analyze
```
