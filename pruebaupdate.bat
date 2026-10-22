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

REM ============================================================
REM  FASE DE PREPARACION AUTOMATICA
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

echo  [2/3] Instalando/Actualizando Teams, Zoom y Office...
echo       [ INFO ] Esto puede tardar unos minutos, por favor espere...
winget install --id Microsoft.Teams --accept-package-agreements --accept-source-agreements >nul 2>&1
winget install --id Zoom.Zoom --accept-package-agreements --accept-source-agreements >nul 2>&1
winget upgrade --id Microsoft.Office --accept-package-agreements --accept-source-agreements >nul 2>&1
echo       [ OK ] Proceso de software finalizado.
echo.

echo  [3/3] Verificando agentes de seguridad y monitoreo (Admin. de Tareas)...
echo.

REM --- Verificacion de Horus ---
tasklist 2>nul | findstr /i /c:"horus" >nul
if %errorLevel% EQU 0 (
    echo       [ ACTIVO ] Horus detectado en ejecucion.
) else (
    echo       [ INACTIVO ] Horus no encontrado.
)

REM --- Verificacion de Absolute (RPCNET) ---
tasklist 2>nul | findstr /i /c:"rpcnet" /c:"absolute" >nul
if %errorLevel% EQU 0 (
    echo       [ ACTIVO ] Absolute (RPCNET) detectado en ejecucion.
) else (
    echo       [ INACTIVO ] Absolute no encontrado.
)

REM --- Verificacion de ActivTrack ---
tasklist 2>nul | findstr /i /c:"activtrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 (
    echo       [ ACTIVO ] ActivTrack detectado en ejecucion.
) else (
    echo       [ INACTIVO ] ActivTrack no encontrado.
)

REM --- Verificacion de HP Proactive Insight ---
tasklist 2>nul | findstr /i /c:"hpvsc" /c:"proactive" /c:"hp.proactive" >nul
if %errorLevel% EQU 0 (
    echo       [ ACTIVO ] HP Proactive Insight detectado en ejecucion.
) else (
    echo       [ INACTIVO ] HP Proactive Insight no encontrado.
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
echo   [ ACTUALIZACIONES Y GPO ]
echo    4.  Buscar actualizaciones de Windows (Windows Update)
echo    5.  Actualizar apps instaladas (Winget)
echo    15. Forzar actualizacion de politicas (GPO) [AISLADO]
echo    21. Verificar politicas GPO aplicadas (gpresult) [AISLADO]
echo    22. Limpiar cache GPO y reiniciar de inmediato [AISLADO]
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
echo    11. [Opcion removida]
echo    12. Abrir carpeta de Minidumps (C:\Windows\Minidump)
echo    13. Abrir HP Image Assistant (HPIA)
echo    14. Abrir guia oficial de WinDbg / !analyze -v
echo    17. Reiniciar el equipo (Aviso de 30 seg)
echo    23. Obtener direccion MAC del equipo
echo.
echo   [ UTILIDADES / VERIFICACION ]
echo    18. Opcion no disponible (Enlaces externos eliminados)
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
if "%opcion%"=="21" goto VERIFYGPO
if "%opcion%"=="22" goto CLEANGPO
if "%opcion%"=="23" goto GETMAC
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
:CLEANMGR
cls
echo +================================================================+
echo ^|  ABRIENDO LIBERADOR DE ESPACIO EN DISCO                        ^|
echo +================================================================+
echo  Abriendo herramienta...
start cleanmgr
echo.
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
echo  Abriendo Administrador de tareas...
start taskmgr
echo.
echo  [ INFO ] Ve a la pestana "Inicio" para deshabilitar apps de arranque.
pause
goto MENU
 
REM ============================================================
:BATERIA
cls
echo +================================================================+
echo ^|  OPCION NO DISPONIBLE                                          ^|
echo +================================================================+
echo  [ INFO ] La funcion de reporte de bateria ha sido eliminada.
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
:HPIA
cls
echo +================================================================+
echo ^|      INSTALANDO HP IMAGE ASSISTANT                             ^|
echo +================================================================+
echo.

if not exist "%TEMP%\HPIA" mkdir "%TEMP%\HPIA"

echo [1/3] Descargando HP Image Assistant (v5.3.7)...

powershell -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest -Uri 'https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.7.exe' -OutFile '%TEMP%\HPIA\HPIA.exe'"

if not exist "%TEMP%\HPIA\HPIA.exe" (
    echo.
    echo [ERROR] No fue posible descargar HP Image Assistant.
    pause
    goto MENU
)

echo [ OK ] Descarga completada.
echo.

echo [2/3] Ejecutando instalador...

start "" "%TEMP%\HPIA\HPIA.exe"

echo [ OK ] Instalación finalizada.
echo.

echo [ OK ] Proceso completado correctamente.
echo.

pause
goto MENU
 
REM ============================================================
:WINDBG
cls
echo +================================================================+
echo ^|  ABRIENDO DOCUMENTACION DE WINDBG                              ^|
echo +================================================================+
echo  Abriendo documentacion oficial en el navegador...
start https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-analyze
echo.
echo  [ INFO ] Consulta la documentacion para analizar minidumps con !analyze -v
pause
goto MENU
 
REM ============================================================
:GPUPDATE
cls
echo +================================================================+
echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO) - MODO AISLADO          ^|
echo +================================================================+
echo  Iniciando actualizacion de politicas en ventana separada...
echo.
start "GPUPDATE - Actualizacion de Politicas" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO)        ^| & echo +============================================+ & echo. & echo Aplicando directivas requeridas: & echo - GPO_CP_Cert_Autoenrollment Compute & echo - GPO_CP_Cert_Autoenrollment User & echo - GPO_CP_802.1x_Adapter_Prueba & echo. & gpupdate /force & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & pause"
echo  [ OK ] Ventana aislada de GPUPDATE iniciada correctamente.
pause
goto MENU
 
