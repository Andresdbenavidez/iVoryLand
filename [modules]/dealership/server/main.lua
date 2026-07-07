local conexionDB = nil

-- Función principal que dibuja los concesionarios en el mapa real
local function crearMarcadoresEnMapa()
    outputDebugString("[DEALERSHIP] Consultando tiendas activas para el mapa...", 3)
    
    local consulta = dbQuery(conexionDB, "SELECT * FROM concesionarios WHERE estado_abierto = 1")
    local resultados = dbPoll(consulta, -1)

    if resultados and #resultados > 0 then
        for index, fila in ipairs(resultados) do
            -- Creamos el marcador físico (un cilindro verde visible)
            local marcador = createMarker(fila.pos_x, fila.pos_y, fila.pos_z - 1.0, "cylinder", 2.0, 0, 255, 0, 150)
            
            -- Creamos el ícono en el mapa (ID 55 es el coche verde de San Andreas)
            createBlip(fila.pos_x, fila.pos_y, fila.pos_z, 55, 2)
            
            -- Guardamos el ID dinámico de la base de datos en la memoria del marcador
            setElementData(marcador, "esConcesionario", fila.id)
            
            outputDebugString("[DEALERSHIP] ¡ÉXITO! Marcador e ícono creados para: " .. fila.nombre, 3)
        end
    else
        outputDebugString("[DEALERSHIP ERROR] Las tablas existen, pero la consulta no devolvió ninguna fila activa.", 2)
    end
end

