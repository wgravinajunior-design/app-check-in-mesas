@echo off
title Servidor Bridge Firebird 5.0 - Gestao de Mesas
color 0A
echo ================================================================
echo    INICIANDO SERVIDOR BRIDGE FIREBIRD 5.0 (PORTA 8082)
echo    Permite que celulares Android acessem a base DADOS.FDB
echo ================================================================
echo.
echo IP da sua maquina na rede Wi-Fi: 192.168.0.109
echo Porta: 8082
echo.
node server_firebird.js
pause
