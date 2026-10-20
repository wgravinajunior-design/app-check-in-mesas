@echo off
chcp 65001 > nul
echo ========================================================
echo Gerando Pasta Instalador CheckMesa Multiplataforma...
echo ========================================================

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gerar_instalador.ps1"

echo.
pause
