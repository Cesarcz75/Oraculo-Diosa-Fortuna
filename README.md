# Oráculo Diosa Fortuna Professional

Plataforma Flutter de investigación estadística para Melate Retro, desarrollada por PRIME Innovation Thinking.

## Versión estable

**1.1.0+110**

## Acceso por suscripción

La versión 1.1.0 usa las mismas cuentas de Academia PIT mediante Supabase.
Antes de mostrar el software valida que el usuario esté activo, inscrito en
Oráculo Diosa Fortuna y dentro de su periodo de acceso. La Academia debe tener
instalado `supabase/diosa_subscriptions_v3_6.sql` de la versión 3.6.0.

## Calidad

```bash
flutter pub get
flutter analyze
flutter test
```

## Builds

- `Build Windows Download`: ZIP portable para Windows.
- `Build and Deploy Web`: despliegue en GitHub Pages.
- `Build Android Release`: APK y AAB de prueba.
- `Publish Professional Release`: AAB firmado, APK, Web, Windows y GitHub Release.

La firma para Google Play se configura mediante secretos de GitHub. Consulte `store/GUIA_FIRMA_ANDROID.txt`.

## Aviso

El software no garantiza premios y sus indicadores no representan probabilidades de ganar.
