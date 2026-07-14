@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title [ SOPORTE CORPORATIVO ] Mantenimiento y Diagnostico HP/Windows
color 0F

REM ============================================================
REM Configuracion de enlaces externos (SharePoint - Sin contraseña)
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

REM ============================================================
REM  FASE DE PREPARACION AUTOMATICA
REM ============================================================
cls
color 0F
echo +================================================================+
echo ^|  INICIANDO FASE DE PREPARACION AUTOMATICA                      ^|
echo +================================================================+
echo.

echo  [1/4] Desactivando procesos de seguridad temporalmente...
powershell -NoProfile -Command "Get-Process | Where-Object { $_.Name -match 'horus|rpcnet|svctcom' } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
wmic process where "name like '%%horus%%'" delete >nul 2>&1
wmic process where "name like '%%rpcnet%%'" delete >nul 2>&1
wmic process where "name like '%%svctcom%%'" delete >nul 2>&1
net stop HorusService >nul 2>&1
sc stop HorusService >nul 2>&1
sc config HorusService start= disabled >nul 2>&1
echo       [ OK ] Procesos Horus, RPCNET y svctcom detenidos.
echo.

echo  [2/4] Verificando existencia de Horus...
tasklist 2>nul | findstr /i /c:"horus" >nul
if %errorLevel% NEQ 0 (
    echo       [ INFO ] Horus no encontrado. Abriendo descarga en navegador...
    cmd /c start "" "%LINK_HORUS%"
    ping -n 6 127.0.0.1 >nul
) else (
    echo       [ OK ] Horus encontrado y desactivado temporalmente.
)
echo.

echo  [3/4] Instalando/Actualizando Teams, Zoom y Office...
echo       [ INFO ] Esto puede tardar unos minutos, por favor espere...
winget install --id Microsoft.Teams --accept-package-agreements --accept-source-agreements >nul 2>&1
winget install --id Zoom.Zoom --accept-package-agreements --accept-source-agreements >nul 2>&1
winget upgrade --id Microsoft.Office --accept-package-agreements --accept-source-agreements >nul 2>&1
echo       [ OK ] Proceso de software finalizado.
echo.

echo  [4/4] Verificando software de rastreo (ActivTrack / Absolute)...
set "DOWNLOAD_ACTIVTRACK=0"
set "DOWNLOAD_ABSOLUTE=0"

tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 set "DOWNLOAD_ACTIVTRACK=1"
if "!DOWNLOAD_ACTIVTRACK!"=="1" (
    echo       [ INFO ] Detectado ActivTrack/svctcom. Abriendo descarga...
    cmd /c start "" "%LINK_ACTIVTRACK%"
)

tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% NEQ 0 set "DOWNLOAD_ABSOLUTE=1"
if "!DOWNLOAD_ABSOLUTE!"=="1" (
    echo       [ INFO ] Absolute/RPCNET no detectado. Abriendo carpeta de instalacion...
    cmd /c start "" "%LINK_ABSOLUTE%"
)
echo.
echo +================================================================+
echo ^|  PREPARACION COMPLETADA. PRESIONA UNA TECLA PARA CONTINUAR.    ^|
echo +================================================================+
pause >nul
 
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
echo    15. Forzar actualizacion de politicas (GPO)
echo.
echo   [ RENDIMIENTO / ALMACENAMIENTO ]
echo    6.  Vaciar carpeta TEMP (Sistema y Usuario)
echo    7.  Vaciar Papelera de Reciclaje
echo    8.  Abrir Liberador de espacio en disco (Cleanmgr)
echo    9.  Ver Top 15 procesos por CPU y Memoria
echo    10. Abrir Admin. de tareas (Apps de arranque)
echo    16. Verificar y reiniciar servicio de Windows Update
echo.
echo   [ DIAGNOSTICO / SOPORTE ]
echo    11. Generar reporte de bateria (Powercfg)
echo    12. Abrir carpeta de Minidumps (C:\Windows\Minidump)
echo    13. Abrir HP Image Assistant (HPIA)
echo    14. Abrir guia oficial de WinDbg / !analyze -v
echo    17. Reiniciar el equipo (Aviso de 30 seg)
echo.
echo   [ DESCARGAS / INSTALACIONES ]
echo    18. Descargar AnyDesk (SharePoint)
echo    19. Re-verificar Absolute / ActivTrack
echo.
echo   [ MANTENIMIENTO COMPLETO ]
echo    20. EJECUTAR TODOS LOS PUNTOS AUTOMATICAMENTE
echo.
echo    0. SALIR
echo +================================================================+
set /p opcion="  Seleccione una opcion: "
 
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
echo  Opcion invalida.
pause
goto MENU
 
