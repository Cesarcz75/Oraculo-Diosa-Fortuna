# Compilar sin instalar Flutter en tu computadora

Esta fase incluye flujos de GitHub Actions que pueden generar:

- un paquete para Windows;
- un APK de Android;
- un Android App Bundle para Google Play;
- una compilación web.

## Qué necesitas

1. Una cuenta de GitHub.
2. Crear un repositorio nuevo.
3. Subir todo el contenido de esta carpeta al repositorio.
4. Abrir la pestaña **Actions**.
5. Elegir el proceso:
   - **Build Windows**
   - **Build Android**
   - **Build Web**
6. Pulsar **Run workflow**.
7. Cuando termine, descargar el archivo desde la sección **Artifacts**.

## Windows

El flujo genera:

`Oraculo_Diosa_Fortuna_Windows.zip`

Debe descomprimirse completo. Dentro estará el ejecutable y las bibliotecas necesarias.

## Android

Se generan dos archivos:

- `app-release.apk`: para instalar y probar directamente.
- `app-release.aab`: formato requerido para publicar en Google Play.

El AAB generado en esta fase no está firmado con una llave comercial propia. Antes de publicar se debe configurar una llave de firma, nombre de paquete definitivo, política de privacidad, ficha de Play Store y declaraciones de seguridad.

## Advertencia

GitHub Actions compila el código, pero no sustituye las pruebas reales en Windows y Android. La versión debe probarse antes de distribuirla o publicarla.
