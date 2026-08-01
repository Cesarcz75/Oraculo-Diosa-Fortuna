@echo off
echo Preparando Oraculo Diosa Fortuna...
flutter create . --platforms=windows,android,web
if errorlevel 1 goto error
flutter pub get
if errorlevel 1 goto error
echo.
echo Proyecto preparado correctamente.
pause
exit /b 0
:error
echo.
echo Ocurrio un error. Verifica que Flutter este instalado y disponible en PATH.
pause
exit /b 1
