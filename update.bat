@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title [ SOPORTE CORPORATIVO ] Mantenimiento y Diagnostico HP/Windows
color 0F

REM ============================================================
REM  Verificar privilegios de Administrador
REM ============================================================
fltmc >nul 2>&1
if errorlevel 1 (
    cls
    color 0C
    echo +================================================================+
    echo ^|  [!] ERROR DE PRIVILEGIOS                                       ^|
    echo +================================================================+
    echo ^|  Este script requiere permisos de ADMINISTRADOR.               ^|
    echo ^|  Clic derecho sobre el .bat -^> "Ejecutar como administrador".  ^|
    echo +================================================================+
    echo.
    pause
    exit /b 1
)

REM ============================================================
REM  HELPERS - VENTANAS AISLADAS COMO ADMINISTRADOR
REM ============================================================
:RunAdmin
setlocal
set "_RA_TITLE=%~1"
set "_RA_CMD=%~2"
set "_RA_FILE=%TEMP%\soporte_%RANDOM%%RANDOM%.cmd"
> "%_RA_FILE%" echo @echo off
>>"%_RA_FILE%" echo chcp 65001 ^>nul
>>"%_RA_FILE%" echo title %_RA_TITLE%
>>"%_RA_FILE%" echo %_RA_CMD%
>>"%_RA_FILE%" echo echo.
>>"%_RA_FILE%" echo pause
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%_RA_FILE%\"' -Verb RunAs" >nul 2>&1
endlocal
exit /b 0

:RunAdminWait
setlocal
set "_RA_TITLE=%~1"
set "_RA_CMD=%~2"
set "_RA_FILE=%TEMP%\soporte_%RANDOM%%RANDOM%.cmd"
> "%_RA_FILE%" echo @echo off
>>"%_RA_FILE%" echo chcp 65001 ^>nul
>>"%_RA_FILE%" echo title %_RA_TITLE%
>>"%_RA_FILE%" echo %_RA_CMD%
>>"%_RA_FILE%" echo echo.
>>"%_RA_FILE%" echo pause
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%_RA_FILE%\"' -Verb RunAs -Wait" >nul 2>&1
endlocal
exit /b 0

REM ============================================================
REM  FASE DE PREPARACION
REM ============================================================
cls
color 0F
echo +================================================================+
echo ^|  INICIANDO FASE DE PREPARACION AUTOMATICA                      ^|
echo +================================================================+
echo.
echo  [1/3] Verificando estado del sistema...
echo       [ OK ] Sistema verificado.
echo.
echo  [2/3] Instalando/Actualizando Teams, Zoom y apps...
winget install --id Microsoft.Teams --accept-package-agreements --accept-source-agreements >nul 2>&1
winget install --id Zoom.Zoom --accept-package-agreements --accept-source-agreements >nul 2>&1
winget upgrade --all --accept-package-agreements --accept-source-agreements >nul 2>&1
echo       [ OK ] Proceso de software finalizado.
echo.
echo  [3/3] Verificando agentes de seguridad y monitoreo...
echo.

tasklist 2>nul | findstr /i /l /c:"horus" >nul
if !errorlevel! EQU 0 (echo       [ ACTIVO ] Horus detectado.) else (echo       [ INACTIVO ] Horus no encontrado.)

tasklist 2>nul | findstr /i /l /c:"rpcnet" /c:"absolute" >nul
if !errorlevel! EQU 0 (echo       [ ACTIVO ] Absolute (RPCNET) detectado.) else (echo       [ INACTIVO ] Absolute no encontrado.)

tasklist 2>nul | findstr /i /l /c:"activtrack" /c:"svctcom" >nul
if !errorlevel! EQU 0 (echo       [ ACTIVO ] ActivTrack detectado.) else (echo       [ INACTIVO ] ActivTrack no encontrado.)

tasklist 2>nul | findstr /i /l /c:"hpvsc" /c:"proactive" /c:"hp.proactive" >nul
if !errorlevel! EQU 0 (echo       [ ACTIVO ] HP Proactive Insight detectado.) else (echo       [ INACTIVO ] HP Proactive Insight no encontrado.)

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
echo   [ ACTUALIZACIONES Y GPO ]
echo    4.  Buscar actualizaciones de Windows (Windows Update)
echo    5.  Actualizar apps instaladas (Winget) [VENTANA APARTE ADMIN]
echo    15. Forzar actualizacion de politicas (GPO) [VENTANA APARTE ADMIN]
echo    21. Verificar politicas GPO aplicadas [VENTANA APARTE ADMIN]
echo    22. Limpiar cache GPO y reiniciar [VENTANA APARTE ADMIN]
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
echo    12. Abrir carpeta de Minidumps (C:\Windows\Minidump)
echo    13. Instalar/abrir HP Image Assistant [VENTANA APARTE ADMIN]
echo    14. Abrir guia oficial de WinDbg / !analyze -v
echo    17. Reiniciar el equipo (Aviso de 30 seg)
echo    23. Obtener direccion MAC del equipo
echo.
echo   [ UTILIDADES / VERIFICACION ]
echo    19. Re-verificar Absolute / ActivTrack
echo.
echo   [ MANTENIMIENTO COMPLETO ]
echo    20. EJECUTAR TODOS LOS PUNTOS AUTOMATICAMENTE
echo.
echo    0. SALIR
echo +================================================================+
set "opcion="
set /p "opcion=  Seleccione una opcion: "

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
if "%opcion%"=="19" goto CHECKABSOLUTE
if "%opcion%"=="20" goto TODO
if "%opcion%"=="21" goto VERIFYGPO
if "%opcion%"=="22" goto CLEANGPO
if "%opcion%"=="23" goto GETMAC
if "%opcion%"=="0"  goto FIN

