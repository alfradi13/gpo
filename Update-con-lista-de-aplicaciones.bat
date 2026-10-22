@echo off
setlocal EnableExtensions DisableDelayedExpansion
title [ SOPORTE CORPORATIVO ] Mantenimiento y Diagnostico HP/Windows
color 0F

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
choice /c SN /t 10 /d S /m "      Ejecutar ahora. S=Si, N=Omitir. Continua solo en 10 s"
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
echo   [ SEGURIDAD ]
echo    1.  Habilitar Firewall de Windows - 3 perfiles
echo    2.  Habilitar Windows Defender - tiempo real
echo    3.  Actualizar firmas de malware de Defender
echo.
echo   [ ACTUALIZACIONES Y GPO ]
echo    4.  Buscar actualizaciones de Windows - Windows Update
echo    5.  Actualizar apps instaladas - Winget
echo    15. Forzar actualizacion de politicas GPO - ventana aislada
echo    21. Verificar politicas GPO aplicadas - ventana aislada
echo    22. Limpiar cache GPO y reiniciar - ventana aislada, con confirmacion
echo.
echo   [ RENDIMIENTO / ALMACENAMIENTO ]
echo    6.  Vaciar TEMP usuario/sistema y cache de Windows Update
echo    7.  Vaciar Papelera de Reciclaje
echo    8.  Abrir Liberador de espacio en disco - Cleanmgr
echo    9.  Ver Top 15 procesos por CPU y Memoria
echo    10. Abrir Admin. de tareas - Apps de arranque
echo    16. Verificar y reiniciar servicios de Windows Update
echo.
echo   [ DIAGNOSTICO / SOPORTE ]
echo    12. Abrir carpeta de Minidumps
echo    13. Descargar y ejecutar HP Image Assistant - HPIA
echo    14. Abrir guia oficial de WinDbg / !analyze -v
echo    17. Reiniciar el equipo - aviso de 30 seg
echo    23. Obtener direccion MAC del equipo
echo.
echo   [ UTILIDADES / VERIFICACION ]
echo    18. Verificar programas instalados vs. lista permitida
echo    19. Re-verificar Absolute / ActivTrack
echo.
echo   [ MANTENIMIENTO COMPLETO ]
echo    20. EJECUTAR TODOS LOS PUNTOS AUTOMATICAMENTE
echo.
echo    0. SALIR
echo +================================================================+
set "opcion="
set /p "opcion=  Seleccione una opcion: "
if not defined opcion goto MENU
set "opcion=%opcion:"=%"

if "%opcion%"=="1"  goto FIREWALL
if "%opcion%"=="2"  goto DEFENDER
if "%opcion%"=="3"  goto FIRMAS
if "%opcion%"=="4"  goto WINDOWSUPDATE
if "%opcion%"=="5"  goto WINGET
if "%opcion%"=="6"  goto TEMP
if "%opcion%"=="7"  goto PAPELERA
if "%opcion%"=="8"  goto CLEANMGR
if "%opcion%"=="9"  goto TOPPROC
if "%opcion%"=="10" goto STARTUPAPPS
if "%opcion%"=="12" goto MINIDUMP
if "%opcion%"=="13" goto HPIA
if "%opcion%"=="14" goto WINDBG
if "%opcion%"=="15" goto GPUPDATE
if "%opcion%"=="16" goto WUSERVICE
if "%opcion%"=="17" goto REBOOT
if "%opcion%"=="18" goto PROGRAMAS
if "%opcion%"=="19" goto CHECKABSOLUTE
if "%opcion%"=="20" goto TODO
if "%opcion%"=="21" goto VERIFYGPO
if "%opcion%"=="22" goto CLEANGPO
if "%opcion%"=="23" goto GETMAC
if "%opcion%"=="0"  goto FIN

echo.
echo  Opcion invalida.
timeout /t 2 >nul
goto MENU

REM ============================================================
REM  OPCIONES DEL MENU  - cada una usa las subrutinas F_ del final
REM ============================================================
:FIREWALL
call :HEADER "HABILITANDO FIREWALL DE WINDOWS"
call :F_FIREWALL
echo.
netsh advfirewall show allprofiles state
pause
goto MENU

:DEFENDER
call :HEADER "HABILITANDO WINDOWS DEFENDER"
call :F_DEFENDER
pause
goto MENU

:FIRMAS
call :HEADER "ACTUALIZANDO FIRMAS DE WINDOWS DEFENDER"
echo   Descargando e instalando firmas de malware...
call :F_FIRMAS
pause
goto MENU

