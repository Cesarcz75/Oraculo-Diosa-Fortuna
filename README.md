# Oráculo Diosa Fortuna Professional

Plataforma Flutter de investigación estadística para Melate Retro, desarrollada por PRIME Innovation Thinking.

## Versión estable

**1.2.3+123**

## Acceso por suscripción

La versión 1.1.0 usa las mismas cuentas de Academia PIT mediante Supabase.
Antes de mostrar el software valida que el usuario esté activo, inscrito en
Oráculo Diosa Fortuna y dentro de su periodo de acceso. La Academia debe tener
instalado `supabase/diosa_subscriptions_v3_6.sql` de la versión 3.6.0.

## Histórico oficial de Melate Retro

Desde la versión 1.2.0, los sorteos nuevos se almacenan de forma central en
Supabase. El administrador registra el número de concurso, la fecha y los seis
números; los suscriptores reciben el mismo historial en modo de sólo lectura.
El número de concurso y la fecha son únicos, mientras que una combinación puede
repetirse legítimamente en concursos diferentes. Requiere ejecutar
`supabase/retro_draws_v1_2.sql` una sola vez en el proyecto de Supabase.

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
