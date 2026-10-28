@echo off
setlocal EnableExtensions DisableDelayedExpansion
title [ SOPORTE CORPORATIVO ] Mantenimiento y Diagnostico HP/Windows
color 0F

REM ============================================================
REM  v2 - Menu reducido a tareas esenciales:
REM   - Winget, politicas GPO, HPIA, agentes y auditoria de software.
REM   - Se eliminaron: Firewall/Defender/firmas, Windows Update,
REM     limpieza de temporales/papelera/Cleanmgr, top de procesos,
REM     Administrador de tareas, minidumps, WinDbg, reinicio y MAC.
REM ============================================================

REM ============================================================
REM  CONFIGURACION (ajusta aqui)
REM ============================================================
set "SELF=%~f0"
set "HPIA_VER=5.3.7"
set "LOGDIR=%ProgramData%\SoporteCorp"
set "LOGFILE=%LOGDIR%\mantenimiento.log"
set "ERRS=0"

REM ============================================================
REM  Verificar privilegios de Administrador (con auto-elevacion)
REM ============================================================
whoami /groups 2>nul | find "S-1-16-12288" >nul
if errorlevel 1 goto NOADMIN
goto ADMINOK

:NOADMIN
if /i "%~1"=="/elev" goto NOADMIN_FINAL
echo.
echo   Solicitando permisos de administrador...
powershell -NoProfile -Command "try { Start-Process -FilePath $env:SELF -ArgumentList '/elev' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 exit /b 0

:NOADMIN_FINAL
cls
color 0C
echo +================================================================+
echo   [!] ERROR DE PRIVILEGIOS
echo +================================================================+
echo   Este script requiere permisos de ADMINISTRADOR.
echo   Cierra esta ventana, clic derecho sobre el .bat
echo   y selecciona "Ejecutar como administrador".
echo +================================================================+
echo.
pause
exit /b 1

:ADMINOK
if /i "%~1"=="/task" goto RUNTASK
if not exist "%LOGDIR%\" mkdir "%LOGDIR%" >nul 2>&1
call :LOG "===== Inicio de sesion de mantenimiento ====="

REM ============================================================
REM  FASE DE PREPARACION AUTOMATICA
REM ============================================================
cls
color 0F
echo +================================================================+
echo   INICIANDO FASE DE PREPARACION AUTOMATICA
echo +================================================================+
echo.
echo  [1/3] Verificando estado del sistema...
call :F_SYSCHECK
echo.

echo  [2/3] Instalando/Actualizando Teams, Zoom y apps...
echo       [ INFO ] Esto puede tardar varios minutos.
choice /c SN /t 10 /d S /m "      Ejecutar ahora. S=Si, N=Omitir. Autocontinua en 10 s"
if errorlevel 2 goto PREP_SKIP
call :F_PREPAPPS
goto PREP_AGENTS

:PREP_SKIP
echo       [ OMITIDO ] Instalacion/actualizacion omitida por el usuario.

:PREP_AGENTS
echo.
echo  [3/3] Verificando agentes de seguridad y monitoreo...
echo.
call :CHECK_AGENT "Horus" "horus" "horus"
call :CHECK_AGENT "Absolute RPCNET" "rpcnet" "absolute"
call :CHECK_AGENT "ActivTrack" "activtrack" "svctcom"
call :CHECK_AGENT "HP Proactive Insight" "hpvsc" "proactive"
echo.
echo +================================================================+
echo   PREPARACION COMPLETADA. PRESIONA UNA TECLA PARA CONTINUAR.
echo +================================================================+
pause >nul

REM ============================================================
REM  MENU PRINCIPAL
REM ============================================================
:MENU
cls
color 0F
echo +================================================================+
echo         MANTENIMIENTO Y DIAGNOSTICO DE EQUIPOS HP/WINDOWS
echo                      SOPORTE CORPORATIVO
echo +================================================================+
echo.
echo   [ ACTUALIZACIONES Y GPO ]
echo    1.  Actualizar apps instaladas - Winget
echo    2.  Forzar actualizacion de politicas GPO - ventana aislada
echo    3.  Verificar politicas GPO aplicadas - ventana aislada
echo    4.  Limpiar cache GPO y reiniciar - ventana aislada, con confirmacion
echo.
echo   [ DIAGNOSTICO / SOPORTE ]
echo    5.  Descargar y ejecutar HP Image Assistant - HPIA
echo    6.  Re-verificar Absolute / ActivTrack
echo.
echo   [ AUDITORIA ]
echo    7.  Verificar programas instalados vs. lista permitida
echo.
echo   [ MANTENIMIENTO COMPLETO ]
echo    8.  EJECUTAR TODAS LAS TAREAS AUTOMATICAMENTE
echo.
echo    0.  SALIR
echo +================================================================+
set "opcion="
set /p "opcion=  Seleccione una opcion: "
if not defined opcion goto MENU
set "opcion=%opcion:"=%"