:WINDOWSUPDATE
call :HEADER "BUSCANDO ACTUALIZACIONES DE WINDOWS"
call :F_WUSEARCH
call :F_OPENWU
pause
goto MENU

:WINGET
call :HEADER "ACTUALIZANDO APLICACIONES CON WINGET"
echo   Esto puede tardar varios minutos.
echo.
call :F_WINGET_UPGRADE
pause
goto MENU

:TEMP
call :HEADER "LIMPIANDO ARCHIVOS TEMPORALES"
call :F_TEMP
pause
goto MENU

:PAPELERA
call :HEADER "VACIANDO PAPELERA DE RECICLAJE"
call :F_PAPELERA
pause
goto MENU

:CLEANMGR
call :HEADER "ABRIENDO LIBERADOR DE ESPACIO EN DISCO"
where cleanmgr >nul 2>&1
if errorlevel 1 goto CLEANMGR_ALT
start "" cleanmgr
echo   [ INFO ] Selecciona la unidad y categorias en la ventana abierta.
pause
goto MENU

:CLEANMGR_ALT
echo   [ AVISO ] cleanmgr no existe en este equipo. Abriendo Almacenamiento de Windows...
start "" ms-settings:storagesense
pause
goto MENU

:TOPPROC
call :HEADER "TOP 15 PROCESOS POR CPU Y MEMORIA"
call :F_TOPPROC
pause
goto MENU

:STARTUPAPPS
call :HEADER "ABRIENDO ADMINISTRADOR DE TAREAS"
start "" taskmgr
echo   [ INFO ] Ve a la pestana Inicio para deshabilitar apps de arranque.
pause
goto MENU

:MINIDUMP
call :HEADER "ABRIENDO CARPETA MINIDUMPS"
call :F_MINIDUMP
pause
goto MENU

:HPIA
call :HEADER "HP IMAGE ASSISTANT"
call :F_HPIA
pause
goto MENU

:WINDBG
call :HEADER "DOCUMENTACION DE WINDBG"
echo   Abriendo documentacion oficial en el navegador...
start "" "https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze"
echo.
echo   [ INFO ] Consulta la documentacion para analizar minidumps con !analyze -v
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

:GETMAC
call :HEADER "DIRECCION MAC DEL EQUIPO"
getmac /v /fo table
echo.
pause
goto MENU

:WUSERVICE
call :HEADER "VERIFICANDO Y REINICIANDO SERVICIOS DE WINDOWS UPDATE"
call :F_WUSERVICE
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

REM ============================================================
REM  18 - AUDITORIA DE SOFTWARE (Programas instalados vs. lista permitida)
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

:REBOOT
cls
color 0E
call :HEADER "REINICIANDO EL EQUIPO"
echo   El equipo se reiniciara en 30 segundos.
echo   Guarda tu trabajo antes de continuar.
echo   Para cancelar despues: shutdown /a
echo.
set "confirm="
set /p "confirm=  Escribe REINICIAR para confirmar: "
if not defined confirm goto REBOOT_CANCEL
set "confirm=%confirm:"=%"
if /i not "%confirm%"=="REINICIAR" goto REBOOT_CANCEL
shutdown /r /t 30 /c "Reinicio programado por Soporte Corporativo - Guarda tu trabajo"
if errorlevel 1 (
    echo.
    echo   [ ERROR ] No se pudo programar el reinicio.
    call :LOG "Reinicio: ERROR"
) else (
    echo.
    echo   [ OK ] Reinicio programado. Tienes 30 segundos para guardar trabajo.
    echo          Para cancelar: shutdown /a
    call :LOG "Reinicio programado"
)
pause
color 0F
goto MENU

:REBOOT_CANCEL
echo.
echo   [ CANCELADO ] Operacion cancelada por el usuario.
pause
color 0F
goto MENU

REM ============================================================
REM  20 - MANTENIMIENTO COMPLETO
REM ============================================================
:TODO
color 0A
set "ERRS=0"
call :HEADER "EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO"
echo   Notas:
echo    - Cleanmgr no se incluye: requiere interaccion manual.
echo    - Winget y GPUPDATE se abren en ventanas aisladas.
echo    - El resultado queda registrado en: %LOGFILE%
echo.
call :LOG "--- Mantenimiento completo: inicio ---"

echo  [ 1/12] Habilitando Firewall de Windows...
call :F_FIREWALL || set /a ERRS+=1

