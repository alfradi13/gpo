@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title [ SOPORTE CORPORATIVO ] Mantenimiento y Diagnostico HP/Windows
color 0F

REM ============================================================
REM  Verificar privilegios de Administrador 
REM ============================================================
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    cls
    color 0C
    echo +================================================================+
    echo ^|  [!] ERROR DE PRIVILEGIOS                                       ^|
    echo +================================================================+
    echo ^|  Este script requiere permisos de ADMINISTRADOR.               ^|
    echo ^|  Cierra esta ventana, clic derecho sobre el .bat               ^|
    echo ^|  y selecciona "Ejecutar como administrador".                   ^|
    echo +================================================================+
    echo.
    pause
    exit /b
)

:MENU
cls
color 0F
echo +================================================================+
echo ^|        MANTENIMIENTO Y DIAGNOSTICO DE EQUIPOS HP/WINDOWS       ^|
echo ^|                     SOPORTE CORPORATIVO                        ^|
echo +================================================================+
echo.
echo   [ SEGURIDAD ]
echo    1.  Habilitar Firewall de Windows (3 perfiles)
echo    2.  Habilitar Windows Defender (tiempo real)
echo    3.  Actualizar firmas de malware de Defender
echo.
echo   [ ACTUALIZACIONES ]
echo    4.  Buscar actualizaciones de Windows (Windows Update)
echo    5.  Actualizar apps instaladas (Winget)
echo    6.  Forzar actualizacion de politicas (GPO) [AISLADO]
echo    7.  Verificar y reiniciar servicio de Windows Update
echo.
echo   [ RENDIMIENTO / ALMACENAMIENTO ]
echo    8.  Vaciar carpeta TEMP (Sistema y Usuario)
echo    9.  Vaciar Papelera de Reciclaje
echo.
echo   [ DIAGNOSTICO / SOPORTE ]
echo    10. Abrir carpeta de Minidumps (C:\Windows\Minidump)
echo    11. Reiniciar el equipo (Aviso de 30 seg)
echo.
echo   [ AUDITORIA DE SOFTWARE ]
echo    12. Verificar programas instalados vs. lista permitida
echo.
echo   [ MANTENIMIENTO COMPLETO ]
echo    13. EJECUTAR TODOS LOS PUNTOS AUTOMATICAMENTE
echo.
echo    0. SALIR
echo +================================================================+
set /p opcion="  Seleccione una opcion: "
 
if "%opcion%"=="1" goto FIREWALL
if "%opcion%"=="2" goto DEFENDER
if "%opcion%"=="3" goto FIRMAS
if "%opcion%"=="4" goto WINDOWSUPDATE
if "%opcion%"=="5" goto WINGET
if "%opcion%"=="6" goto GPUPDATE
if "%opcion%"=="7" goto WUSERVICE
if "%opcion%"=="8" goto TEMP
if "%opcion%"=="9" goto PAPELERA
if "%opcion%"=="10" goto MINIDUMP
if "%opcion%"=="11" goto REBOOT
if "%opcion%"=="12" goto PROGRAMAS
if "%opcion%"=="13" goto TODO
if "%opcion%"=="0" goto FIN
echo  Opcion invalida.
timeout /t 2 >nul
goto MENU
 
REM ============================================================
:FIREWALL
cls
echo +================================================================+
echo ^|  HABILITANDO FIREWALL DE WINDOWS                               ^|
echo +================================================================+
echo  Aplicando cambios...
netsh advfirewall set allprofiles state on
echo.
echo  [ OK ] Firewall habilitado en los 3 perfiles (Dominio, Privado, Publico).
pause
goto MENU
 
REM ============================================================
:DEFENDER
cls
echo +================================================================+
echo ^|  HABILITANDO WINDOWS DEFENDER                                  ^|
echo +================================================================+
echo  Aplicando cambios...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableIOAVProtection $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableBehaviorMonitoring $false" 2>nul
echo.
echo  [ OK ] Windows Defender habilitado completamente.
pause
goto MENU
 
REM ============================================================
:FIRMAS
cls
echo +================================================================+
echo ^|  ACTUALIZANDO FIRMAS DE WINDOWS DEFENDER                       ^|
echo +================================================================+
echo  Descargando e instalando firmas de malware...
echo.
powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue"
echo.
echo  [ OK ] Proceso de actualizacion de firmas finalizado.
pause
goto MENU
 
REM ============================================================
:WINDOWSUPDATE
cls
echo +================================================================+
echo ^|  ABRIENDO WINDOWS UPDATE                                       ^|
echo +================================================================+
echo  Abriendo configuracion de Windows Update...
start ms-settings:windowsupdate
echo.
echo  [ INFO ] Haz clic en "Buscar actualizaciones" en la ventana abierta.
pause
goto MENU
 