if "%opcion%"=="1" goto WINGET
if "%opcion%"=="2" goto GPUPDATE
if "%opcion%"=="3" goto VERIFYGPO
if "%opcion%"=="4" goto CLEANGPO
if "%opcion%"=="5" goto HPIA
if "%opcion%"=="6" goto CHECKABSOLUTE
if "%opcion%"=="7" goto PROGRAMAS
if "%opcion%"=="8" goto TODO
if "%opcion%"=="0" goto FIN

echo.
echo  Opcion invalida.
timeout /t 2 >nul
goto MENU

REM ============================================================
REM  OPCIONES DEL MENU  - cada una usa las subrutinas F_ del final
REM ============================================================
:WINGET
call :HEADER "ACTUALIZANDO APLICACIONES CON WINGET"
echo   Esto puede tardar varios minutos.
echo.
call :F_WINGET_UPGRADE
pause
goto MENU

:GPUPDATE
call :HEADER "ACTUALIZANDO POLITICAS DE GRUPO GPO - MODO AISLADO"
echo   Iniciando actualizacion de politicas en ventana separada...
call :F_LAUNCH GPUPDATE "GPUPDATE - Actualizacion de Politicas"
pause
goto MENU

:VERIFYGPO
call :HEADER "VERIFICANDO POLITICAS GPO APLICADAS"
echo   Abriendo ventana aislada para verificar gpresult...
call :F_LAUNCH GPRESULT "VERIFICACION GPO - GPResult"
pause
goto MENU

:CLEANGPO
call :HEADER "LIMPIAR CACHE GPO Y REINICIAR"
echo   ADVERTENCIA: Esto eliminara la cache de politicas locales:
echo     - %SystemRoot%\System32\GroupPolicy
echo     - %SystemRoot%\System32\GroupPolicyUsers
echo     - %ProgramData%\Microsoft\Group Policy\History
echo   Se hace un respaldo previo en: %LOGDIR%
echo   Luego se ejecuta gpupdate y el equipo se reinicia en 60 segundos.
echo   Podras cancelar el reinicio con: shutdown /a
echo.
set "conf="
set /p "conf=  Escribe LIMPIAR para continuar: "
if not defined conf goto CLEANGPO_CANCEL
set "conf=%conf:"=%"
if /i not "%conf%"=="LIMPIAR" goto CLEANGPO_CANCEL
call :F_LAUNCH CLEANGPO "LIMPIEZA CACHE GPO"
echo.
echo   Sigue el avance en la ventana nueva. Para cancelar el reinicio: shutdown /a
pause
goto MENU

:CLEANGPO_CANCEL
echo.
echo   [ CANCELADO ] Operacion cancelada por el usuario.
pause
goto MENU

:HPIA
call :HEADER "HP IMAGE ASSISTANT"
call :F_HPIA
pause
goto MENU

:CHECKABSOLUTE
call :HEADER "VERIFICANDO SOFTWARE DE RASTREO"
echo   Analizando procesos y servicios...
echo.
call :CHECK_AGENT "ActivTrack" "activtrack" "svctcom"
call :CHECK_AGENT "Absolute RPCNET" "rpcnet" "absolute"
echo.
pause
goto MENU

:PROGRAMAS
call :HEADER "AUDITORIA DE PROGRAMAS INSTALADOS VS LISTA PERMITIDA"
call :F_AUDITORIA
echo.
pause
goto MENU

REM ============================================================
REM  8 - MANTENIMIENTO COMPLETO
REM ============================================================
:TODO
color 0A
set "ERRS=0"
call :HEADER "EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO"
echo   Notas:
echo    - Winget y GPUPDATE se abren en ventanas aisladas.
echo    - La auditoria de software usa: %~dp0programas_permitidos.txt
echo    - El resultado queda registrado en: %LOGFILE%
echo.
call :LOG "--- Mantenimiento completo: inicio ---"

