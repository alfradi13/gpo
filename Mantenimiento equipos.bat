@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Herramienta de Mantenimiento y Diagnostico de Equipos - HP/Windows

REM ============================================================
REM Configuracion de enlaces externos (SharePoint)
REM ============================================================
set "LINK_HORUS=https://unadvirtualedu-my.sharepoint.com/:u:/g/personal/fabio_benavides_unad_edu_co/IQB8EzMNw5WCTKP_SIbNr3_zAdod09Zb8y6A8LWlH4K12QE?e=1xz4ok"
set "LINK_ANYDESK=https://unadvirtualedu-my.sharepoint.com/:u:/g/personal/fabio_benavides_unad_edu_co/IQCiHZD_u4tsQqk_BpQOvRaFAbKyotGdn5XN5jCW1ZXw1-o?e=37rkrH"
set "LINK_ACTIVTRACK=https://unadvirtualedu-my.sharepoint.com/:u:/g/personal/fabio_benavides_unad_edu_co/IQBAPG7UAK1OTawnPmkOGZ9GAcBhtkQCEIdiyaIhOu2KL9w?e=NXaf5G"
set "LINK_ABSOLUTE=https://unadvirtualedu-my.sharepoint.com/:f:/g/personal/fabio_benavides_unad_edu_co/IgC--z4fRGqPQb4a5nA_kaO3AaOVU-WGjOSDWn1S0u_nceM?e=bcKTpH"

REM ============================================================
REM  Verificar privilegios de Administrador 
REM ============================================================
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo  [!] Este script requiere permisos de ADMINISTRADOR.
    echo      Cierra esta ventana y ejecuta el .bat con "Ejecutar como administrador".
    echo.
    pause
    exit /b
)

REM ============================================================
REM  FASE DE PREPARACION AUTOMATICA (Al ejecutar el script)
REM ============================================================
echo ================================================================
echo  FASE DE PREPARACION AUTOMATICA - POR FAVOR ESPERA...
echo ================================================================

echo [1/4] Desactivando Horus y HorusService temporalmente...
taskkill /f /im horus.exe >nul 2>&1
taskkill /f /im horussvc.exe >nul 2>&1
net stop HorusService >nul 2>&1
sc stop HorusService >nul 2>&1
sc config HorusService start= disabled >nul 2>&1
powershell -NoProfile -Command "Get-Process -Name horus,horussvc -ErrorAction SilentlyContinue | Stop-Process -Force; Stop-Service -Name HorusService -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo     Procesos desactivados.

echo [2/4] Verificando existencia de Horus...
tasklist 2>nul | findstr /i /c:"horus" >nul
if %errorLevel% NEQ 0 (
    echo     Horus no encontrado. Abriendo enlace de instalacion...
    start "" "%LINK_HORUS%"
    ping -n 6 127.0.0.1 >nul
) else (
    echo     Horus encontrado y desactivado temporalmente.
)

echo [3/4] Instalando/Actualizando Teams, Zoom y Office...
echo     (Esto puede tardar unos minutos, por favor espere...)
winget install --id Microsoft.Teams --accept-package-agreements --accept-source-agreements >nul 2>&1
winget install --id Zoom.Zoom --accept-package-agreements --accept-source-agreements >nul 2>&1
winget upgrade --id Microsoft.Office --accept-package-agreements --accept-source-agreements >nul 2>&1
echo     Proceso de instalacion de software finalizado.

echo [4/4] Verificando software de seguridad (ActivTrack / Absolute)...
set "DOWNLOAD_ACTIVTRACK=0"
set "DOWNLOAD_ABSOLUTE=0"

tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 set "DOWNLOAD_ACTIVTRACK=1"

if "%DOWNLOAD_ACTIVTRACK%"=="1" (
    echo     Detectado ActivTrack/svctcom. Abriendo descarga...
    start "" "%LINK_ACTIVTRACK%"
)

tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% NEQ 0 set "DOWNLOAD_ABSOLUTE=1"

if "%DOWNLOAD_ABSOLUTE%"=="1" (
    echo     Absolute/RPCNET no detectado. Abriendo enlace de instalacion...
    start "" "%LINK_ABSOLUTE%"
)

echo.
echo  Preparacion automatica completada. Presiona una tecla para ir al Menu.
pause >nul
 