-- Función autónoma para verificar la estructura e insertar la semilla de datos iniciales
local function inicializarBaseDeDatos()
    if not conexionDB then return end

    -- 1. Creamos la tabla de los concesionarios
    dbExec(conexionDB, [[
        CREATE TABLE IF NOT EXISTS `concesionarios` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `nombre` VARCHAR(50) NOT NULL,
          `pos_x` FLOAT NOT NULL,
          `pos_y` FLOAT NOT NULL,
          `pos_z` FLOAT NOT NULL,
          `estado_abierto` TINYINT(1) DEFAULT 1
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- 2. 🛑 CORREGIDO: Eliminamos la coma huérfana antes del FOREIGN KEY
    dbExec(conexionDB, [[
        CREATE TABLE IF NOT EXISTS `concesionarios_vehiculos` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `concesionario_id` INT NOT NULL,
          `modelo_gta` INT NOT NULL,
          `nombre_estetico` VARCHAR(50) NOT NULL,
          `precio` INT NOT NULL,
          CONSTRAINT fk_concesionario FOREIGN KEY (`concesionario_id`) REFERENCES `concesionarios`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- 3. Creamos la tabla de persistencia para los vehículos comprados
    dbExec(conexionDB, [[
        CREATE TABLE IF NOT EXISTS `vehiculos_jugadores` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `propietario` VARCHAR(100) NOT NULL,
          `modelo_gta` INT NOT NULL,
          `concesionario_id` INT NOT NULL,
          `color_r` INT DEFAULT 255,
          `color_g` INT DEFAULT 255,
          `color_b` INT DEFAULT 255
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- 4. Forzamos una comprobación síncrona de las semillas
    local consultaValidacion = dbQuery(conexionDB, "SELECT id FROM concesionarios LIMIT 1")
    local resultadoValidacion = dbPoll(consultaValidacion, -1)

    if resultadoValidacion and #resultadoValidacion == 0 then
        outputDebugString("[DEALERSHIP] phpMyAdmin vacío. Insertando fila semilla de Jefferson Motors...", 3)
        
        dbExec(conexionDB, "INSERT INTO `concesionarios` (`id`, `nombre`, `pos_x`, `pos_y`, `pos_z`, `estado_abierto`) VALUES (1, 'Jefferson Motors', 2131.5, -1150.8, 24.0, 1)")
        dbExec(conexionDB, "INSERT INTO `concesionarios_vehiculos` (`concesionario_id`, `modelo_gta`, `nombre_estetico`, `precio`) VALUES (1, 411, 'Pegassi Infernus', 150000)")
        dbExec(conexionDB, "INSERT INTO `concesionarios_vehiculos` (`concesionario_id`, `modelo_gta`, `nombre_estetico`, `precio`) VALUES (1, 541, 'Vapid Bullet', 95000)")
        
        setTimer(crearMarcadoresEnMapa, 100, 1)
    else
        crearMarcadoresEnMapa()
    end
end

-- Función de arranque conectada al Core central
local function arrancarRecurso()
    local recursoCore = getResourceFromName("core")
    if recursoCore and getResourceState(recursoCore) == "running" then
        conexionDB = exports["core"]:obtenerBD()
    end
    
    if conexionDB then
        inicializarBaseDeDatos()
    else
        outputDebugString("[DEALERSHIP] No se pudo obtener la conexión del core todavía. Reintentando...", 2)
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[DEALERSHIP] Módulo iniciado individualmente. Buscando conexión...", 3)
    setTimer(arrancarRecurso, 100, 1)
end)

addEventHandler("onResourceStart", root, function(recursoIniciado)
    if getResourceName(recursoIniciado) == "core" then
        outputDebugString("[DEALERSHIP] Se detectó reinicio del Core central. Sincronizando BD...", 3)
        setTimer(arrancarRecurso, 300, 1)
    end
end)


-- ====================================================================
-- MANEJADOR DE ENVIAR CATÁLOGO
-- ====================================================================
addEvent("dealership:solicitarCatalogo", true)
addEventHandler("dealership:solicitarCatalogo", root, function(idTienda)
    local jugador = client
    if not conexionDB then return end

    local idNumerico = tonumber(idTienda)
    if not idNumerico then return end

    dbQuery(function(queryHandle)
        local resultados = dbPoll(queryHandle, -1)
        if not resultados then
            triggerClientEvent(jugador, "dealership:recibirCatalogo", jugador, {})
            return
        end
        
        if #resultados > 0 then
            triggerClientEvent(jugador, "dealership:recibirCatalogo", jugador, resultados)
        else
            outputChatBox("🏪 Este concesionario no tiene vehículos asignados.", jugador, 255, 255, 0)
            triggerClientEvent(jugador, "dealership:recibirCatalogo", jugador, {}) 
        end
    end, conexionDB, "SELECT * FROM concesionarios_vehiculos WHERE concesionario_id = ?", idNumerico)
end)


-- ====================================================================
-- MANEJADOR DE PROCESAMIENTO DE COMPRA (SERVIDOR) - CON PERSISTENCIA
-- ====================================================================
addEvent("dealership:procesarCompra", true)
addEventHandler("dealership:procesarCompra", root, function(idVehiculo)
    local jugador = client
    
    if not jugador or not isElement(jugador) then return end
    
    local idNumerico = tonumber(idVehiculo)
    if not idNumerico or not conexionDB then return end

    dbQuery(function(queryHandle)
        local resultados = dbPoll(queryHandle, -1)
        if not resultados or #resultados == 0 then return end

        local datosCoche = resultados[1]
        local precioVehiculo = tonumber(datosCoche.precio)
        local modeloGTA = tonumber(datosCoche.modelo_gta)
        local nombreVehiculo = tostring(datosCoche.nombre_estetico)
        local tiendaID = tonumber(datosCoche.concesionario_id)

        -- 1. VERIFICACIÓN DE FONDOS
        local dineroActual = getPlayerMoney(jugador)
        if dineroActual < precioVehiculo then
            local faltante = precioVehiculo - dineroActual
            outputChatBox("❌ No tienes suficiente dinero. Te faltan: $" .. string.format("%s", faltante), jugador, 255, 0, 0)
            return
        end

        -- 2. VERIFICACIÓN DE CUENTA DEL JUGADOR
        local cuentaJugador = getPlayerAccount(jugador)
        if isGuestAccount(cuentaJugador) then
            outputChatBox("❌ Error: Debes iniciar sesión en tu cuenta para poder comprar un vehículo.", jugador, 255, 0, 0)
            return
        end
        local nombreCuenta = getAccountName(cuentaJugador)

        -- 3. COBRAR DINERO Y CERRAR MENÚ
        takePlayerMoney(jugador, precioVehiculo)
        triggerClientEvent(jugador, "dealership:cerrarMenuCompra", jugador)

        -- 4. 🛑 ESCRITURA FÍSICA EN MYSQL: Guardamos la propiedad de forma permanente
        dbExec(conexionDB, "INSERT INTO `vehiculos_jugadores` (`propietario`, `modelo_gta`, `concesionario_id`) VALUES (?, ?, ?)", nombreCuenta, modeloGTA, tiendaID)

        -- Notificaciones de éxito
        outputChatBox("🎉 ¡Felicitaciones! Has comprado un " .. nombreVehiculo .. " por $" .. string.format("%s", precioVehiculo) .. ".", jugador, 0, 255, 0)
        outputChatBox("💾 Propietario registrado: " .. nombreCuenta .. ". Guardado en la Base de Datos.", jugador, 200, 200, 200)
        outputDebugString("[DEALERSHIP] Compra registrada en BD para la cuenta: " .. nombreCuenta, 3)

    end, conexionDB, "SELECT * FROM concesionarios_vehiculos WHERE id = ? LIMIT 1", idNumerico)
end)