echo  [1/5] Verificando agentes de seguridad y monitoreo...
call :CHECK_AGENT "Horus" "horus" "horus"
call :CHECK_AGENT "Absolute RPCNET" "rpcnet" "absolute"
call :CHECK_AGENT "ActivTrack" "activtrack" "svctcom"
call :CHECK_AGENT "HP Proactive Insight" "hpvsc" "proactive"
echo.

echo  [2/5] Iniciando Winget en ventana aislada...
call :F_LAUNCH WINGET "WINGET - Actualizando Aplicaciones"
echo.

echo  [3/5] Iniciando GPUPDATE en ventana aislada...
call :F_LAUNCH GPUPDATE "GPUPDATE - Actualizacion de Politicas"
echo.

echo  [4/5] Auditoria de programas instalados vs. lista permitida...
call :F_AUDITORIA
echo.

echo  [5/5] HP Image Assistant...
call :F_HPIA || set /a ERRS+=1

call :LOG "--- Mantenimiento completo: fin, pasos con error: %ERRS% ---"
echo.
echo +================================================================+
echo   RESUMEN
echo +================================================================+
echo   Ventanas aisladas abiertas: WINGET y GPUPDATE.
echo   Puedes cerrarlas cuando terminen.
echo.
if "%ERRS%"=="0" (
    echo   [ OK ] MANTENIMIENTO COMPLETADO SIN ERRORES.
) else (
    echo   [ AVISO ] MANTENIMIENTO COMPLETADO CON %ERRS% PASO/S CON ERROR. Revisa los mensajes anteriores.
)
echo   Registro: %LOGFILE%
echo +================================================================+
pause
color 0F
goto MENU

REM ============================================================
:FIN
cls
color 0F
echo.
echo +================================================================+
echo   CERRANDO HERRAMIENTA DE MANTENIMIENTO... HASTA PRONTO.
echo +================================================================+
call :LOG "===== Fin de sesion ====="
ping -n 3 127.0.0.1 >nul
endlocal
exit /b 0


REM ############################################################
REM  TAREAS EN VENTANA AISLADA
REM  Se lanzan con:  cmd /c call "este.bat" /task NOMBRE
REM ############################################################
:RUNTASK
set "TASK=%~2"
if /i "%TASK%"=="GPUPDATE" call :T_GPUPDATE
if /i "%TASK%"=="GPRESULT" call :T_GPRESULT
if /i "%TASK%"=="WINGET"   call :T_WINGET
if /i "%TASK%"=="CLEANGPO" call :T_CLEANGPO
exit /b 0

:T_GPUPDATE
title GPUPDATE - Actualizacion de Politicas
call :HEADER "ACTUALIZANDO POLITICAS DE GRUPO GPO"
echo   Directivas esperadas, se verifican con la opcion 3:
echo    - GPO_CP_Cert_Autoenrollment Compute
echo    - GPO_CP_Cert_Autoenrollment User
echo    - GPO_CP_802.1x_Adapter_Prueba
echo.
echo   Ejecutando gpupdate /force ...
echo N | gpupdate /force
echo.
echo   [ INFO ] Si gpupdate indico que se requiere cerrar sesion o reiniciar, hazlo al terminar.
call :LOG "gpupdate /force ejecutado"
echo.
echo   PROCESO FINALIZADO
pause
exit /b 0

:T_GPRESULT
title VERIFICACION GPO - GPResult
call :HEADER "VERIFICACION DE POLITICAS DE GRUPO"
set "GPR=%TEMP%\gpresult_check.txt"
echo   Generando reporte, puede tardar unos segundos...
gpresult /r /scope computer > "%GPR%" 2>&1
gpresult /r /scope user >> "%GPR%" 2>&1
type "%GPR%"
echo.
echo +================================================================+
echo   DIRECTIVAS ESPERADAS
echo +================================================================+
call :CHECK_GPO "GPO_CP_Cert_Autoenrollment"
call :CHECK_GPO "GPO_CP_802.1x_Adapter_Prueba"
echo.
echo   [ INFO ] Reporte completo guardado en: %GPR%
echo.
echo   FIN DEL REPORTE
pause
exit /b 0

:T_WINGET
title WINGET - Actualizando Aplicaciones
call :HEADER "ACTUALIZACION DE APLICACIONES - WINGET"
echo   Este proceso puede tardar varios minutos.
echo.
call :F_WINGET_UPGRADE
echo.
echo   PROCESO FINALIZADO
pause
exit /b 0