:MENU
cls
echo ================================================================
echo        MANTENIMIENTO Y DIAGNOSTICO DE EQUIPOS - MENU PRINCIPAL
echo ================================================================
echo.
echo   SEGURIDAD
echo   1. Habilitar Firewall de Windows (los 3 perfiles)
echo   2. Habilitar Windows Defender (antivirus en tiempo real)
echo   3. Actualizar firmas de malware de Windows Defender
echo.
echo   ACTUALIZACIONES
echo   4. Buscar actualizaciones de Windows (abre Windows Update)
echo   5. Actualizar todas las apps instaladas (winget upgrade --all)
echo   15. Forzar actualizacion de politicas de grupo (gpupdate /force)
echo.
echo   RENDIMIENTO / ALMACENAMIENTO
echo   6. Vaciar carpeta TEMP del sistema y del usuario
echo   7. Vaciar Papelera de Reciclaje
echo   8. Abrir Liberador de espacio en disco (cleanmgr)
echo   9. Ver Top 15 procesos por uso de CPU y Memoria
echo   10. Abrir Administrador de tareas en pestaña "Inicio" (apps de arranque)
echo   16. Verificar y (re)iniciar servicio de Windows Update
echo.
echo   BATERIA / HARDWARE (equipos portatiles)
echo   11. Generar reporte de estado de bateria (powercfg /batteryreport)
echo.
echo   DIAGNOSTICO AVANZADO / SOPORTE
echo   12. Abrir carpeta de Minidumps (C:\Windows\Minidump)
echo   13. Abrir pagina oficial de HP Image Assistant (descarga)
echo   14. Abrir guia oficial de WinDbg / !analyze -v (Microsoft Learn)
echo   17. Reiniciar el equipo ahora (con 30 seg de aviso)
echo.
echo   DESCARGAS / INSTALACIONES ADICIONALES
echo   18. Descargar AnyDesk (SharePoint)
echo   19. Verificar/Descargar Absolute (RPCNET/ActivTrack)
echo.
echo   MANTENIMIENTO COMPLETO
echo   20. EJECUTAR TODOS LOS PUNTOS AUTOMATICAMENTE
echo.
echo   0. Salir
echo ================================================================
set /p opcion="Selecciona una opcion: "
 
if "%opcion%"=="1" goto FIREWALL
if "%opcion%"=="2" goto DEFENDER
if "%opcion%"=="3" goto FIRMAS
if "%opcion%"=="4" goto WINDOWSUPDATE
if "%opcion%"=="5" goto WINGET
if "%opcion%"=="6" goto TEMP
if "%opcion%"=="7" goto PAPELERA
if "%opcion%"=="8" goto CLEANMGR
if "%opcion%"=="9" goto TOPPROC
if "%opcion%"=="10" goto STARTUPAPPS
if "%opcion%"=="11" goto BATERIA
if "%opcion%"=="12" goto MINIDUMP
if "%opcion%"=="13" goto HPIA
if "%opcion%"=="14" goto WINDBG
if "%opcion%"=="15" goto GPUPDATE
if "%opcion%"=="16" goto WUSERVICE
if "%opcion%"=="17" goto REBOOT
if "%opcion%"=="18" goto ANYDESK
if "%opcion%"=="19" goto CHECKABSOLUTE
if "%opcion%"=="20" goto TODO
if "%opcion%"=="0" goto FIN
echo Opcion invalida.
pause
goto MENU
 
REM ============================================================
:FIREWALL
echo.
echo Habilitando Firewall de Windows en los 3 perfiles...
netsh advfirewall set allprofiles state on
echo [OK] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:DEFENDER
echo.
echo Habilitando Windows Defender (proteccion en tiempo real)...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -DisableIOAVProtection $false" 2>nul
if %errorLevel% NEQ 0 (
    echo [!] No se pudo aplicar. Antivirus de terceros activo o faltan permisos.
) else (
    echo [OK] Windows Defender habilitado.
)
pause
goto MENU
 
REM ============================================================
:FIRMAS
echo.
echo Actualizando firmas de malware de Windows Defender...
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
echo [OK] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:WINDOWSUPDATE
echo.
echo Abriendo Windows Update...
start ms-settings:windowsupdate
echo [i] Haz clic en "Buscar actualizaciones" en la ventana abierta.
pause
goto MENU
 
REM ============================================================
:WINGET
echo.
echo Actualizando todas las aplicaciones instaladas con winget...
winget upgrade --all --accept-package-agreements --accept-source-agreements
echo [OK] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:TEMP
echo.
echo Limpiando temporales (se omitiran los que esten bloqueados)...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo [OK] Limpieza finalizada.
pause
goto MENU
 
REM ============================================================
:PAPELERA
echo.
echo Vaciando la Papelera de Reciclaje...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo [OK] Papelera vaciada.
pause
goto MENU
 
REM ============================================================
:CLEANMGR
echo.
start cleanmgr
echo [i] Selecciona la unidad y categorias en la ventana abierta.
pause
goto MENU
 
REM ============================================================
:TOPPROC
echo.
echo Top 15 procesos por uso de CPU:
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
echo.
echo Top 15 procesos por uso de Memoria:
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
pause
goto MENU
 