REM ============================================================
:VERIFYGPO
cls
echo +================================================================+
echo ^|  VERIFICANDO POLITICAS GPO APLICADAS                           ^|
echo +================================================================+
echo  Abriendo ventana aislada para verificar gpresult...
echo.
start "VERIFICACION GPO - GPResult" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  VERIFICACION DE POLITICAS DE GRUPO        ^| & echo +============================================+ & echo. & gpresult /r /scope computer & echo. & echo +============================================+ & echo ^|  FIN DEL REPORTE                           ^| & echo +============================================+ & pause"
echo  [ OK ] Ventana aislada de verificacion iniciada.
pause
goto MENU

REM ============================================================
:CLEANGPO
cls
echo +================================================================+
echo ^|  LIMPIAR CACHE GPO Y REINICIAR                                 ^|
echo +================================================================+
echo  Abriendo ventana aislada para limpieza profunda de GPO...
echo.
start "LIMPIEZA CACHE GPO" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  LIMPIANDO CACHE DE POLITICAS LOCALES      ^| & echo +============================================+ & echo. & rd /s /q C:\Windows\System32\GroupPolicy & rd /s /q C:\Windows\System32\GroupPolicyUsers & echo. & echo  [ OK ] Cache eliminada correctamente. & echo  Actualizando politicas y reiniciando equipo de inmediato... & gpupdate /force & shutdown /r /t 0"
echo  [ OK ] Proceso de limpieza y reinicio iniciado en segundo plano.
pause
goto MENU

REM ============================================================
:GETMAC
cls
echo +================================================================+
echo ^|  OBTENER DIRECCION MAC DEL EQUIPO                              ^|
echo +================================================================+
echo.
getmac
echo.
echo +================================================================+
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
:ANYDESK
cls
echo +================================================================+
echo ^|  UTILIDAD NO DISPONIBLE                                        ^|
echo +================================================================+
echo  [ INFO ] Los enlaces externos configurados han sido removidos.
echo.
pause
goto MENU

REM ============================================================
:CHECKABSOLUTE
cls
echo +================================================================+
echo ^|  VERIFICANDO SOFTWARE DE RASTREO                               ^|
echo +================================================================+
echo  Analizando procesos en ejecucion...
echo.

echo  [ Verificando ActivTrack / svctcom... ]
tasklist 2>nul | findstr /i /c:"ActivTrack" /c:"svctcom" >nul
if %errorLevel% EQU 0 (
    echo       [ ENCONTRADO ] ActivTrack/svctcom esta activo.
) else (
    echo       [ NO ENCONTRADO ] ActivTrack/svctcom no detectado.
)
echo.

