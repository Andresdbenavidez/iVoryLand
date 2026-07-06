# ⚙️ Documentación Técnica: Core System (`[gamemodes]/core`)

El módulo `core` actúa como la columna vertebral de la infraestructura del servidor. No gestiona mecánicas de juego en sí, sino que administra la capa de persistencia relacional, la seguridad de identidades y el ciclo de vida de las sesiones de cliente.

---

## 1. Módulos y Responsabilidades del Código
El núcleo está segmentado estrictamente por capas lógicas configuradas en su archivo manifiesto (`meta.xml` con `<oop>true</oop>` activado):

* **`shared/config.lua`**: Define constantes globales (Coordenadas de Spawn y Parámetros de Conexión MySQL).
* **`server/database.lua`**: Implementa el pool de conexiones relacional bajo el argumento `share=1` para la reutilización de memoria y ejecuta sentencias DDL auto-migrables para crear la tabla `cuentas` con el motor **InnoDB**.
* **`server/auth.lua`**: Procesa la entrada de credenciales mediante eventos asíncronos para evitar el bloqueo del hilo principal (*Main Thread*) del servidor. Implementa hashing criptográfico nativo mediante **bcrypt**.
* **`server/spawn.lua` y `server/main.lua`**: Gestionan la instanciación física en Los Santos y centralizan el guardado de progreso ante caídas de red, detención de recursos y temporizadores de seguridad.
* **`client/camera.lua` y `client/gui_login.lua`**: Controlan el aislamiento visual del usuario al conectarse (cámara panorámica en el cliente y congelamiento físico del Ped) y la interfaz gráfica basada en **CEGUI** con enmascarado de contraseña.

---

## 2. Estructura de Base de Datos (DDL Relacional)
El núcleo autogenera la siguiente estructura en MySQL en el primer inicio del servidor:

```sql
CREATE TABLE IF NOT EXISTS cuentas (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    dinero INT DEFAULT 500,
    skin INT DEFAULT 0,
    x FLOAT DEFAULT 1959.55,
    y FLOAT DEFAULT -1714.46,
    z FLOAT DEFAULT 10.0,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
