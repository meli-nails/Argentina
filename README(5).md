# Meli Nails

Sitio web de reservas y panel privado de administración para Meli Nails. La aplicación está construida con HTML, CSS y JavaScript, y utiliza Supabase como backend. No necesita un proceso de compilación.

## Estructura del repositorio

| Archivo | Función |
|---|---|
| `index.html` | Sitio público: portada, servicios, catálogo y solicitud de turnos. |
| `admin.html` | Entrada directa al panel privado de administración. |
| `meli-supabase-hardening.sql` | Registro de las políticas RLS y permisos de base de datos aplicados al proyecto. |
| `supabase-ajustes.sql` | Ajustes complementarios de cancelación e índices. No habilita por sí solo una pantalla pública de cancelación. |

`index.html` y `admin.html` deben mantenerse sincronizados: contienen la misma aplicación y la ruta determina qué vista se muestra. El panel no se protege solamente ocultando elementos; valida la sesión de Supabase y la pertenencia del usuario a `public.admins`. Las políticas RLS de la base de datos siguen siendo la barrera de seguridad principal.

## Funcionalidades

### Sitio público

- Presentación del estudio y datos públicos del negocio.
- Servicios, precios y duración cargados desde Supabase.
- Catálogo de diseños reales publicados, con categorías e imágenes.
- Consulta de días y horarios disponibles mediante funciones RPC.
- Envío de solicitudes de turno a través de `create_booking_request`.
- Resumen de la solicitud y datos de contacto.

### Panel privado

- Acceso mediante Supabase Auth y validación contra `public.admins`.
- Dashboard y agenda con solicitudes reales.
- Confirmación, rechazo, cancelación, finalización y registro de ausencias.
- Consulta de clientas registradas.
- Alta y edición de servicios, precios, duración y visibilidad.
- Alta y edición de diseños, categoría, descripción, precio adicional, imagen, disponibilidad y destacados.
- Registro manual de pagos pendientes como recibidos, seleccionando el medio de pago.
- Edición de los datos del negocio, instrucciones de seña, política de cancelación y horarios semanales.

El registro de pagos es administrativo: este proyecto no incorpora una pasarela de pago ni procesa transferencias automáticamente.

## Configuración de Supabase

La aplicación necesita el esquema y las tablas de Supabase del proyecto. El frontend utiliza la URL del proyecto y una clave publishable; esa clave puede estar en el navegador y no reemplaza las políticas RLS.

1. Verificá que existan las tablas utilizadas por la aplicación: `admins`, `business_settings`, `working_hours`, `services`, `designs`, `clients`, `bookings` y `payments`.
2. Revisá que estén instaladas las funciones RPC `get_public_business_settings`, `get_available_days`, `get_available_slots` y `create_booking_request`.
3. Ejecutá `meli-supabase-hardening.sql` únicamente si sus cambios todavía no fueron aplicados. El archivo documenta el endurecimiento de políticas y permisos; no es un instalador del esquema inicial.
4. Creá la cuenta administrativa en Supabase Auth y registrá su `user_id` en `public.admins`. No concedas acceso administrativo a cuentas que no deban gestionar el negocio.
5. Desde el panel, completá los datos reales en Configuración: WhatsApp, país, Instagram, correo, dirección, seña, alias y titular de pago, instrucciones y política de cancelación.
6. Revisá los siete días de atención, los precios y la duración de cada servicio.

La zona horaria de la aplicación está fijada en `America/Argentina/Buenos_Aires` para evitar desajustes en los turnos.

### Diseños

Los diseños de muestra permanecen privados. Para publicar uno, editá o creá el registro desde el panel, cargá una URL HTTPS de una fotografía propia, desmarcá **Es una muestra privada** y activá **Disponible para reservar**. No se deben presentar imágenes de muestra como trabajos reales del estudio.

### Seguridad

- No agregues claves `service_role`, contraseñas ni secretos al HTML o al repositorio.
- Conservá RLS y las políticas administrativas. Ocultar `/admin.html` no sustituye la autorización en Supabase.
- Mantené la protección de contraseñas filtradas habilitada en Supabase Auth (**Authentication → Security and Protection**).
- Revisá las URL de imágenes y no permitas que contenido externo no confiable se convierta en HTML ejecutable.

## Publicación con GitHub Pages

1. Abrí **Settings → Pages** del repositorio.
2. En **Build and deployment**, seleccioná **Deploy from a branch**.
3. Elegí la rama `main` y la carpeta `/(root)` y guardá.
4. Esperá a que GitHub termine el despliegue.
5. Comprobá el sitio público y el panel en:
   - `https://meli-nails.github.io/Argentina/`
   - `https://meli-nails.github.io/Argentina/admin.html`

Si se cambia el nombre del repositorio o el dominio, actualizá estas direcciones y las URL de redirección permitidas en Supabase Auth.

## Verificación antes de abrir al público

- Cargar los datos reales de contacto, pago y ubicación.
- Publicar fotografías auténticas de los diseños que se quieran mostrar.
- Comprobar que los servicios activos tengan precio y duración correctos.
- Probar una solicitud de turno desde un dispositivo móvil y revisar que aparezca en el panel.
- Probar confirmación y rechazo, y verificar que los horarios ocupados dejen de ofrecerse.
- Verificar permisos con una cuenta administrativa y con una sesión anónima.
- Revisar los registros y errores de Supabase durante las pruebas.

## Limitaciones conocidas

No hay todavía una interfaz pública para consultar o cancelar un turno existente, anotarse en lista de espera o enviar reseñas. Tampoco hay una pasarela de cobro integrada. Esas funciones no deben anunciarse como disponibles hasta que se desarrollen y se prueben de extremo a extremo.