:T_CLEANGPO1
title LIMPIEZA CACHE GPO
call :HEADER "LIMPIANDO CACHE DE POLITICAS LOCALES"
call :GETSTAMP
set "BK=%LOGDIR%\GPO_backup_%STAMP%"
set "BKFAIL="
echo   Respaldando en: %BK%
mkdir "%BK%" >nul 2>&1
if exist "%SystemRoot%\System32\GroupPolicy\" (xcopy "%SystemRoot%\System32\GroupPolicy" "%BK%\GroupPolicy\" /e /i /h /y /q >nul 2>&1 & if errorlevel 2 set "BKFAIL=1")
if exist "%SystemRoot%\System32\GroupPolicyUsers\" (xcopy "%SystemRoot%\System32\GroupPolicyUsers" "%BK%\GroupPolicyUsers\" /e /i /h /y /q >nul 2>&1 & if errorlevel 2 set "BKFAIL=1")
if exist "%ProgramData%\Microsoft\Group Policy\History\" (xcopy "%ProgramData%\Microsoft\Group Policy\History" "%BK%\History\" /e /i /h /y /q >nul 2>&1 & if errorlevel 2 set "BKFAIL=1")
if defined BKFAIL (
    echo   [ ERROR ] Fallo el respaldo. No se elimina nada.
    call :LOG "Limpieza GPO abortada: fallo respaldo"
    pause
    exit /b 1
)
echo   [ OK ] Respaldo creado.
echo.
echo   Eliminando cache de politicas...
rd /s /q "%SystemRoot%\System32\GroupPolicy" >nul 2>&1
rd /s /q "%SystemRoot%\System32\GroupPolicyUsers" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\Group Policy\History" >nul 2>&1
echo   [ OK ] Cache eliminada.
call :LOG "Cache GPO eliminada, respaldo en %BK%"
echo.
echo   Actualizando politicas...
echo N | gpupdate /force
echo.
shutdown /r /t 1000 /c "Limpieza GPO - Soporte Corporativo"
if errorlevel 1 (
    echo   [ ERROR ] No se pudo programar el reinicio. Reinicia el equipo manualmente.
) else (
    echo   [ OK ] Reinicio programado en 1000 segundos. Cancela con: shutdown /a
)
echo.
pause
exit /b 0


REM ############################################################
REM  SUBRUTINAS - FUNCIONES
REM  Convencion: devuelven 0 si salio bien y 1 si hubo error
REM ############################################################

:HEADER
cls
echo +================================================================+
echo   %~1
echo +================================================================+
echo.
exit /b 0

:LOG
if not exist "%LOGDIR%\" mkdir "%LOGDIR%" >nul 2>&1
>>"%LOGFILE%" echo [%date% %time%] %~1
exit /b 0

:GETSTAMP
set "STAMP="
for /f "delims=" %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=manual"
exit /b 0

:F_LAUNCH
REM  %1 = nombre de la tarea, %2 = titulo de la ventana
start %2 cmd /c call "%SELF%" /task %1
echo   [ OK ] Ventana aislada iniciada.
call :LOG "Ventana aislada: %~1"
exit /b 0

:CHECK_AGENT
REM  %1 = nombre, %2 y %3 = patrones a buscar en procesos y servicios
set "AG_PROC="
set "AG_SVC="
tasklist 2>nul | findstr /i /l /c:"%~2" /c:"%~3" >nul && set "AG_PROC=1"
sc query state= all 2>nul | findstr /i /l /c:"%~2" /c:"%~3" >nul && set "AG_SVC=1"
if defined AG_PROC (
    echo       [ ACTIVO ] %~1 detectado en ejecucion.
    call :LOG "Agente %~1: ACTIVO"
    exit /b 0
)
if defined AG_SVC (
    echo       [ SERVICIO ] %~1: servicio instalado pero sin proceso en ejecucion.
    call :LOG "Agente %~1: servicio sin proceso"
    exit /b 1
)
echo       [ INACTIVO ] %~1 no encontrado.
call :LOG "Agente %~1: NO ENCONTRADO"
exit /b 1

:CHECK_GPO
findstr /i /l /c:"%~1" "%GPR%" >nul 2>&1
if errorlevel 1 (
    echo       [ NO ENCONTRADA ] %~1
) else (
    echo       [ APLICADA ] %~1
)
exit /b 0