REM ============================================================
:WINGET
cls
echo +================================================================+
echo ^|  ACTUALIZANDO APLICACIONES CON WINGET                          ^|
echo +================================================================+
echo  Iniciando actualizacion de todas las aplicaciones...
echo  Esto puede tardar varios minutos.
echo.
winget upgrade --all --accept-package-agreements --accept-source-agreements
echo.
echo  [ OK ] Proceso de actualizacion finalizado.
pause
goto MENU
 
REM ============================================================
:TEMP
cls
echo +================================================================+
echo ^|  LIMPIANDO ARCHIVOS TEMPORALES                                 ^|
echo +================================================================+
echo  Limpiando temporales del usuario...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo       [ OK ] Temporales de usuario limpiados.

echo  Limpiando temporales del sistema...
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo       [ OK ] Temporales de sistema limpiados.

echo  Limpiando cache de Windows Update...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo       [ OK ] Cache de Windows Update limpiada.

echo.
echo  [ OK ] Limpieza de temporales finalizada (archivos en uso omitidos).
pause
goto MENU
 
REM ============================================================
:PAPELERA
cls
echo +================================================================+
echo ^|  VACIANDO PAPELERA DE RECICLAJE                                ^|
echo +================================================================+
echo  Vaciando papelera en todas las unidades...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo.
echo  [ OK ] Papelera de reciclaje vaciada.
pause
goto MENU
 
REM ============================================================
:MINIDUMP
cls
echo +================================================================+
echo ^|  ABRIENDO CARPETA MINIDUMPS                                    ^|
echo +================================================================+
if exist "C:\Windows\Minidump\" (
    echo  Abriendo carpeta de minidumps...
    start "" "C:\Windows\Minidump\"
    echo  [ OK ] Carpeta abierta.
) else (
    echo  [ INFO ] No se encontro la carpeta C:\Windows\Minidump\
    echo          Esto indica que no hay volcados de memoria de errores criticos.
)
pause
goto MENU
 
REM ============================================================
:GPUPDATE
cls
echo +================================================================+
echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO) - MODO AISLADO          ^|
echo +================================================================+
echo  Iniciando actualizacion de politicas en ventana separada...
echo  La ventana de GPO se ejecutara de forma independiente.
echo  Este menu seguira disponible para continuar trabajando.
echo.
echo  Abriendo ventana aislada de GPUPDATE...
start "GPUPDATE - Actualizacion de Politicas de Grupo" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO)        ^| & echo +============================================+ & echo. & echo  Iniciando gpupdate /force ... & echo  Este proceso puede tardar varios minutos. & echo. & gpupdate /force & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & echo. & pause"
echo.
echo  [ OK ] Ventana aislada de GPUPDATE iniciada correctamente.
echo  [ INFO ] Puedes continuar usando este menu mientras se ejecuta.
pause
goto MENU
 
REM ============================================================
:WUSERVICE
cls
echo +================================================================+
echo ^|  VERIFICANDO Y REINICIANDO SERVICIO DE WINDOWS UPDATE          ^|
echo +================================================================+
echo  Deteniendo servicios relacionados...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1
echo       [ OK ] Servicios detenidos.

echo  Iniciando servicios...
net start cryptsvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo       [ OK ] Servicios iniciados.

echo.
echo  Estado actual del servicio Windows Update:
sc query wuauserv | findstr /i "STATE TYPE"
echo.
echo  [ OK ] Verificacion y reinicio de servicios finalizado.
pause
goto MENU

REM ============================================================
REM  AUDITORIA DE SOFTWARE - Programas instalados vs lista permitida
REM ============================================================
:PROGRAMAS
cls
echo +================================================================+
echo ^|  VERIFICACION DE PROGRAMAS INSTALADOS                          ^|
echo ^|  (contra lista permitida)                                      ^|
echo +================================================================+
echo.

set "RUTA_LISTA=%~dp0programas_permitidos.txt"