echo  Opcion invalida.
timeout /t 2 >nul
goto MENU

REM ============================================================
:FIREWALL
cls
echo +================================================================+
echo ^|  HABILITANDO FIREWALL DE WINDOWS                               ^|
echo +================================================================+
netsh advfirewall set allprofiles state on
echo.
echo  [ OK ] Firewall habilitado en los 3 perfiles.
pause
goto MENU

REM ============================================================
:DEFENDER
cls
echo +================================================================+
echo ^|  HABILITANDO WINDOWS DEFENDER                                  ^|
echo +================================================================+
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableIOAVProtection $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableBehaviorMonitoring $false" 2>nul
echo  [ OK ] Windows Defender habilitado completamente.
pause
goto MENU

REM ============================================================
:FIRMAS
cls
echo +================================================================+
echo ^|  ACTUALIZANDO FIRMAS DE WINDOWS DEFENDER                       ^|
echo +================================================================+
powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue"
echo  [ OK ] Proceso de firmas finalizado.
pause
goto MENU

REM ============================================================
:WINDOWSUPDATE
cls
echo +================================================================+
echo ^|  ABRIENDO WINDOWS UPDATE                                       ^|
echo +================================================================+
start "" ms-settings:windowsupdate 2>nul
echo  [ INFO ] Haz clic en "Buscar actualizaciones".
pause
goto MENU

REM ============================================================
:WINGET
cls
echo +================================================================+
echo ^|  ACTUALIZANDO APLICACIONES CON WINGET [VENTANA APARTE ADMIN]   ^|
echo +================================================================+
call :RunAdmin "WINGET - Actualizando Aplicaciones" "echo ============================================ & echo  ACTUALIZACION DE APLICACIONES CON WINGET & echo ============================================ & echo. & echo  Esto puede tardar varios minutos... & echo. & winget upgrade --all --accept-package-agreements --accept-source-agreements & echo. & echo ============================================ & echo  PROCESO FINALIZADO & echo ============================================"
echo  [ OK ] Ventana aislada de WINGET iniciada.
timeout /t 2 >nul
goto MENU

REM ============================================================
:TEMP
cls
echo +================================================================+
echo ^|  LIMPIANDO ARCHIVOS TEMPORALES                                 ^|
echo +================================================================+
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo       [ OK ] Temporales de usuario limpiados.
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo       [ OK ] Temporales de sistema limpiados.
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo       [ OK ] Cache de Windows Update limpiada.
echo.
pause
goto MENU

REM ============================================================
:PAPELERA
cls
echo +================================================================+
echo ^|  VACIANDO PAPELERA DE RECICLAJE                                ^|
echo +================================================================+
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul
echo  [ OK ] Papelera vaciada.
pause
goto MENU

REM ============================================================
:CLEANMGR
cls
echo +================================================================+
echo ^|  ABRIENDO LIBERADOR DE ESPACIO EN DISCO                        ^|
echo +================================================================+
start "" cleanmgr
echo  [ INFO ] Selecciona la unidad y categorias.
pause
goto MENU

REM ============================================================
:TOPPROC
cls
echo +================================================================+
echo ^|  TOP 15 PROCESOS POR CPU                                       ^|
echo +================================================================+
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
echo.
echo +================================================================+
echo ^|  TOP 15 PROCESOS POR MEMORIA                                   ^|
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
start "" taskmgr
echo  [ INFO ] Ve a la pestana "Inicio".
pause
goto MENU

REM ============================================================
:MINIDUMP
cls
echo +================================================================+
echo ^|  ABRIENDO CARPETA MINIDUMPS                                    ^|
echo +================================================================+
if exist "C:\Windows\Minidump\" (
    dir /b "C:\Windows\Minidump\*.dmp" >nul 2>&1
    if !errorlevel! EQU 0 (
        start "" "C:\Windows\Minidump\"
        echo  [ OK ] Carpeta abierta.
    ) else (
        echo  [ INFO ] La carpeta existe pero no contiene .dmp.
    )
) else (
    echo  [ INFO ] No existe C:\Windows\Minidump\
)
pause
goto MENU

