-- Coordenadas del Hospital de Jefferson (Al lado de Grove Street)
local HOSP_X, HOSP_Y, HOSP_Z, HOSP_ROT = 2032.8, -1404.9, 17.2, 130

-- ============================================================================
-- 1. FUNCIÓN CENTRAL DE GUARDADO (PERSISTENCIA MYSQL)
-- ============================================================================
function guardarDatosJugador(jugador)
    -- Verificamos que sea un elemento válido y que haya iniciado sesión
    if not isElement(jugador) or not getElementData(jugador, "logeado") then return false end
    
    local idCuenta = getElementData(jugador, "id_cuenta")
    if not idCuenta then return false end

    local x, y, z
    -- SI EL JUGADOR ESTÁ MUERTO en el momento del guardado (ej. por auto-guardado o al salir),
    -- guardamos la posición del hospital para que al volver a entrar no aparezca bugueado en el piso.
    if isPedDead(jugador) then
        x, y, z = HOSP_X, HOSP_Y, HOSP_Z
    else
        x, y, z = getElementPosition(jugador)
    end

    local skin = getElementModel(jugador)
    local dinero = getPlayerMoney(jugador)
    local bd = obtenerBD()

    -- Ejecutamos el UPDATE en XAMPP
    dbExec(bd, "UPDATE cuentas SET x = ?, y = ?, z = ?, skin = ?, dinero = ? WHERE id = ?", 
        x, y, z, skin, dinero, idCuenta
    )
    
    outputDebugString("[Core-Save] Datos actualizados en MySQL para cuenta ID: " .. tostring(idCuenta), 0)
    return true
end

-- ============================================================================
-- 2. APARICIÓN AL INICIAR SESIÓN (LOGIN)
-- ============================================================================
function spawnearJugador(jugador, datosCuenta)
    spawnPlayer(
        jugador, 
        datosCuenta.x, 
        datosCuenta.y, 
        datosCuenta.z, 
        0, 
        datosCuenta.skin, 
        0, 
        0
    )
    
    setCameraTarget(jugador, jugador)
    fadeCamera(jugador, true)
    setPlayerMoney(jugador, datosCuenta.dinero)
end

-- ============================================================================
-- 3. SISTEMA DE MUERTE Y RESPAWN EN EL HOSPITAL
-- ============================================================================
addEventHandler("onPlayerWasted", root, function()
    -- Verificamos si tiene cuenta para no respawnear invitados
    if not getElementData(source, "logeado") then return end
    
    local jugador = source
    outputChatBox("🚑 Has caído inconsciente. Los paramédicos te trasladarán en 5 segundos...", jugador, 255, 100, 100)
    
    -- Temporizador de 5 segundos (5000 ms) para dar realismo al traslado
    setTimer(function()
        if isElement(jugador) then
            -- Revivir en el hospital con skin actual, vida al 100 y cámara limpia
            spawnPlayer(jugador, HOSP_X, HOSP_Y, HOSP_Z, HOSP_ROT, getElementModel(jugador), 0, 0)
            setElementHealth(jugador, 100)
            setCameraTarget(jugador, jugador)
            fadeCamera(jugador, true)
            
            outputChatBox("🏥 Has sido dado de alta en el Hospital de Jefferson.", jugador, 50, 255, 50)
            
            -- ¡Importante! Guardamos en MySQL su nueva posición en el hospital
            guardarDatosJugador(jugador)
        end
    end, 5000, 1)
end)

-- ============================================================================
-- 4. GATILLOS DE GUARDADO AUTOMÁTICO
-- ============================================================================

-- A) Cuando un jugador sale del servidor de forma normal
addEventHandler("onPlayerQuit", root, function()
    guardarDatosJugador(source)
end)

-- B) Cuando el servidor se apaga o el recurso se reinicia por consola
addEventHandler("onResourceStop", resourceRoot, function()
    for _, jugador in ipairs(getElementsByType("player")) do
        guardarDatosJugador(jugador)
    end
    outputDebugString("[Core-Save] Se ha guardado el progreso de todos los jugadores al apagar el recurso.", 0, 0, 255, 0)
end)

-- C) Temporizador global de seguridad: Guardar a todos cada 5 minutos (300,000 ms)
setTimer(function()
    for _, jugador in ipairs(getElementsByType("player")) do
        guardarDatosJugador(jugador)
    end
end, 300000, 0)