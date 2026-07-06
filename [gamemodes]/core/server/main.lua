-- Cuando un jugador entra, no lo spawneamos físicamente. Lo dejamos volando en una cámara mientras espera el login.
addEventHandler("onPlayerJoin", root, function()
    outputChatBox("Bienvenido. Por favor inicia sesión o regístrate.", source, 255, 255, 0)
end)

-- Configuración general del mundo al iniciar el recurso
addEventHandler("onResourceStart", resourceRoot, function()
    -- Ejemplo: Establecer clima despejado (0) y hora fija o normal
    setWeather(0)
    setTime(12, 0)
    outputDebugString("[Core-Main] Lógica principal del mundo inicializada.", 0)
end)