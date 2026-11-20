# Meli Nails — versión revisada

Los archivos `index.html` y `admin.html` contienen la misma aplicación. Deben permanecer iguales porque el sitio usa una única interfaz y protege la vista administrativa según la ruta `/admin.html`.

## Publicación en GitHub Pages

1. Reemplazá `index.html` y `admin.html` en la raíz de la rama `main`.
2. En GitHub, abrí **Settings → Pages**.
3. En **Build and deployment**, elegí **Deploy from a branch**.
4. Seleccioná la rama `main` y la carpeta `/(root)`, y guardá.
5. Esperá a que el despliegue termine y probá `/Argentina/` y `/Argentina/admin.html`.

## Cambios incluidos

- Corrige el acceso al panel cuando se inicia sesión desde `admin.html`: vuelve a mostrar el contenido que estaba oculto para visitantes.
- Escapa texto recibido de reservas y de Supabase antes de insertarlo en HTML, reduciendo el riesgo de XSS almacenado en el panel.
- Permite confirmar, rechazar, completar, cancelar o marcar ausente un turno desde la agenda.
- Usa categorías reales de Supabase en los filtros del catálogo.
- Muestra la imagen `image_url` de cada diseño si se publicó como URL HTTP/HTTPS o como ruta relativa dentro del proyecto; si falta el archivo, usa una imagen alternativa.
- Reemplaza datos de ejemplo falsos (domicilio, teléfono, reseña y estadísticas) por información neutra.
- Carga los primeros tres servicios reales en la portada.
- No permite enviar reservas cuando no se pudieron cargar los servicios desde Supabase.

## Importante antes de abrir reservas al público

- Configurá el WhatsApp real, alias/titular de pago e Instagram en `public.business_settings` desde Supabase. En este momento esos campos están vacíos.
- Revisá el horario cargado en `public.working_hours`: lunes a viernes 09:00–18:00, sábado 09:00–13:00 y domingo cerrado.
- Los ocho diseños actuales están marcados como muestras y no se muestran a clientas. Sus rutas (`/images/designs/*.png`) no corresponden a archivos presentes en el repositorio actual. Subí las imágenes reales dentro de `images/designs/` y marcá `is_sample = false` solo para los diseños que quieras publicar.
- En Finanzas podés marcar una seña pendiente como recibida seleccionando el medio de pago.
- No publiques credenciales `service_role` ni secretos en estos archivos. La clave publishable presente en el frontend es la adecuada para este uso.
- El código de cancelación del turno debe exigir las 24 horas de anticipación que promete la política. El parche separado `supabase-ajustes.sql` corrige esa regla e incorpora índices sugeridos. Ejecutalo en el SQL Editor de Supabase, no lo subas como archivo HTML.
- Activá la protección de contraseñas filtradas en **Supabase → Authentication → Security and Protection**.

## Límites que siguen pendientes

El panel actual permite gestionar servicios y estados de turnos, pero las pantallas de Diseños, Finanzas y Configuración siguen siendo principalmente de consulta. No hay todavía formulario público para buscar/cancelar un turno, apuntarse a la lista de espera o enviar reseñas. No se probó un pago real ni un flujo completo en un navegador con una clienta real.
