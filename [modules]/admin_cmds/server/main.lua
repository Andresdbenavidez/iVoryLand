-- ============================================================================
-- 1. FUNCIÓN GUARDIANA DE SEGURIDAD (ACL)
-- ============================================================================
local function esAdministrador(jugador)
    -- Obtener la cuenta del servidor asociada al jugador
    local cuenta = getPlayerAccount(jugador)
    
    -- Si es una cuenta de invitado (no ha iniciado sesión), se rechaza
    if isGuestAccount(cuenta) then
        outputChatBox("[Error] Debes iniciar sesión para usar comandos administrativos.", jugador, 255, 50, 50)
        return false
    end
    
    local nombreCuenta = getAccountName(cuenta)
    -- Obtener el puntero al grupo "Admin" en el acl.xml
    local grupoAdmin = aclGetGroup("Admin")
    
    -- Si el grupo existe y la cuenta del usuario está en el formato "user.nombre" dentro del grupo
    if grupoAdmin and isObjectInACLGroup("user." .. nombreCuenta, grupoAdmin) then
        return true
    end
    
    outputChatBox("[Denegado] No tienes permisos en acl.xml para usar este comando.", jugador, 255, 50, 50)
    return false
end

-- ============================================================================
-- 2. FUNCIÓN DE BÚSQUEDA INTELIGENTE DE JUGADORES
-- ============================================================================
-- Permite a los admins escribir solo parte del nombre (ej: "/curar dav" curará a "David")
local function obtenerJugadorPorNombre(texto)
    if not texto then return nil end
    local textoMinuscula = string.lower(texto)
    
    for _, jugador in ipairs(getElementsByType("player")) do
        local nombreJugador = string.lower(getPlayerName(jugador))
        -- string.find busca si el fragmento de texto existe dentro del nombre
        if string.find(nombreJugador, textoMinuscula) then
            return jugador
        end
    end
    return nil
end

-- ============================================================================
-- 3. COMANDOS ADMINISTRATIVOS
-- ============================================================================

-- COMANDO: /curar [nombre (opcional)]
addCommandHandler("curar", function(jugador, comando, objetivoNombre)
    if not esAdministrador(jugador) then return end
    
    local objetivo = jugador -- Por defecto, el admin se cura a sí mismo
    
    if objetivoNombre then
        objetivo = obtenerJugadorPorNombre(objetivoNombre)
        if not objetivo then
            outputChatBox("[Admin] No se encontró ningún jugador con el nombre: " .. objetivoNombre, jugador, 255, 150, 0)
            return
        end
    end
    
    -- Restaurar salud (100) y blindaje (100)
    setElementHealth(objetivo, 100)
    setPedArmor(objetivo, 100)
    
    if objetivo == jugador then
        outputChatBox("[Admin] Te has curado por completo.", jugador, 0, 255, 0)
    else
        outputChatBox("[Admin] Has curado a " .. getPlayerName(objetivo) .. ".", jugador, 0, 255, 0)
        outputChatBox("[Admin] El administrador " .. getPlayerName(jugador) .. " te ha curado.", objetivo, 0, 255, 0)
    end
end)

-- COMANDO: /dardinero [nombre] [cantidad]
addCommandHandler("dardinero", function(jugador, comando, objetivoNombre, cantidad)
    if not esAdministrador(jugador) then return end
    
    local monto = tonumber(cantidad)
    if not objetivoNombre or not monto or monto <= 0 then
        outputChatBox("[Sintaxis] Uso correcto: /dardinero [jugador] [cantidad]", jugador, 255, 255, 0)
        return
    end
    
    local objetivo = obtenerJugadorPorNombre(objetivoNombre)
    if not objetivo then
        outputChatBox("[Admin] Jugador no encontrado.", jugador, 255, 150, 0)
        return
    end
    
    -- Damos el dinero en el motor físico (el archivo spawn.lua del core se encargará de guardarlo en MySQL al salir)
    -- Damos el dinero en el motor físico
    givePlayerMoney(objetivo, math.floor(monto))
    
    -- ¡NUEVO! Forzamos el guardado inmediato en la base de datos MySQL (XAMPP)
    exports.core:guardarDatosJugador(objetivo)
    
    outputChatBox("[Admin] Le has dado $" .. monto .. " a " .. getPlayerName(objetivo) .. ".", jugador, 0, 255, 0)
    outputChatBox("[Admin] Has recibido $" .. monto .. " por parte de un administrador.", objetivo, 0, 255, 0)
end)