echo  [ 2/12] Habilitando Windows Defender...
call :F_DEFENDER || set /a ERRS+=1

echo  [ 3/12] Actualizando firmas de Windows Defender...
call :F_FIRMAS || set /a ERRS+=1

echo  [ 4/12] Limpiando temporales y cache de Windows Update...
call :F_TEMP

echo  [ 5/12] Vaciando Papelera de Reciclaje...
call :F_PAPELERA

echo  [ 6/12] Reiniciando servicios de Windows Update...
call :F_WUSERVICE || set /a ERRS+=1

echo  [ 7/12] Top 15 procesos por CPU y Memoria...
call :F_TOPPROC

echo  [ 8/12] Revisando carpeta Minidumps...
call :F_MINIDUMP

echo  [ 9/12] Abriendo configuracion de Windows Update...
call :F_OPENWU

echo  [10/12] Iniciando Winget en ventana aislada...
call :F_LAUNCH WINGET "WINGET - Actualizando Aplicaciones"

echo  [11/12] Iniciando GPUPDATE en ventana aislada...
call :F_LAUNCH GPUPDATE "GPUPDATE - Actualizacion de Politicas"

echo  [12/12] HP Image Assistant...
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
echo   Directivas esperadas, se verifican con la opcion 21:
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

:T_CLEANGPO
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
shutdown /r /t 60 /c "Limpieza GPO - Soporte Corporativo"
if errorlevel 1 (
    echo   [ ERROR ] No se pudo programar el reinicio. Reinicia el equipo manualmente.
) else (
    echo   [ OK ] Reinicio programado en 60 segundos. Cancela con: shutdown /a
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

:SVC_STATUS
sc query %~1 2>nul | findstr /i /c:"RUNNING" >nul
if errorlevel 1 (
    echo       %~1 : DETENIDO
) else (
    echo       %~1 : EN EJECUCION
)
sc qc %~1 2>nul | findstr /i /c:"DISABLED" >nul
if not errorlevel 1 echo       [ AVISO ] %~1 esta DESHABILITADO, posible GPO.
exit /b 0

:CLEAN_DIR
REM  Borra el contenido de una carpeta, con proteccion contra rutas vacias o raiz
if "%~1"=="" exit /b 1
if /i "%~1"=="%SystemDrive%" exit /b 1
if /i "%~1"=="%SystemDrive%\" exit /b 1
if not exist "%~1\" exit /b 1
del /q /f /s "%~1\*" >nul 2>&1
for /d %%D in ("%~1\*") do rd /s /q "%%D" >nul 2>&1
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

:F_FIREWALL
netsh advfirewall set allprofiles state on >nul 2>&1
if errorlevel 1 (
    echo       [ ERROR ] No se pudo habilitar el Firewall. Puede estar controlado por GPO.
    call :LOG "Firewall: ERROR"
    exit /b 1
)
echo       [ OK ] Firewall habilitado en Dominio, Privado y Publico.
call :LOG "Firewall: OK"
exit /b 0

:F_DEFENDER
powershell -NoProfile -Command "try { Set-MpPreference -DisableRealtimeMonitoring $false -DisableIOAVProtection $false -DisableBehaviorMonitoring $false -ErrorAction Stop; $s = Get-MpComputerStatus -ErrorAction Stop; Write-Host ('      Proteccion en tiempo real : ' + $s.RealTimeProtectionEnabled); Write-Host ('      Antivirus habilitado      : ' + $s.AntivirusEnabled); Write-Host ('      Firmas actualizadas el    : ' + $s.AntivirusSignatureLastUpdated); if ($s.RealTimeProtectionEnabled) { exit 0 } else { exit 2 } } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 2 (
    echo       [ AVISO ] El comando se ejecuto pero el tiempo real sigue desactivado.
    echo                 Puede haber Tamper Protection, una GPO o un antivirus de terceros.
    call :LOG "Defender: tiempo real sigue desactivado"
    exit /b 1
)
if errorlevel 1 (
    echo       [ ERROR ] No se pudo configurar Windows Defender.
    call :LOG "Defender: ERROR"
    exit /b 1
)
echo       [ OK ] Windows Defender habilitado.
call :LOG "Defender: OK"
exit /b 0

:F_FIRMAS
powershell -NoProfile -Command "try { Update-MpSignature -ErrorAction Stop; exit 0 } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 (
    echo       [ ERROR ] No se pudieron actualizar las firmas.
    call :LOG "Firmas Defender: ERROR"
    exit /b 1
)
echo       [ OK ] Firmas de Defender actualizadas.
call :LOG "Firmas Defender: OK"
exit /b 0

