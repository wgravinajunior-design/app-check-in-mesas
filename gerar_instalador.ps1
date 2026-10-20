param (
    [switch]$ForceRebuild
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

# 1. Identificar versao no pubspec.yaml
$pubspecPath = Join-Path $root "pubspec.yaml"
$versionLine = Get-Content $pubspecPath | Where-Object { $_ -match "^version:\s*([0-9]+\.[0-9]+\.[0-9]+)" } | Select-Object -First 1
if ($versionLine -match "([0-9]+\.[0-9]+\.[0-9]+)") {
    $version = $matches[1]
} else {
    $version = "1.0.20"
}
$tag = "v$version"
Write-Host "=== Gerador do Instalador Padrao CheckMesa ($tag) ===" -ForegroundColor Cyan

# 2. Diretorios de saida
$installDir = Join-Path $root "instalador"
$winInstallDir = Join-Path $installDir "Windows"
$androidInstallDir = Join-Path $installDir "Android"

New-Item -ItemType Directory -Force -Path $winInstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $androidInstallDir | Out-Null

# 3. Verificar/Compilar versao Windows
$winReleaseDir = Join-Path $root "build\windows\x64\runner\Release"
$winExe = Join-Path $winReleaseDir "CheckMesa.exe"

if ($ForceRebuild -or (-not (Test-Path $winExe))) {
    Write-Host "-> Compilando Windows Desktop Release..." -ForegroundColor Yellow
    Push-Location $root
    flutter build windows --release
    Pop-Location
}

if (-not (Test-Path $winExe)) {
    throw "Executavel Windows nao encontrado em $winExe apos build."
}

Write-Host "-> Copiando executavel e TODAS as DLLs/dependencias para instalador\Windows..." -ForegroundColor Green
Copy-Item -Path "$winReleaseDir\*" -Destination $winInstallDir -Recurse -Force

# 4. Criar pacotes ZIP do Windows
$distReleaseDir = Join-Path $root "build\dist_release"
New-Item -ItemType Directory -Force -Path $distReleaseDir | Out-Null

$zipVersioned = Join-Path $installDir "CheckMesa-$tag-Windows.zip"
$zipGeneric = Join-Path $installDir "CheckMesa-Windows.zip"

Write-Host "-> Gerando arquivos compactados .ZIP do Windows..." -ForegroundColor Green
Compress-Archive -Path "$winReleaseDir\*" -DestinationPath $zipVersioned -Force
Copy-Item -Path $zipVersioned -Destination $zipGeneric -Force
Copy-Item -Path $zipVersioned -Destination (Join-Path $distReleaseDir "CheckMesa-$tag-Windows.zip") -Force
Copy-Item -Path $zipGeneric -Destination (Join-Path $distReleaseDir "CheckMesa-Windows.zip") -Force
Copy-Item -Path $winExe -Destination (Join-Path $distReleaseDir "CheckMesa.exe") -Force

# 5. Obter APK do Android
$apkLocalPath = Join-Path $root "build\app\outputs\flutter-apk\CheckMesa-$tag.apk"
if (-not (Test-Path $apkLocalPath)) {
    Write-Host "-> Buscando APK do release no GitHub ($tag)..." -ForegroundColor Yellow
    try {
        gh release download $tag -p "CheckMesa-$tag.apk" -D (Join-Path $root "build\app\outputs\flutter-apk") --clobber
    } catch {
        Write-Host "Nao foi possivel baixar pelo gh cli. Verificando app-release.apk local..." -ForegroundColor Yellow
    }
}

if (-not (Test-Path $apkLocalPath)) {
    $fallbackApk = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $fallbackApk) {
        Copy-Item -Path $fallbackApk -Destination $apkLocalPath -Force
    } else {
        Write-Host "-> Compilando APK localmente..." -ForegroundColor Yellow
        Push-Location $root
        flutter build apk --release
        Pop-Location
        Copy-Item -Path $fallbackApk -Destination $apkLocalPath -Force
    }
}

Write-Host "-> Copiando APK para instalador\Android e raiz do instalador..." -ForegroundColor Green
Copy-Item -Path $apkLocalPath -Destination (Join-Path $androidInstallDir "CheckMesa-$tag.apk") -Force
Copy-Item -Path $apkLocalPath -Destination (Join-Path $androidInstallDir "CheckMesa.apk") -Force
Copy-Item -Path $apkLocalPath -Destination (Join-Path $installDir "CheckMesa-$tag.apk") -Force
Copy-Item -Path $apkLocalPath -Destination (Join-Path $installDir "CheckMesa.apk") -Force

# 6. Gerar LEIA-ME explicativo
$readmeContent = @"
========================================================================
CHECKMESA - PACOTE DE INSTALACAO MULTIPLATAFORMA ($tag)
========================================================================

Este diretorio contem os binarios oficiais prontos para uso e distribuicao.

1. ANDROID (Celulares e Tablets)
------------------------------------------------------------------------
- Arquivos:
  * CheckMesa-$tag.apk
  * CheckMesa.apk (copia com nome fixo)
  * Pasta 'Android/' com as copias adicionais.
- Como instalar:
  Envie o arquivo .apk para o smartphone ou tablet via WhatsApp, Google Drive
  ou cabo USB, abra o arquivo no aparelho e confirme a instalacao.

2. WINDOWS DESKTOP (Computadores e Terminais)
------------------------------------------------------------------------
- Pasta 'Windows/':
  Contem o executavel 'CheckMesa.exe' acompanhado de TODAS as DLLs necessarias
  (Flutter Engine, driver nativo Firebird fbclient.dll, SQLite3, runtimes C++
  MSVCP140/VCRUNTIME140, plugins de som e navegacao, pasta data e plugins).
  * Como usar: Basta abrir a pasta 'Windows/' e dar dois cliques em 'CheckMesa.exe'.
  * Para enviar para outro PC: Envie o arquivo compactado 'CheckMesa-$tag-Windows.zip'
    ou 'CheckMesa-Windows.zip', descompacte em qualquer pasta e execute 'CheckMesa.exe'.

========================================================================
Atualizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
========================================================================
"@

Set-Content -Path (Join-Path $installDir "LEIA-ME.txt") -Value $readmeContent -Encoding UTF8

Write-Host "`n=== Concluido com Sucesso! ===" -ForegroundColor Cyan
Write-Host "Pasta do Instalador: $installDir" -ForegroundColor Green
Get-ChildItem -Path $installDir