-- COMANDO: /ir [nombre] (Teletransportarse hacia un jugador)
addCommandHandler("ir", function(jugador, comando, objetivoNombre)
    if not esAdministrador(jugador) then return end
    
    if not objetivoNombre then
        outputChatBox("[Sintaxis] Uso correcto: /ir [jugador]", jugador, 255, 255, 0)
        return
    end
    
    local objetivo = obtenerJugadorPorNombre(objetivoNombre)
    if not objetivo or objetivo == jugador then
        outputChatBox("[Admin] Jugador no válido o no encontrado.", jugador, 255, 150, 0)
        return
    end
    
    -- Obtener posición y dimensión del objetivo para evitar caer al vacío si está en otro interior
    local x, y, z = getElementPosition(objetivo)
    local interior = getElementInterior(objetivo)
    local dimension = getElementDimension(objetivo)
    
    -- Sincronizar interior y dimensión primero, luego teletransportar al lado (+1 en X)
    setElementInterior(jugador, interior)
    setElementDimension(jugador, dimension)
    setElementPosition(jugador, x + 1, y, z)
    
    outputChatBox("[Admin] Te has teletransportado hacia " .. getPlayerName(objetivo) .. ".", jugador, 0, 255, 0)
end)

-- COMANDO: /traer [nombre] (Traer un jugador hacia tu posición)
addCommandHandler("traer", function(jugador, comando, objetivoNombre)
    if not esAdministrador(jugador) then return end
    
    if not objetivoNombre then
        outputChatBox("[Sintaxis] Uso correcto: /traer [jugador]", jugador, 255, 255, 0)
        return
    end
    
    local objetivo = obtenerJugadorPorNombre(objetivoNombre)
    if not objetivo or objetivo == jugador then
        outputChatBox("[Admin] Jugador no válido o no encontrado.", jugador, 255, 150, 0)
        return
    end
    
    -- Obtener posición del admin
    local x, y, z = getElementPosition(jugador)
    local interior = getElementInterior(jugador)
    local dimension = getElementDimension(jugador)
    
    -- Teletransportar al objetivo justo enfrente del administrador (+1 en Y)
    setElementInterior(objetivo, interior)
    setElementDimension(objetivo, dimension)
    setElementPosition(objetivo, x, y + 1, z)
    
    outputChatBox("[Admin] Has traído a " .. getPlayerName(objetivo) .. " hacia tu posición.", jugador, 0, 255, 0)
    outputChatBox("[Admin] Has sido teletransportado por un administrador.", objetivo, 255, 200, 0)
end)

outputDebugString("[Módulo Admin] Comandos administrativos cargados y vinculados a la ACL.", 0, 0, 255, 0)

-- ============================================================================
-- 4. NUEVOS COMANDOS: VEHÍCULOS, ECONOMÍA Y TELETRANSPORTE POR COORDENADAS
-- ============================================================================

