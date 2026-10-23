<p align="center"><img src="images/banner-es.png" alt="WorkHarbor — Tus calendarios. En armonía." /></p>

[English](../README.md) · [Português](README.pt-BR.md) · Español

# WorkHarbor

Un lugar tranquilo para tus calendarios, en la barra de menús de macOS.

Consulta próximos eventos y sincroniza los calendarios ya configurados en el Calendario de Apple. Sin correo, navegador integrado, cuentas de IA ni contraseñas adicionales.

> **Versión preliminar en desarrollo.** No es una versión de producción notarizada. Las pruebas sintéticas no demuestran compatibilidad con todos los proveedores. Revisa los cambios antes de autorizar la sincronización automática.

## Un vistazo al menú

<p align="center"><img src="images/agenda-es-light.png" width="320" alt="WorkHarbor light" /> <img src="images/agenda-es-dark.png" width="320" alt="WorkHarbor dark" /></p>

Interfaz nativa renderizada en macOS con eventos ficticios. Sin datos privados de calendarios.

## Lo esencial, a mano

- Panel nativo SwiftUI con eventos próximos, colores por calendario, eventos en curso y grupos por día.
- Ventana independiente solo para configuración.
- Copias **Busy** que comparten únicamente horarios, con márgenes opcionales antes y después.
- Copias completas cuando autorizas compartir títulos, notas y ubicaciones.
- Automatización por regla, vinculada al origen, destino, modo y márgenes aprobados.
- Limpieza revisable de duplicados identificados que conserva la copia registrada actualizada.
- Interfaz en inglés, portugués brasileño y español.

## Cómo funciona

Las cuentas del Calendario de Apple gestionan la sincronización con sus proveedores. WorkHarbor usa EventKit y requiere su propio permiso de acceso. Se respetan las restricciones de las cuentas y los calendarios de solo lectura.

El menú muestra los próximos siete días, hasta 80 eventos. La sincronización examina los 30 días anteriores y los 180 siguientes. Funciona con la aplicación abierta y el Mac despierto, con comprobaciones tras despertar y cambios del calendario. No es un servicio en la nube ni garantiza entrega remota inmediata.

## Protecciones

Las copias llevan una identificación de WorkHarbor y se registran localmente. Un título coincidente nunca demuestra que un evento pertenece a la aplicación.

La ausencia del evento original no se interpreta como eliminación. La sincronización en segundo plano nunca elimina eventos. La limpieza requiere una copia registrada actualizada, selección y confirmación. No se adivina la identidad de eventos sin marcador, de otras instalaciones o sin correspondencia.

Se bloquean ciclos, rutas redundantes y encadenamientos desde destinos Busy. Un registro persistente impide repetir escrituras cuyo resultado es incierto. No borres ese registro para forzar un reintento.

La migración conserva identificadores, reglas e inventario. Los datos y credenciales de las antiguas funciones de correo no se cargan ni se eliminan en la edición de calendarios.

## Compilación

macOS 14 o posterior y herramientas Xcode/Swift 6. Sin dependencias Swift externas.

```sh
./scripts/test.sh
./scripts/build-app.sh
```

El script crea aplicación y ZIP en `dist/`, con firma ad hoc local, no notarización de Apple. Cierra la versión anterior antes de abrir otra. No ignores advertencias de seguridad para ejecutar descargas no fiables.

## Privacidad y estado

Sin analítica, lector de correo, endpoint de IA ni servidor propio de calendarios. macOS puede transmitir copias a los proveedores de las cuentas de destino elegidas. Las reglas completas incluyen títulos, notas y ubicaciones; Busy no.

No publiques eventos privados, exportaciones, identificadores de cuentas ni secretos al informar de problemas. Usa ejemplos ficticios.

El rediseño está en validación. La integración con proveedores, zonas horarias y accesibilidad necesitan pruebas continuas. Las imágenes promocionales son ilustraciones, no pruebas de funciones en ejecución.

Todavía no se ha elegido una licencia. No se concede una licencia de redistribución implícita.
