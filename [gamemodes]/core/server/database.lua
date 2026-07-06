-- Variable local para que no colisione en la memoria global, pero accesible mediante la función
local conexionBD = nil

-- Función global para que auth.lua y spawn.lua puedan pedir el conector
function obtenerBD()
    return conexionBD
end

local function conectarBaseDeDatos()
    -- Formatear cadena de conexión de MTA para MySQL
    local cadenaConexion = string.format("dbname=%s;host=%s;port=%d;charset=utf8mb4", 
        Config.MySQL.database, 
        Config.MySQL.host, 
        Config.MySQL.port
    )

    -- Iniciar conexión (share=1 optimiza la memoria compartiendo el pool con otros scripts)
    conexionBD = dbConnect("mysql", cadenaConexion, Config.MySQL.username, Config.MySQL.password, "share=1")

    if conexionBD then
        outputDebugString("[Core-DB] Conexión MySQL (XAMPP) establecida con éxito.", 0, 0, 255, 0)
        
        -- Crear tabla de cuentas optimizada para MySQL (InnoDB + UTF8MB4)
        dbExec(conexionBD, [[
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
        ]])
    else
        outputDebugString("[Core-DB ERROR] No se pudo conectar a MySQL. Verifica que XAMPP esté encendido.", 1)
    end
end

addEventHandler("onResourceStart", resourceRoot, conectarBaseDeDatos)