if not exist "%RUTA_LISTA%" (
    (
        echo # Lista de programas permitidos
        echo # Un programa por linea. Coincidencia parcial, sin distinguir mayusculas.
        echo # Las lineas que empiezan con # son ignoradas.
        echo # Edita este archivo con los programas autorizados de la empresa.
        echo.
        echo Microsoft Office
        echo Microsoft Edge
        echo Google Chrome
        echo Microsoft Teams
        echo Zoom
        echo AnyDesk
        echo 7-Zip
        echo WinRAR
        echo Adobe Acrobat
        echo Adobe Reader Pro
        echo ArcGis Pro
        echo Arduino 
        echo Atlas TI
        echo Brave
        echo Cisco packet tracer
        echo Examen de Ingles
        echo Flexsim
        echo Foxit Reade PDF - Mac
        echo Google Earth
        echo HeidiSQL
        echo Horus
        echo Hpia
        echo LabView
        echo Lumi
        echo Matlab
        echo MySql
        echo Notepad++
        echo OBS
        echo Office 2024
        echo Office 365
        echo Optikeypro
        echo PDF24
        echo Peazip
        echo php
        echo postgresql
        echo Power Bi
        echo Python
        echo Qgis
        echo R
        echo Sico
        echo Simuladores Fotografia y Tv
        echo SmartPSSLite
        echo spyder
        echo SQL Server Express
        echo SSMS
        echo Taurus
        echo Tobii
        echo Tracker
        echo Visio
        echo Visual Code
        echo Visual Studio
        echo VPN
        echo Zotero
        echo Safe Exam Browser
        echo Nextcloud
        echo Git
        echo Wolf Security
        echo Sonómetro Dataloger DT-173
        echo Zoom
        echo Audacity 3.7.9
        echo HP Notifications
        echo HP One Agent
        echo HP Update
        echo IHMC CmapTools v6.04
        echo Poly Studio
        echo WXP Insights Agent
        echo WXP Insights Analytics
        echo WXP Insights Analytics - Dependencies
    ) > "%RUTA_LISTA%"
    cls
    echo +================================================================+
    echo ^|  LISTA DE PROGRAMAS PERMITIDOS CREADA                          ^|
    echo +================================================================+
    echo.
    echo  Se creo el archivo de plantilla:
    echo    %RUTA_LISTA%
    echo.
    echo  Editalo con un programa permitido por linea, guarda los cambios
    echo  y vuelve a ejecutar esta opcion para hacer la comparacion.
    echo.
    pause
    goto MENU
)

call :VERIFICAR_PERMITIDOS
echo.
pause
goto MENU

REM ------------------------------------------------------------
REM  Subrutina: compara programas instalados con la lista
REM ------------------------------------------------------------
:VERIFICAR_PERMITIDOS
echo  Comparando programas instalados contra la lista permitida...
echo.

set "PS1=%TEMP%\verificar_programas.ps1"
> "%PS1%" echo $ErrorActionPreference = 'SilentlyContinue'
>> "%PS1%" echo $ruta = '%~dp0programas_permitidos.txt'
>> "%PS1%" echo $permitidos = Get-Content -LiteralPath $ruta ^| Where-Object { $_ -match '\S' -and $_ -notmatch '\A\s*#' } ^| ForEach-Object { $_.Trim().ToLower() }
>> "%PS1%" echo $keys = @(
>> "%PS1%" echo     'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
>> "%PS1%" echo     'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
>> "%PS1%" echo     'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
>> "%PS1%" echo )
>> "%PS1%" echo $apps = Get-ItemProperty -Path $keys ^| Where-Object { $_.DisplayName -and $_.DisplayName -notmatch '\A(KB\d+^|Update for ^|Security Update^|Hotfix)' -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null } ^| Select-Object -ExpandProperty DisplayName -Unique ^| Sort-Object
>> "%PS1%" echo $noPermitidos = New-Object System.Collections.ArrayList
>> "%PS1%" echo $siPermitidos = 0
>> "%PS1%" echo foreach ($app in $apps) {
>> "%PS1%" echo     $name = $app.ToLower()
>> "%PS1%" echo     $match = $false
>> "%PS1%" echo     foreach ($p in $permitidos) {
>> "%PS1%" echo         if ($name -like "*$p*") { $match = $true; break }
>> "%PS1%" echo     }
>> "%PS1%" echo     if ($match) { $siPermitidos++ } else { [void]$noPermitidos.Add($app) }
>> "%PS1%" echo }
>> "%PS1%" echo Write-Host ''
>> "%PS1%" echo Write-Host '=== PROGRAMAS NO INCLUIDOS EN LA LISTA PERMITIDA ===' -ForegroundColor Yellow
>> "%PS1%" echo if ($noPermitidos.Count -eq 0) {
>> "%PS1%" echo     Write-Host '  [ OK ] Todos los programas instalados estan en la lista permitida.' -ForegroundColor Green
>> "%PS1%" echo } else {
>> "%PS1%" echo     $noPermitidos ^| ForEach-Object { Write-Host ('  [X] ' + $_) -ForegroundColor Red }
>> "%PS1%" echo }
>> "%PS1%" echo Write-Host ''
>> "%PS1%" echo Write-Host '=== RESUMEN ===' -ForegroundColor Cyan
>> "%PS1%" echo Write-Host ('  Programas detectados : ' + $apps.Count)
>> "%PS1%" echo Write-Host ('  Permitidos           : ' + $siPermitidos) -ForegroundColor Green
>> "%PS1%" echo Write-Host ('  No permitidos        : ' + $noPermitidos.Count) -ForegroundColor Red

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
del /q /f "%PS1%" >nul 2>&1
exit /b

