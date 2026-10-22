:RunAdmin
set "_RA_TITLE=%~1"
set "_RA_CMD=%~2"
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','chcp 65001 >nul & title %_RA_TITLE% & %_RA_CMD%' -Verb RunAs" >nul 2>&1
exit /b 0