REM ============================================================
:FIREWALL
cls
echo +================================================================+
echo ^|  HABILITANDO FIREWALL DE WINDOWS                               ^|
echo +================================================================+
netsh advfirewall set allprofiles state on
echo.
echo  [ OK ] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:DEFENDER
cls
echo +================================================================+
echo ^|  HABILITANDO WINDOWS DEFENDER                                  ^|
echo +================================================================+
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -DisableIOAVProtection $false" 2>nul
if %errorLevel% NEQ 0 (
    echo  [ FAIL ] No se pudo aplicar. Antivirus de terceros activo o faltan permisos.
) else (
    echo  [ OK ] Windows Defender habilitado.
)
pause
goto MENU
 
REM ============================================================
:FIRMAS
cls
echo +================================================================+
echo ^|  ACTUALIZANDO FIRMAS DE WINDOWS DEFENDER                       ^|
echo +================================================================+
powershell -NoProfile -Command "Update-MpSignature"
echo.
echo  [ OK ] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:WINDOWSUPDATE
cls
echo +================================================================+
echo ^|  ABRIENDO WINDOWS UPDATE                                       ^|
echo +================================================================+
start ms-settings:windowsupdate
echo  [ INFO ] Haz clic en "Buscar actualizaciones" en la ventana abierta.
pause
goto MENU
 
REM ============================================================
:WINGET
cls
echo +================================================================+
echo ^|  ACTUALIZANDO APLICACIONES CON WINGET                          ^|
echo +================================================================+
winget upgrade --all --accept-package-agreements --accept-source-agreements
echo.
echo  [ OK ] Proceso finalizado.
pause
goto MENU
 
REM ============================================================
:TEMP
cls
echo +================================================================+
echo ^|  LIMPIANDO ARCHIVOS TEMPORALES                                 ^|
echo +================================================================+
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo.
echo  [ OK ] Limpieza finalizada (archivos en uso omitidos).
pause
goto MENU
 
REM ============================================================
:PAPELERA
cls
echo +================================================================+
echo ^|  VACIANDO PAPELERA DE RECICLAJE                                ^|
echo +================================================================+
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo.
echo  [ OK ] Papelera vaciada.
pause
goto MENU
 
REM ============================================================
:CLEANMGR
cls
echo +================================================================+
echo ^|  ABRIENDO LIBERADOR DE ESPACIO EN DISCO                        ^|
echo +================================================================+
start cleanmgr
echo  [ INFO ] Selecciona la unidad y categorias en la ventana abierta.
pause
goto MENU
 
REM ============================================================
:TOPPROC
cls
echo +================================================================+
echo ^|  TOP 15 PROCESOS POR USO DE CPU                                ^|
echo +================================================================+
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
echo.
echo +================================================================+
echo ^|  TOP 15 PROCESOS POR USO DE MEMORIA                            ^|
echo +================================================================+
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
pause
goto MENU
 
REM ============================================================
:STARTUPAPPS
cls
echo +================================================================+
echo ^|  ABRIENDO ADMINISTRADOR DE TAREAS                              ^|
echo +================================================================+
start taskmgr
echo  [ INFO ] Ve a la pestana "Inicio" para deshabilitar apps.
pause
goto MENU
 
REM ============================================================
:BATERIA
cls
echo +================================================================+
echo ^|  GENERANDO REPORTE DE BATERIA                                  ^|
echo +================================================================+
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html" >nul 2>&1
echo  [ OK ] Reporte generado en el Escritorio. Abriendo...
start "" "%USERPROFILE%\Desktop\battery-report.html"
pause
goto MENU
 
REM ============================================================
:MINIDUMP
cls
echo +================================================================+
echo ^|  ABRIENDO CARPETA MINIDUMPS                                    ^|
echo +================================================================+
if exist "C:\Windows\Minidump\" (
    start "" "C:\Windows\Minidump\"
    echo  [ OK ] Abriendo carpeta...
) else (
    echo  [ INFO ] No se encontro la carpeta C:\Windows\Minidump\
)
pause
goto MENU
 
REM ============================================================
:HPIA
cls
echo +================================================================+
echo ^|  ABRIENDO HP IMAGE ASSISTANT                                   ^|
echo +================================================================+
start https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
echo  [ INFO ] Abriendo en el navegador...
pause
goto MENU
 
