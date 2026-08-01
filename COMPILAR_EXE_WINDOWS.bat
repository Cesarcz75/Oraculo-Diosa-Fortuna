@echo off
flutter build windows --release
if errorlevel 1 goto error
echo.
echo Compilacion terminada.
echo Revisa: build\windows\x64\runner\Release
pause
exit /b 0
:error
echo.
echo No se pudo compilar.
pause
exit /b 1