:F_WUSEARCH
echo   Buscando actualizaciones pendientes, puede tardar varios minutos...
powershell -NoProfile -Command "try { $s = New-Object -ComObject Microsoft.Update.Session; $r = $s.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0'); if ($r.Updates.Count -eq 0) { Write-Host '      No hay actualizaciones pendientes.' } else { Write-Host ('      Actualizaciones pendientes: ' + $r.Updates.Count); foreach ($u in $r.Updates) { Write-Host ('       - ' + $u.Title) } }; exit 0 } catch { Write-Host ('      ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 (
    echo       [ AVISO ] No se pudo consultar el servicio. Usa la ventana de Windows Update.
    call :LOG "Busqueda WU: ERROR"
    exit /b 1
)
call :LOG "Busqueda WU: OK"
exit /b 0

:F_OPENWU
start "" ms-settings:windowsupdate
echo       [ OK ] Configuracion de Windows Update abierta.
exit /b 0

:F_TEMP
echo       Limpiando temporales del usuario...
call :CLEAN_DIR "%TEMP%"
if errorlevel 1 (echo       [ AVISO ] No se pudo acceder a TEMP del usuario.) else (echo       [ OK ] Temporales de usuario limpiados.)
echo       Limpiando temporales del sistema...
call :CLEAN_DIR "%SystemRoot%\Temp"
if errorlevel 1 (echo       [ AVISO ] No se pudo acceder a TEMP del sistema.) else (echo       [ OK ] Temporales de sistema limpiados.)
echo       Limpiando cache de Windows Update...
call :F_WUCACHE
echo       [ INFO ] Los archivos en uso se omiten.
call :LOG "Limpieza de temporales ejecutada"
exit /b 0

:F_WUCACHE
set "WU_RUN="
sc query wuauserv 2>nul | findstr /i /c:"RUNNING" >nul && set "WU_RUN=1"
net stop wuauserv /y >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
if not exist "%SystemRoot%\SoftwareDistribution\Download\" mkdir "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
if defined WU_RUN net start wuauserv >nul 2>&1
echo       [ OK ] Cache de Windows Update limpiada.
exit /b 0

:F_PAPELERA
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo       [ OK ] Papelera de reciclaje vaciada.
call :LOG "Papelera vaciada"
exit /b 0

:F_TOPPROC
echo   --- Top 15 por CPU ---
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
echo   --- Top 15 por Memoria ---
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
exit /b 0

:F_MINIDUMP
if exist "%SystemRoot%\MEMORY.DMP" echo       [ INFO ] Existe un volcado completo: %SystemRoot%\MEMORY.DMP
if not exist "%SystemRoot%\Minidump\" goto F_MINIDUMP_NONE
dir /b "%SystemRoot%\Minidump\*.dmp" >nul 2>&1
if errorlevel 1 goto F_MINIDUMP_EMPTY
start "" "%SystemRoot%\Minidump\"
echo       [ OK ] Carpeta de minidumps abierta.
exit /b 0

:F_MINIDUMP_EMPTY
echo       [ INFO ] La carpeta existe pero no contiene archivos .dmp.
exit /b 0

:F_MINIDUMP_NONE
echo       [ INFO ] No existe %SystemRoot%\Minidump
echo                Indica que no hay volcados de memoria de errores criticos.
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

:F_WUSERVICE
echo   Estado inicial:
call :SVC_STATUS wuauserv
call :SVC_STATUS bits
call :SVC_STATUS cryptsvc
echo.
echo   Reiniciando servicios...
net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
net start cryptsvc >nul 2>&1
echo.
echo   Estado final:
call :SVC_STATUS wuauserv
call :SVC_STATUS bits
call :SVC_STATUS cryptsvc
sc query wuauserv 2>nul | findstr /i /c:"RUNNING" >nul
if errorlevel 1 (
    echo       [ AVISO ] wuauserv no quedo en ejecucion. Puede iniciarse bajo demanda o estar bloqueado por GPO.
    call :LOG "Servicios WU: wuauserv detenido"
    exit /b 1
)
echo       [ OK ] Servicios de Windows Update reiniciados.
call :LOG "Servicios WU: OK"
exit /b 0

REM ------------------------------------------------------------
REM  Subrutina: compara programas instalados con la lista permitida
REM  (modulo tomado de pruebas (1).bat)
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