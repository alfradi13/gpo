@echo off
title ACTUALIZADOR AUTOMATICO UNAD
color 0A
setlocal EnableDelayedExpansion

::=========================================================
:: CONFIGURACION
::=========================================================

set "WORKDIR=C:\UNAD_TEMP"

set "HORUS_URL=https://unadvirtualedu-my.sharepoint.com/personal/fabio_benavides_unad_edu_co/_layouts/15/download.aspx?SourceUrl=%2Fpersonal%2Ffabio%5Fbenavides%5Funad%5Fedu%5Fco%2FDocuments%2FINSTALACION%2FHorus%5FUNAD%5F2%5F4%2Eexe"

set "ABS_URL=https://unadvirtualedu-my.sharepoint.com/personal/fabio_benavides_unad_edu_co/_layouts/15/download.aspx?UniqueId=aa65a0c2%2Db667%2D48ee%2D9e1c%2D27dc883270a0"

set "HPIA_URL=https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.6.exe"

mkdir "%WORKDIR%" >nul 2>&1

echo.
echo ============================================
echo      ACTUALIZADOR AUTOMATICO UNAD
echo ============================================
echo.

::=========================================================
:: HORUS
::=========================================================

echo Descargando Horus...

powershell -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest '%HORUS_URL%' -OutFile '%WORKDIR%\Horus.exe'"

if not exist "%WORKDIR%\Horus.exe" (
    echo ERROR descargando Horus.
    pause
    exit
)

echo.
echo Instalando Horus...

start /wait "" "%WORKDIR%\Horus.exe"

echo Horus instalado.
echo.

::=========================================================
:: ABSOLUTE
::=========================================================

echo Descargando Absolute...

powershell -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest '%ABS_URL%' -OutFile '%WORKDIR%\Absolute.zip'"

if not exist "%WORKDIR%\Absolute.zip" (
    echo ERROR descargando Absolute.
    pause
    exit
)

echo.
echo Descomprimiendo...

powershell -ExecutionPolicy Bypass -Command ^
"Expand-Archive '%WORKDIR%\Absolute.zip' '%WORKDIR%\Absolute' -Force"

echo.
echo Buscando instalador...

set EXE=

for /r "%WORKDIR%\Absolute" %%f in (*.exe) do (
    set EXE=%%f
    goto instalarAbsolute
)

echo No se encontro ningun ejecutable.
goto hpia

:instalarAbsolute

echo Ejecutando:
echo !EXE!

start /wait "" "!EXE!"

echo Absolute instalado.

::=========================================================
:: HP IMAGE ASSISTANT
::=========================================================

:hpia

echo.
echo Descargando HP Image Assistant...

powershell -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest '%HPIA_URL%' -OutFile '%WORKDIR%\HPIA.exe'"

if exist "%WORKDIR%\HPIA.exe" (

    echo Instalando HP Image Assistant...

    start /wait "" "%WORKDIR%\HPIA.exe"

)

::=========================================================
:: LIMPIEZA
::=========================================================

echo.
echo Eliminando temporales...

rd /s /q "%WORKDIR%"

echo.
echo ============================================
echo      PROCESO FINALIZADO
echo ============================================

pause