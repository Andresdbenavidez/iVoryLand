# 🚀 MTA: San Andreas - Modular Gamemode Architecture

Un gamemode para **Multi Theft Auto: San Andreas (MTA: SA)** diseñado desde cero bajo el patrón de **Separación de Preocupaciones (Separation of Concerns)**, enfocado en alto rendimiento, modularidad extrema y persistencia relacional optimizada mediante MySQL.

---

## 📐 Arquitectura y Filosofía
Este proyecto rechaza el uso de scripts monolíticos de miles de líneas y dependencias obsoletas (como el gamemode nativo `play`). Cada sistema funciona bajo principios de responsabilidad única, comunicándose mediante eventos asíncronos y exportaciones seguras del servidor (`exports`).

### Ecosistema de Recursos
* **`[gamemodes]/core`**: El corazón del servidor. Gestor de base de datos MySQL, autenticación cifrada, ciclo de vida de sesiones y visualización de interfaz nativa en el cliente.
* **`[modules]/admin_cmds`**: Módulo de administración independiente integrado directamente con las listas de control de acceso nativas (`acl.xml`).

---

## 📚 Documentación Técnica por Módulos
Para conocer los detalles de implementación, eventos disponibles, exportaciones y flujos lógicos de cada sistema, consulta la documentación específica:

| Módulo | Categoría | Descripción y Enlace |
| :--- | :--- | :--- |
| **Núcleo Base (Core)** | `[gamemodes]` | [Ver Documentación - core_system.md](docs/core_system.md) <br> *(Conexión MySQL, Auth con Bcrypt, Sesiones y Cámara)* |
| **Administración** | `[modules]` | [Ver Documentación - admin_module.md](docs/admin_module.md) <br> *(Comandos administrativos y validación en ACL)* |

---

## 🛠️ Requisitos e Instalación Local

1. **Servidor MTA:SA 1.6+**: Descarga los archivos del servidor oficial desde [mtasa.com](https://mtasa.com/).
2. **Entorno MySQL (XAMPP / MariaDB / Linux MySQL)**:
   * Crea una base de datos vacía llamada `mta_servidor` con cotejamiento `utf8mb4_general_ci`.
   * **Nota:** No se requieren archivos `.sql` manuales; el código autogenera las tablas con el motor **InnoDB** en el primer inicio.
3. **Clonación del Proyecto**:
   * Clona este repositorio dentro del directorio `mods/deathmatch/resources/` de tu servidor.
4. **Configuración**:
   * Abre `[gamemodes]/core/shared/config.lua` y ajusta las credenciales de base de datos en la tabla `Config.MySQL`.
   * En la consola de MTA, ejecuta `refresh` seguidamente de `start core` y `start admin_cmds`.