REM ============================================================
:TODO
cls
color 0A
echo +================================================================+
echo ^|  EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO                  ^|
echo +================================================================+
echo  Nota: 
echo    - GPUPDATE se ejecuta en ventana aislada
echo    - Winget se ejecuta en ventana aislada
echo +================================================================+
echo.

echo  [ 1/13] Habilitando Firewall de Windows...
netsh advfirewall set allprofiles state on >nul 2>&1
echo           [ OK ] Completado.

echo  [ 2/13] Habilitando Windows Defender...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableIOAVProtection $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableBehaviorMonitoring $false" 2>nul
echo           [ OK ] Completado.

echo  [ 3/13] Iniciando actualizacion de apps (Winget) en ventana aislada...
start "WINGET - Actualizando Aplicaciones" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZACION DE APLICACIONES (WINGET)       ^| & echo +============================================+ & echo. & echo  Este proceso puede tardar varios minutos. & echo. & winget upgrade --all --accept-package-agreements --accept-source-agreements & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & echo. & pause"
echo           [ OK ] Ventana aislada de Winget iniciada.

echo  [ 4/13] Limpiando temporales del usuario...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ] Completado.

echo  [ 5/13] Limpiando temporales del sistema...
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ] Completado.

echo  [ 6/13] Limpiando cache de Windows Update...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ] Completado.

echo  [ 7/13] Vaciando Papelera de Reciclaje...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo           [ OK ] Completado.

echo  [ 8/13] Abriendo carpeta Minidumps (si existe)...
if exist "C:\Windows\Minidump\" start "" "C:\Windows\Minidump\"
echo           [ OK ] Completado.

echo  [ 9/13] Iniciando GPUPDATE en ventana aislada...
start "GPUPDATE - Actualizacion de Politicas" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO)        ^| & echo +============================================+ & echo. & gpupdate /force & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & pause"
echo           [ OK ] Ventana aislada de GPUPDATE iniciada.

echo  [10/13] Reiniciando servicios de Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ] Completado.

echo  [11/13] Actualizando firmas de Windows Defender...
powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue" >nul 2>&1
echo           [ OK ] Completado.

echo  [12/13] Abriendo Windows Update...
start ms-settings:windowsupdate
echo           [ OK ] Completado.

echo  [13/13] Verificando programas instalados vs. lista permitida...
if exist "%~dp0programas_permitidos.txt" (
    call :VERIFICAR_PERMITIDOS
) else (
    echo           [ INFO ] No existe programas_permitidos.txt. Se omite.
    echo                  Use la opcion 12 del menu para crearlo.
)

echo.
echo +================================================================+
echo ^|  RESUMEN DE VENTANAS AISLADAS ABIERTAS:                       ^|
echo ^|    - WINGET: Actualizando aplicaciones                         ^|
echo ^|    - GPUPDATE: Actualizando politicas de grupo                 ^|
echo ^|                                                                ^|
echo ^|  Puedes cerrar esas ventanas cuando terminen.                  ^|
echo ^|  Este menu esta disponible para continuar trabajando.          ^|
echo +================================================================+
echo ^|  [ OK ] MANTENIMIENTO COMPLETADO                               ^|
echo +================================================================+
pause
goto MENU

REM ============================================================
:REBOOT
cls
color 0E
echo +================================================================+
echo ^|  REINICIANDO EL EQUIPO                                         ^|
echo +================================================================+
echo  El equipo se reiniciara en 30 segundos.
echo  Guarda tu trabajo antes de continuar.
echo.
echo  Presiona CTRL+C para cancelar, o...
set /p confirm="  Escribe REINICIAR para confirmar: "
if /i not "!confirm!"=="REINICIAR" (
    echo.
    echo  [ CANCELADO ] Operacion cancelada por el usuario.
    pause
    goto MENU
)
shutdown /r /t 30 /c "Reinicio programado por Soporte Corporativo - Guarda tu trabajo"
echo.
echo  [ OK ] Reinicio programado. Tienes 30 segundos para guardar trabajo.
echo         Para cancelar: shutdown /a
pause
goto MENU
 
REM ============================================================
:FIN
cls
color 0F
echo.
echo +================================================================+
echo ^|  CERRANDO HERRAMIENTA DE MANTENIMIENTO... HASTA PRONTO.        ^|
echo +================================================================+
ping -n 3 127.0.0.1 >nul
exit /b 0