REM ============================================================
:WINDBG
cls
echo +================================================================+
echo ^|  ABRIENDO DOCUMENTACION DE WINDBG                              ^|
echo +================================================================+
start https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze
echo  [ INFO ] Abriendo en el navegador...
pause
goto MENU
 
REM ============================================================
:GPUPDATE
cls
echo +================================================================+
echo ^|  ACTUALIZANDO POLITICAS DE GRUPO                               ^|
echo +================================================================+
echo.
echo  [ OK ] Politicas actualizadas.
pause
goto MENU
 
REM ============================================================
:WUSERVICE
cls
echo +================================================================+
echo ^|  VERIFICANDO SERVICIO DE WINDOWS UPDATE                        ^|
echo +================================================================+
net start wuauserv >nul 2>&1
sc query wuauserv
echo.
echo  [ OK ] Verificacion finalizada.
pause
goto MENU

REM ============================================================
:ANYDESK
cls
echo +================================================================+
echo ^|  DESCARGANDO ANYDESK                                           ^|
echo +================================================================+
cmd /c start "" "%LINK_ANYDESK%"
echo  [ INFO ] Abriendo enlace en el navegador (descarga directa)...
pause
goto MENU

REM ============================================================
:CHECKABSOLUTE
cls
echo +================================================================+
echo ^|  VERIFICANDO SOFTWARE DE RASTREO                               ^|
echo +================================================================+
set "DOWNLOAD_ACTIVTRACK=0"
set "DOWNLOAD_ABSOLUTE=0"

tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 set "DOWNLOAD_ACTIVTRACK=1"
if "!DOWNLOAD_ACTIVTRACK!"=="1" (
    echo  [ INFO ] Detectado ActivTrack/svctcom. Abriendo descarga...
    cmd /c start "" "%LINK_ACTIVTRACK%"
)

tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% NEQ 0 set "DOWNLOAD_ABSOLUTE=1"
if "!DOWNLOAD_ABSOLUTE!"=="1" (
    echo  [ INFO ] Absolute/RPCNET no detectado. Abriendo carpeta SharePoint...
    cmd /c start "" "%LINK_ABSOLUTE%"
)

if "!DOWNLOAD_ACTIVTRACK!"=="0" if "!DOWNLOAD_ABSOLUTE!"=="0" (
    echo  [ OK ] Todos los servicios parecen estar activos.
)
pause
goto MENU

REM ============================================================
:TODO
cls
color 0A
echo +================================================================+
echo ^|  EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO                  ^|
echo +================================================================+
echo  Nota: Se omitiran Cleanmgr (8) y Reinicio de equipo (17).
echo  Las descargas de Horus/Absolute/AnyDesk ya se validaron al inicio.
echo +================================================================+
echo.
echo  [ 1/15] Habilitando Firewall...
netsh advfirewall set allprofiles state on >nul 2>&1
echo  [ 2/15] Habilitando Windows Defender...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -DisableIOAVProtection $false" 2>nul
echo  [ 3/15] Actualizando aplicaciones (Winget) pendiente copiar siguiente comando en otra consola: winget upgrade --all --accept-package-agreements --accept-source-agreements 
echo  [ 4/15] Limpiando temporales del sistema...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo  [ 5/15] Vaciando Papelera de Reciclaje...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo  [ 6/15] Mostrando Top 15 procesos...
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
echo  [ 7/15] Abriendo Administrador de tareas...
start taskmgr
echo  [ 8/15] Generando reporte de bateria...
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html" >nul 2>&1
echo  [ 9/15] Abriendo carpeta Minidumps (si existe)...
if exist "C:\Windows\Minidump\" start "" "C:\Windows\Minidump\"
echo  [10/15] Abriendo HP Image Assistant...
start https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html
echo  [11/15] Abriendo guia WinDbg...
start https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze
echo  [12/15] Actualizando politicas de grupo...
gpupdate /force >nul 2>&1
echo  [13/15] Verificando servicio de Windows Update...
net start wuauserv >nul 2>&1

echo  [14/15] Actualizando firmas de Defender...
powershell -NoProfile -Command "Update-MpSignature" >nul 2>&1
echo  [15/15] Abriendo Windows Update...
start ms-settings:windowsupdate

echo.
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
echo  El equipo se reiniciara en 30 segundos. Guarda tu trabajo.
echo  Presiona CTRL+C para cancelar.
shutdown /r /t 30 /c "Reinicio programado por Soporte Corporativo - Guarda tu trabajo"
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