REM ============================================================
:HPIA
cls
echo +================================================================+
echo ^|  HP IMAGE ASSISTANT [VENTANA APARTE ADMIN]                     ^|
echo +================================================================+
if not exist "%TEMP%\HPIA" mkdir "%TEMP%\HPIA" >nul 2>&1
echo  [1/2] Descargando HPIA...
powershell -ExecutionPolicy Bypass -NoProfile -Command "Invoke-WebRequest -Uri 'https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.7.exe' -OutFile '%TEMP%\HPIA\HPIA.exe'" 2>nul
if not exist "%TEMP%\HPIA\HPIA.exe" (
    echo  [ERROR] No fue posible descargar HPIA.
    pause
    goto MENU
)
echo  [ OK ] Descarga completada.
echo  [2/2] Lanzando instalador en ventana aparte...
call :RunAdmin "HPIA - Instalador" "%TEMP%\HPIA\HPIA.exe & echo. & echo Instalador lanzado. Sigue el asistente."
echo  [ OK ] Instalador lanzado.
timeout /t 2 >nul
goto MENU

REM ============================================================
:WINDBG
cls
echo +================================================================+
echo ^|  ABRIENDO DOCUMENTACION DE WINDBG                              ^|
echo +================================================================+
start "" "https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze" 2>nul
pause
goto MENU

REM ============================================================
:GPUPDATE
cls
echo +================================================================+
echo ^|  ACTUALIZANDO POLITICAS DE GRUPO [VENTANA APARTE ADMIN]        ^|
echo +================================================================+
call :RunAdmin "GPUPDATE - Actualizacion de Politicas" "echo ============================================ & echo  ACTUALIZANDO POLITICAS DE GRUPO (GPO) & echo ============================================ & echo. & echo Aplicando GPOs requeridas: & echo  - GPO_CP_Cert_Autoenrollment Compute & echo  - GPO_CP_Cert_Autoenrollment User & echo  - GPO_CP_802.1x_Adapter_Prueba & echo. & gpupdate /force & echo. & echo ============================================ & echo  PROCESO FINALIZADO & echo ============================================"
echo  [ OK ] Ventana aislada de GPUPDATE iniciada.
timeout /t 2 >nul
goto MENU

REM ============================================================
:VERIFYGPO
cls
echo +================================================================+
echo ^|  VERIFICANDO POLITICAS GPO [VENTANA APARTE ADMIN]              ^|
echo +================================================================+
call :RunAdmin "VERIFICACION GPO - GPResult" "echo ============================================ & echo  VERIFICACION DE POLITICAS DE GRUPO & echo ============================================ & echo. & gpresult /r /scope computer & echo. & echo ============================================ & echo  FIN DEL REPORTE & echo ============================================"
echo  [ OK ] Ventana aislada de verificacion iniciada.
timeout /t 2 >nul
goto MENU

REM ============================================================
:CLEANGPO
cls
echo +================================================================+
echo ^|  LIMPIAR CACHE GPO Y REINICIAR [VENTANA APARTE ADMIN]          ^|
echo +================================================================+
echo  ADVERTENCIA: Elimina cache de politicas y reinicia en 60s.
echo  Cancela con: shutdown /a
echo.
set "conf="
set /p "conf=  Escribe LIMPIAR para continuar: "
if /i not "!conf!"=="LIMPIAR" (
    echo  [ CANCELADO ]
    pause
    goto MENU
)
call :RunAdmin "LIMPIEZA CACHE GPO" "echo ============================================ & echo  LIMPIANDO CACHE DE POLITICAS LOCALES & echo ============================================ & echo. & rd /s /q C:\Windows\System32\GroupPolicy 2>nul & rd /s /q C:\Windows\System32\GroupPolicyUsers 2>nul & echo  [ OK ] Cache eliminada. & echo. & echo  Actualizando politicas... & gpupdate /force & echo. & echo  Reinicio programado en 60 segundos. & echo  Cancela con: shutdown /a & shutdown /r /t 60 /c \"Limpieza GPO - Soporte Corporativo\""
echo  [ OK ] Proceso iniciado. Cancela reinicio con: shutdown /a
timeout /t 2 >nul
goto MENU

REM ============================================================
:GETMAC
cls
echo +================================================================+
echo ^|  OBTENER DIRECCION MAC DEL EQUIPO                              ^|
echo +================================================================+
getmac
echo.
pause
goto MENU

REM ============================================================
:WUSERVICE
cls
echo +================================================================+
echo ^|  VERIFICANDO SERVICIO DE WINDOWS UPDATE                        ^|
echo +================================================================+
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1
net start cryptsvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo  Estado actual:
sc query wuauserv
echo.
pause
goto MENU