REM ============================================================
:STARTUPAPPS
echo.
start taskmgr
echo [i] Ve a la pestana "Inicio" para deshabilitar apps.
pause
goto MENU
 
REM ============================================================
:BATERIA
echo.
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html"
echo [OK] Reporte generado en el Escritorio. Abriendo...
start "" "%USERPROFILE%\Desktop\battery-report.html"
pause
goto MENU
 
REM ============================================================
:MINIDUMP
echo.
if exist "C:\Windows\Minidump\" (
    start "" "C:\Windows\Minidump\"
    echo [i] Abriendo carpeta de Minidumps...
) else (
    echo [i] No se encontro la carpeta C:\Windows\Minidump\
)
pause
goto MENU
 
REM ============================================================
:HPIA
echo.
start https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
echo [i] Abriendo HP Image Assistant en el navegador...
pause
goto MENU
 
REM ============================================================
:WINDBG
echo.
start https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze
echo [i] Abriendo documentacion de WinDbg...
pause
goto MENU
 
REM ============================================================
:GPUPDATE
echo.
gpupdate /force
echo [OK] Politicas actualizadas.
pause
goto MENU
 
REM ============================================================
:WUSERVICE
echo.
net start wuauserv >nul 2>&1
sc query wuauserv
echo [OK] Verificacion finalizada.
pause
goto MENU

REM ============================================================
:ANYDESK
echo.
start "" "%LINK_ANYDESK%"
echo [i] Abriendo enlace de AnyDesk en el navegador...
pause
goto MENU

REM ============================================================
:CHECKABSOLUTE
echo.
echo Verificando software de seguridad en ejecucion...
set "DOWNLOAD_ACTIVTRACK=0"
set "DOWNLOAD_ABSOLUTE=0"

tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 set "DOWNLOAD_ACTIVTRACK=1"

if "%DOWNLOAD_ACTIVTRACK%"=="1" (
    echo Se detecto ActivTrack/svctcom. Abriendo descarga...
    start "" "%LINK_ACTIVTRACK%"
)

tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% NEQ 0 set "DOWNLOAD_ABSOLUTE=1"

if "%DOWNLOAD_ABSOLUTE%"=="1" (
    echo Absolute/RPCNET no detectado. Abriendo enlace...
    start "" "%LINK_ABSOLUTE%"
)

if "%DOWNLOAD_ACTIVTRACK%"=="0" if "%DOWNLOAD_ABSOLUTE%"=="0" (
    echo Todos los servicios parecen estar activos y corriendo.
)
pause
goto MENU

REM ============================================================
:TODO
cls
echo ================================================================
echo  EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO
echo  (Omitiendo Liberador de espacio y Reinicio de equipo)
echo  (Este proceso puede tardar varios minutos. No cierres la ventana)
echo ================================================================
echo.
echo [1/15] Habilitando Firewall...
netsh advfirewall set allprofiles state on >nul 2>&1
echo [2/15] Habilitando Windows Defender...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -DisableIOAVProtection $false" 2>nul
echo [3/15] Actualizando firmas de Defender...
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate >nul 2>&1
echo [4/15] Abriendo Windows Update...
start ms-settings:windowsupdate
echo [5/15] Actualizando aplicaciones (Winget)...
winget upgrade --all --accept-package-agreements --accept-source-agreements >nul 2>&1
echo [6/15] Limpiando temporales del sistema...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo [7/15] Vaciando Papelera de Reciclaje...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo [8/15] Mostrando Top 15 procesos...
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
echo [9/15] Abriendo Administrador de tareas...
start taskmgr
echo [10/15] Generando reporte de bateria...
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html" >nul 2>&1
echo [11/15] Abriendo carpeta Minidumps (si existe)...
if exist "C:\Windows\Minidump\" start "" "C:\Windows\Minidump\"
echo [12/15] Abriendo HP Image Assistant...
start https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
echo [13/15] Abriendo guia WinDbg...
start https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze
echo [14/15] Actualizando politicas de grupo...
gpupdate /force >nul 2>&1
echo [15/15] Verificando servicio de Windows Update...
net start wuauserv >nul 2>&1

echo.
echo  Verificando Absolute/ActivTrack y AnyDesk...
tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 start "" "%LINK_ACTIVTRACK%"
tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% NEQ 0 start "" "%LINK_ABSOLUTE%"

echo.
echo ================================================================
echo  [OK] MANTENIMIENTO COMPLETADO. 
echo  NOTA: Se omitieron Cleanmgr (8) y Reinicio de equipo (17).
echo ================================================================
pause
goto MENU

REM ============================================================
:REBOOT
echo.
shutdown /r /t 30 /c "Reinicio programado por mantenimiento - Guarda tu trabajo"
pause
goto MENU
 
REM ============================================================
:FIN
exit /b 0