-- COMANDO: /veh [id_o_nombre_vehiculo]
addCommandHandler("veh", function(jugador, comando, entradaVehiculo)
    if not esAdministrador(jugador) then return end
    
    if not entradaVehiculo then
        outputChatBox("[Sintaxis] Uso correcto: /veh [ID o Nombre del vehículo] (Ej: /veh 411 o /veh Infernus)", jugador, 255, 255, 0)
        return
    end
    
    -- Intentar obtener el ID del vehículo (ya sea porque escribió un número "411" o un texto "Infernus")
    local modeloID = tonumber(entradaVehiculo)
    if not modeloID then
        modeloID = getVehicleModelFromName(entradaVehiculo)
    end
    
    -- Validar que el ID sea un vehículo existente en GTA: SA (los modelos van de 400 a 611)
    if not modeloID or modeloID < 400 or modeloID > 611 then
        outputChatBox("[Admin] ID o nombre de vehículo inválido (debe ser entre 400 y 611).", jugador, 255, 100, 100)
        return
    end
    
    -- Si el administrador ya tenía un vehículo creado temporalmente con este comando, lo borramos para no saturar el servidor
    local vehiculoAnterior = getElementData(jugador, "admin_veh_temp")
    if isElement(vehiculoAnterior) then
        destroyElement(vehiculoAnterior)
    end
    
    -- Obtener la posición y rotación actual del administrador
    local x, y, z = getElementPosition(jugador)
    local rotX, rotY, rotZ = getElementRotation(jugador)
    local interior = getElementInterior(jugador)
    local dimension = getElementDimension(jugador)
    
    -- Crear el vehículo un poco más arriba (+2 en Z) y con la misma orientación del jugador
    local nuevoVehiculo = createVehicle(modeloID, x, y, z + 2, rotX, rotY, rotZ)
    
    if isElement(nuevoVehiculo) then
        setElementInterior(nuevoVehiculo, interior)
        setElementDimension(nuevoVehiculo, dimension)
        
        -- Guardar la referencia del auto en el jugador para poder borrarlo luego
        setElementData(jugador, "admin_veh_temp", nuevoVehiculo)
        
        -- Colocar al administrador automáticamente en el asiento del conductor (asiento 0)
        warpPedIntoVehicle(jugador, nuevoVehiculo, 0)
        
        outputChatBox("[Admin] Has spawneado un " .. getVehicleName(nuevoVehiculo) .. " (ID: " .. modeloID .. ").", jugador, 0, 255, 0)
    else
        outputChatBox("[Error] No se pudo crear el vehículo en esta ubicación.", jugador, 255, 50, 50)
    end
end)

-- COMANDO: /quitardinero [nombre] [cantidad]
addCommandHandler("quitardinero", function(jugador, comando, objetivoNombre, cantidad)
    if not esAdministrador(jugador) then return end
    
    local monto = tonumber(cantidad)
    if not objetivoNombre or not monto or monto <= 0 then
        outputChatBox("[Sintaxis] Uso correcto: /quitardinero [jugador] [cantidad]", jugador, 255, 255, 0)
        return
    end
    
    local objetivo = obtenerJugadorPorNombre(objetivoNombre)
    if not objetivo then
        outputChatBox("[Admin] Jugador no encontrado.", jugador, 255, 150, 0)
        return
    end
    
    -- Tomamos el dinero actual y restamos el monto (asegurando que sea entero con math.floor)
    local dineroActual = getPlayerMoney(objetivo)
    local dineroAQuitar = math.floor(monto)
    
    -- Evitar que el jugador quede con dinero negativo en el HUD (o puedes quitar el math.max si deseas deudas negativas)
    local nuevoSaldo = math.max(0, dineroActual - dineroAQuitar)
    setPlayerMoney(objetivo, nuevoSaldo)
    
    -- ¡NUEVO! Forzamos el guardado inmediato en la base de datos MySQL (XAMPP)
    exports.core:guardarDatosJugador(objetivo)
    
    outputChatBox("[Admin] Le has quitado $" .. dineroAQuitar .. " a " .. getPlayerName(objetivo) .. ".", jugador, 0, 255, 0)
    outputChatBox("[Admin] Un administrador ha deducido $" .. dineroAQuitar .. " de tu saldo.", objetivo, 255, 150, 0)
end)

-- COMANDO: /tp [x] [y] [z]
addCommandHandler("tp", function(jugador, comando, coordX, coordY, coordZ)
    if not esAdministrador(jugador) then return end
    
    -- Convertir las entradas de texto a números decimales
    local x, y, z = tonumber(coordX), tonumber(coordY), tonumber(coordZ)
    
    if not x or not y or not z then
        outputChatBox("[Sintaxis] Uso correcto: /tp [X] [Y] [Z] (Ej: /tp 0 0 10)", jugador, 255, 255, 0)
        return
    end
    
    -- Verificar si el administrador está dentro de un vehículo o a pie
    local vehiculoAdmin = getPedOccupiedVehicle(jugador)
    
    if vehiculoAdmin then
        -- Si está conduciendo o de pasajero, teletransportamos todo el auto con los ocupantes
        setElementPosition(vehiculoAdmin, x, y, z)
        setElementVelocity(vehiculoAdmin, 0, 0, 0) -- Frenar la inercia del vehículo al llegar
    else
        -- Si está a pie, teletransportamos solo a su personaje
        setElementPosition(jugador, x, y, z)
    end
    
    outputChatBox("[Admin] Te has teletransportado a las coordenadas: " .. x .. ", " .. y .. ", " .. z, jugador, 0, 255, 0)
end)