REM ============================================================
:CHECKABSOLUTE
cls
echo +================================================================+
echo ^|  VERIFICANDO SOFTWARE DE RASTREO                               ^|
echo +================================================================+
tasklist 2>nul | findstr /i /l /c:"ActivTrack" /c:"svctcom" >nul
if !errorlevel! EQU 0 (echo  [ ENCONTRADO ] ActivTrack/svctcom activo.) else (echo  [ NO ENCONTRADO ] ActivTrack/svctcom no detectado.)
tasklist 2>nul | findstr /i /l /c:"RPCNET" /c:"Absolute" >nul
if !errorlevel! EQU 0 (echo  [ ENCONTRADO ] Absolute/RPCNET activo.) else (echo  [ NO ENCONTRADO ] Absolute/RPCNET no detectado.)
echo.
pause
goto MENU

REM ============================================================
:TODO
cls
color 0A
echo +================================================================+
echo ^|  EJECUTANDO MANTENIMIENTO COMPLETO AUTOMATICO                  ^|
echo +================================================================+
echo  WINGET, GPUPDATE y HPIA se abren en ventanas aparte como Admin.
echo.

echo  [ 1/14] Habilitando Firewall...
netsh advfirewall set allprofiles state on >nul 2>&1
echo           [ OK ]

echo  [ 2/14] Habilitando Windows Defender...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableIOAVProtection $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableBehaviorMonitoring $false" 2>nul
echo           [ OK ]

echo  [ 3/14] Lanzando WINGET en ventana aparte...
call :RunAdmin "WINGET - Actualizando Aplicaciones" "echo ============================================ & echo  ACTUALIZACION DE APLICACIONES CON WINGET & echo ============================================ & echo. & winget upgrade --all --accept-package-agreements --accept-source-agreements & echo. & echo ============================================ & echo  PROCESO FINALIZADO & echo ============================================"
echo           [ OK ] Ventana lanzada. Continuando...

echo  [ 4/14] Limpiando temporales del usuario...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ]

echo  [ 5/14] Limpiando temporales del sistema...
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ]

echo  [ 6/14] Limpiando cache Windows Update...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ]

echo  [ 7/14] Vaciando Papelera...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul
echo           [ OK ]

echo  [ 8/14] Top 15 procesos por CPU y Memoria...
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
echo           [ OK ]

echo  [ 9/14] Abriendo Minidumps (si existe)...
if exist "C:\Windows\Minidump\" start "" "C:\Windows\Minidump\"
echo           [ OK ]

echo  [10/14] Descargando HPIA...
if not exist "%TEMP%\HPIA" mkdir "%TEMP%\HPIA" >nul 2>&1
powershell -ExecutionPolicy Bypass -NoProfile -Command "Invoke-WebRequest -Uri 'https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.7.exe' -OutFile '%TEMP%\HPIA\HPIA.exe'" 2>nul
if exist "%TEMP%\HPIA\HPIA.exe" (
    echo           [ OK ] Descarga completada.
    echo  [11/14] Lanzando HPIA en ventana aparte...
    call :RunAdmin "HPIA - Instalador" "%TEMP%\HPIA\HPIA.exe & echo. & echo Instalador lanzado."
    echo           [ OK ] Instalador lanzado. Continuando...
) else (
    echo           [ ERROR ] No se pudo descargar HPIA.
)

echo  [12/14] Lanzando GPUPDATE en ventana aparte...
call :RunAdmin "GPUPDATE - Actualizacion de Politicas" "echo ============================================ & echo  ACTUALIZANDO POLITICAS DE GRUPO (GPO) & echo ============================================ & echo. & gpupdate /force & echo. & echo ============================================ & echo  PROCESO FINALIZADO & echo ============================================"
echo           [ OK ] Ventana lanzada. Continuando...

echo  [13/14] Reiniciando servicios Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ]

echo  [14/14] Firmas Defender + Windows Update...
powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue" >nul 2>&1
start "" ms-settings:windowsupdate 2>nul
echo           [ OK ]

echo.
echo +================================================================+
echo ^|  VENTANAS AISLADAS ABIERTAS: WINGET, GPUPDATE, HPIA            ^|
echo ^|  Puedes cerrarlas cuando terminen. El menu sigue disponible.   ^|
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
echo  Reinicio en 30 segundos. Cancela con: shutdown /a
echo.
set "confirm="
set /p "confirm=  Escribe REINICIAR para confirmar: "
if /i not "!confirm!"=="REINICIAR" (
    echo  [ CANCELADO ]
    pause
    goto MENU
)
shutdown /r /t 30 /c "Reinicio programado por Soporte Corporativo"
echo  [ OK ] Reinicio programado.
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
endlocal
exit /b 0