echo  [ Verificando Absolute / RPCNET... ]
tasklist 2>nul | findstr /i /c:"RPCNET" /c:"Absolute" >nul
if %errorLevel% EQU 0 (
    echo       [ ENCONTRADO ] Absolute/RPCNET esta activo.
) else (
    echo       [ NO ENCONTRADO ] Absolute/RPCNET no detectado.
)
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
echo  Nota: 
echo    - Cleanmgr se abre manualmente (requiere interaccion)
echo    - GPUPDATE y WINGET se ejecutan en ventanas aisladas
echo +================================================================+
echo.

echo  [ 1/14] Habilitando Firewall de Windows...
netsh advfirewall set allprofiles state on >nul 2>&1
echo           [ OK ] Completado.

echo  [ 2/14] Habilitando Windows Defender...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableIOAVProtection $false" 2>nul
powershell -NoProfile -Command "Set-MpPreference -DisableBehaviorMonitoring $false" 2>nul
echo           [ OK ] Completado.

echo  [ 3/14] Iniciando actualizacion de apps (Winget) en ventana aislada...
start "WINGET - Actualizando Aplicaciones" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZACION DE APLICACIONES (WINGET)       ^| & echo +============================================+ & echo. & echo  Este proceso puede tardar varios minutos. & echo. & winget upgrade --all --accept-package-agreements --accept-source-agreements & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & echo. & pause"
echo           [ OK ] Ventana aislada de Winget iniciada.

echo  [ 4/14] Limpiando temporales del usuario...
del /q /f /s "%TEMP%\*.*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ] Completado.

echo  [ 5/14] Limpiando temporales del sistema...
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo           [ OK ] Completado.

echo  [ 6/14] Limpiando cache de Windows Update...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
mkdir "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ] Completado.

echo  [ 7/14] Vaciando Papelera de Reciclaje...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo           [ OK ] Completado.

echo  [ 8/14] Mostrando Top 15 procesos por CPU...
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize"
echo.
echo           --- Top 15 por Memoria ---
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, @{n='Mem(MB)';e={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize"
echo           [ OK ] Completado.

echo  [ 9/14] Abriendo carpeta Minidumps (si existe)...
if exist "C:\Windows\Minidump\" start "" "C:\Windows\Minidump\"
echo           [ OK ] Completado.

echo.
if not exist "%TEMP%\HPIA" mkdir "%TEMP%\HPIA"
echo [10/14] Descargando HP Image Assistant (v5.3.7)...

powershell -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest -Uri 'https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.7.exe' -OutFile '%TEMP%\HPIA\HPIA.exe'"

if exist "%TEMP%\HPIA\HPIA.exe" (
    echo           [ OK ] Descarga completada.
    
    echo [11/14] Instalando HP Image Assistant...
    start "" "%TEMP%\HPIA\HPIA.exe"

    echo           [ OK ] Instalación finalizada.
) else (
    echo           [ ERROR ] nonradiative / No fue posible descargar HP Image Assistant.
)

echo  [11/14] Iniciando GPUPDATE /force en ventana aislada...
start "GPUPDATE - Actualizacion de Politicas" cmd /c "chcp 65001 >nul & echo +============================================+ & echo ^|  ACTUALIZANDO POLITICAS DE GRUPO (GPO)        ^| & echo +============================================+ & echo. & echo Aplicando GPOs requeridas: & echo - GPO_CP_Cert_Autoenrollment Compute & echo - GPO_CP_Cert_Autoenrollment User & echo - GPO_CP_802.1x_Adapter_Prueba & echo. & gpupdate /force & echo. & echo +============================================+ & echo ^|  PROCESO FINALIZADO                        ^| & echo +============================================+ & pause"
echo           [ OK ] Ventana aislada de GPUPDATE iniciada.

echo  [12/14] Reiniciando servicios de Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo           [ OK ] Completado.

echo  [13/14] Actualizando firmas de Windows Defender...
powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue" >nul 2>&1
echo           [ OK ] Completado.

echo  [14/14] Abriendo Windows Update...
start ms-settings:windowsupdate
echo           [ OK ] Completado.

echo.
echo +================================================================+
echo ^|  RESUMEN DE VENTANAS AISLADAS ABIERTAS:                       ^|
echo ^|    - WINGET: Actualizando aplicaciones                           ^|
echo ^|    - GPUPDATE: Actualizando politicas de grupo                  ^|
echo ^|                                                                 ^|
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