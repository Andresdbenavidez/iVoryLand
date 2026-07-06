Config = {}

-- Coordenadas de spawn inicial (X, Y, Z, Rotación, SkinID)
Config.Spawn = {
    x = 1959.55,
    y = -1714.46,
    z = 10.0,
    rot = 0,
    skin = 135
}

-- Configuración de Base de Datos MySQL (XAMPP por defecto no tiene contraseña en root)
Config.MySQL = {
    host = "127.0.0.1",   -- Usamos la IP local en vez de 'localhost' por velocidad de resolución
    port = 3306,          -- Puerto por defecto de XAMPP
    database = "ivoryland_db",
    username = "root",
    password = ""         -- Déjalo vacío si estás en XAMPP estándar
}