:WG_RESULT
set "WGRC=%errorlevel%"
if "%WGRC%"=="0" (
    echo       [ OK ] %~1
) else (
    echo       [ AVISO ] %~1 devolvio codigo %WGRC%. Si ya estaba instalado o actualizado es normal.
)
call :LOG "winget %~1 codigo %WGRC%"
exit /b 0

REM ------------------------------------------------------------
:F_SYSCHECK
ver
powershell -NoProfile -Command "try { $d = Get-PSDrive -Name C -ErrorAction Stop; Write-Host ('      Espacio libre en C: ' + [math]::Round($d.Free/1GB,1) + ' GB') } catch { Write-Host '      No se pudo leer el espacio en disco.' }"
where winget >nul 2>&1
if errorlevel 1 (
    echo       [ AVISO ] winget no esta disponible en esta sesion.
) else (
    echo       [ OK ] winget disponible.
)
echo       [ OK ] Verificacion terminada.
exit /b 0

:F_PREPAPPS
where winget >nul 2>&1
if errorlevel 1 (
    echo       [ ERROR ] winget no esta disponible en este equipo o sesion.
    call :LOG "winget no disponible"
    exit /b 1
)
echo       Instalando Microsoft Teams...
winget install --id Microsoft.Teams --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
call :WG_RESULT "Teams"
echo       Instalando Zoom...
winget install --id Zoom.Zoom --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
call :WG_RESULT "Zoom"
echo       Actualizando aplicaciones instaladas...
call :F_WINGET_UPGRADE
exit /b 0

:F_WINGET_UPGRADE
where winget >nul 2>&1
if errorlevel 1 (
    echo       [ ERROR ] winget no esta disponible en este equipo o sesion.
    call :LOG "winget no disponible"
    exit /b 1
)
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
call :WG_RESULT "Actualizacion de aplicaciones"
exit /b 0

:F_HPIA
set "HPIA_URL=https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-%HPIA_VER%.exe"
set "HPIA_DIR=%TEMP%\HPIA"
set "HPIA_EXE=%HPIA_DIR%\hp-hpia-%HPIA_VER%.exe"
if not exist "%HPIA_DIR%\" mkdir "%HPIA_DIR%" >nul 2>&1
if exist "%HPIA_EXE%" del /q /f "%HPIA_EXE%" >nul 2>&1
echo       Descargando HP Image Assistant v%HPIA_VER% ...
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri $env:HPIA_URL -OutFile $env:HPIA_EXE -ErrorAction Stop; exit 0 } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 goto F_HPIA_FAIL
set "HPIA_SIZE=0"
for %%F in ("%HPIA_EXE%") do set "HPIA_SIZE=%%~zF"
if %HPIA_SIZE% LSS 1000000 goto F_HPIA_FAIL
echo       [ OK ] Descarga completada.
start "" "%HPIA_EXE%"
echo       [ OK ] Instalador lanzado. Sigue el asistente en pantalla.
call :LOG "HPIA %HPIA_VER% lanzado"
exit /b 0

:F_HPIA_FAIL
echo       [ ERROR ] No fue posible descargar HP Image Assistant v%HPIA_VER%.
echo                 Revisa conexion/proxy, o cambia HPIA_VER al inicio del script.
echo                 Abriendo la pagina oficial de descarga de HP...
start "" "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"
call :LOG "HPIA %HPIA_VER%: fallo la descarga"
exit /b 1

REM ------------------------------------------------------------
REM  Auditoria de software: crea la plantilla si no existe y
REM  compara los programas instalados contra la lista permitida.
REM ------------------------------------------------------------
:F_AUDITORIA
set "RUTA_LISTA=%~dp0programas_permitidos.txt"
if exist "%RUTA_LISTA%" goto F_AUD_RUN
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
    echo Foxit Reader PDF - Mac
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
echo   [ AVISO ] Se creo la plantilla de programas permitidos en:
echo             %RUTA_LISTA%
echo             Editala (un programa permitido por linea), guarda los
echo             cambios y vuelve a ejecutar la auditoria.
call :LOG "Plantilla programas_permitidos.txt creada"
exit /b 1

:F_AUD_RUN
call :VERIFICAR_PERMITIDOS
exit /b 0

REM ------------------------------------------------------------
REM  Subrutina: compara programas instalados con la lista permitida
REM ------------------------------------------------------------
:VERIFICAR_PERMITIDOS
echo   Comparando programas instalados contra la lista permitida...
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
exit /b 0
