-- Variables del sistema
local gpsActual = nil
local vehiculoExhibicion = nil
local temporizadorRotacion = nil
-- Guardamos la posición exacta donde estaba parado el jugador en la calle antes de entrar
local calleX, calleY, calleZ = 0, 0, 0

local catalogoActual = {}
local indiceSeleccionado = 1
local cargandoSala = false 

-- Variables para DirectX
local mostrandoDX = false
local textoNombre = ""
local textoPrecio = ""
local textoVelocidad = ""
local textoPlazas = ""

-- Declaramos la función de salida antes para poder usarla en los binds
local salirConcesionario

-- 1. Comando GPS
local function gestionarGPS(comando, coordX, coordY, coordZ)
    local x, y, z = tonumber(coordX), tonumber(coordY), tonumber(coordZ)
    if not x or not y or not z then
        outputChatBox("Uso: /marcarconcesionario [X] [Y] [Z]", 255, 255, 0)
        return
    end
    if isElement(gpsActual) then destroyElement(gpsActual) end
    gpsActual = createBlip(x, y, z, 41, 2, 255, 0, 0)
    outputChatBox("🛰️ GPS: Ubicación marcada en el minimapa.", 0, 255, 0)
end
addCommandHandler("marcarconcesionario", gestionarGPS)

-- 2. Ficha Técnica (DirectX)
local function calcularDatosVehiculo(modelID, nombreEstetico, precio)
    textoNombre = tostring(nombreEstetico):upper()
    textoPrecio = "PRECIO: $" .. string.format("%s", precio)
    
    local handlingOriginal = getOriginalHandling(modelID)
    local velocidadPlana = 150
    if handlingOriginal and handlingOriginal["maxVelocity"] then
        velocidadPlana = handlingOriginal["maxVelocity"]
    end
    
    local velocidadKMH = math.floor(velocidadPlana * 1.2)
    textoVelocidad = "VEL. MÁXIMA: " .. velocidadKMH .. " KM/H"
    
    local plazasPasajeros = getVehicleMaxPassengers(modelID) or 1
    local capacidadTotal = plazasPasajeros + 1
    textoPlazas = "CAPACIDAD: " .. capacidadTotal .. " PLAZAS"
end

-- 3. Renderizado Gráfico DirectX
local function renderizarInformacionVehiculo()
    if not mostrandoDX then return end
    
    local x, y = guiGetScreenSize()
    local ancho, alto = 320, 240
    local posX = x - ancho - 40
    local posY = (y / 2) - (alto / 2)
    
    dxDrawRectangle(posX, posY, ancho, alto, tocolor(0, 0, 0, 180))
    dxDrawRectangle(posX, posY, ancho, 4, tocolor(0, 255, 0, 255))
    
    local padX = posX + 20
    dxDrawText(textoNombre, padX + 1, posY + 21, ancho, alto, tocolor(0, 0, 0, 255), 1.6, "default-bold")
    dxDrawText(textoNombre, padX, posY + 20, ancho, alto, tocolor(255, 255, 255, 255), 1.6, "default-bold")
    
    dxDrawText(textoPrecio, padX + 1, posY + 66, ancho, alto, tocolor(0, 0, 0, 255), 1.2, "default")
    dxDrawText(textoPrecio, padX, posY + 65, ancho, alto, tocolor(0, 255, 0, 255), 1.2, "default-bold")
    
    dxDrawRectangle(padX, posY + 95, ancho - 40, 1, tocolor(255, 255, 255, 40))
    
    dxDrawText(textoVelocidad, padX, posY + 115, ancho, alto, tocolor(200, 200, 200, 255), 1.1, "default")
    dxDrawText(textoPlazas, padX, posY + 140, ancho, alto, tocolor(200, 200, 200, 255), 1.1, "default")
    
    -- Actualizamos el texto guía inferior para reflejar la tecla BACKSPACE
    dxDrawText("◄ / ► Cambiar Auto  |  ENTER Comprar  |  BACKSPACE Salir", posX, posY + alto - 25, posX + ancho, y, tocolor(150, 150, 150, 255), 0.9, "default", "center")
end
addEventHandler("onClientRender", root, renderizarInformacionVehiculo)

-- 4. Funciones de Navegación del Menú
local function actualizarVehiculoDeExhibicion()
    if not catalogoActual[indiceSeleccionado] then return end
    local info = catalogoActual[indiceSeleccionado]
    
    local modeloSeguro = tonumber(info.modelo_gta)
    local precioSeguro = tonumber(info.precio) or 0
    if not modeloSeguro then return end
    
    calcularDatosVehiculo(modeloSeguro, info.nombre_estetico, precioSeguro)
    if isElement(vehiculoExhibicion) then setElementModel(vehiculoExhibicion, modeloSeguro) end
end

local function navegarCatalogo(tecla)
    if not mostrandoDX or #catalogoActual == 0 then return end
    if tecla == "arrow_r" then
        indiceSeleccionado = indiceSeleccionado + 1
        if indiceSeleccionado > #catalogoActual then indiceSeleccionado = 1 end
    elseif tecla == "arrow_l" then
        indiceSeleccionado = indiceSeleccionado - 1
        if indiceSeleccionado < 1 then indiceSeleccionado = #catalogoActual end
    end
    actualizarVehiculoDeExhibicion()
end

-- ====================================================================
-- SOLICITUD DE COMPRA AL SERVIDOR (PASO 1)
-- ====================================================================
local function procesarCompra()
    if not mostrandoDX or #catalogoActual == 0 then return end
    local info = catalogoActual[indiceSeleccionado]
    
    outputChatBox("🛒 Enviando solicitud de compra para: " .. info.nombre_estetico .. "...", 0, 255, 255)
    
    -- Disparamos el evento al servidor pasando el ID interno del vehículo en tu tabla MySQL
    triggerServerEvent("dealership:procesarCompra", localPlayer, info.id)
end

-- 5. Presionar tecla E en el marcador
local function alPresionarTeclaE(tecla, estado, idTienda)
    if cargandoSala then return end
    local idReal = tonumber(idTienda) or 1
    cargandoSala = true
    outputChatBox("🏪 Solicitando catálogo a la base de datos...", 0, 255, 255)
    
    calleX, calleY, calleZ = getElementPosition(localPlayer)
    triggerServerEvent("dealership:solicitarCatalogo", localPlayer, idReal)
end

-- Reception desde el Servidor
addEvent("dealership:recibirCatalogo", true)
addEventHandler("dealership:recibirCatalogo", root, function(listaVehiculos)
    outputChatBox("📡 [CLIENTE] ¡Paquete recibido del servidor!", 0, 255, 0)

    if not listaVehiculos or type(listaVehiculos) ~= "table" or #listaVehiculos == 0 then
        outputChatBox("❌ [CLIENTE ERROR] El catálogo llegó vacío.", 255, 0, 0)
        cargandoSala = false
        return
    end

    catalogoActual = listaVehiculos
    indiceSeleccionado = 1 
    local primerVehiculo = catalogoActual[indiceSeleccionado]
    
    local modeloNumerico = tonumber(primerVehiculo.modelo_gta)
    local precioNumerico = tonumber(primerVehiculo.precio) or 0
    
    if not modeloNumerico then
        outputChatBox("❌ [CLIENTE ERROR] Modelo no numérico en BD.", 255, 0, 0)
        cargandoSala = false
        return
    end
    
    calcularDatosVehiculo(modeloNumerico, primerVehiculo.nombre_estetico, precioNumerico)
    mostrandoDX = true
    
    toggleAllControls(false, true, true)
    setElementFrozen(localPlayer, true)
    setElementAlpha(localPlayer, 0)
    
    local dimensionPrivada = 99
    setTime(12, 0)
    setWeather(1)
    
    setCameraInterior(0)
    setElementInterior(localPlayer, 0, -1656.3, 1209.6, 21.1)
    setElementDimension(localPlayer, dimensionPrivada)
    
    setCameraMatrix(-1664.0, 1218.0, 24.5, -1656.3, 1209.6, 21.5)
    
    if isElement(vehiculoExhibicion) then destroyElement(vehiculoExhibicion) end
    vehiculoExhibicion = createVehicle(modeloNumerico, -1656.3, 1209.6, 21.1, 0, 0, 0)
    
    if isElement(vehiculoExhibicion) then
        setElementDimension(vehiculoExhibicion, dimensionPrivada)
        setElementInterior(vehiculoExhibicion, 0)
        setElementCollisionsEnabled(vehiculoExhibicion, false)
        setElementFrozen(vehiculoExhibicion, true)
        outputChatBox("🚗 ¡Bienvenido a la sala de exhibición! BACKSPACE para volver.", 0, 255, 0)
    else
        outputChatBox("❌ Error al crear vehículo en sala.", 255, 0, 0)
        return
    end
    
    -- Vincular navegación y compras
    bindKey("arrow_r", "down", navegarCatalogo)
    bindKey("arrow_l", "down", navegarCatalogo)
    bindKey("enter", "down", procesarCompra)
    -- 🛑 VINCULAMOS BACKSPACE PARA SALIR SEGURO
    bindKey("backspace", "down", salirConcesionario)

    if isTimer(temporizadorRotacion) then killTimer(temporizadorRotacion) end
    temporizadorRotacion = setTimer(function()
        if not isElement(vehiculoExhibicion) then return end
        local rx, ry, rz = getElementRotation(vehiculoExhibicion)
        setElementRotation(vehiculoExhibicion, rx, ry, rz + 1)
    end, 50, 0)
end)

-- Eventos de Marcador
addEventHandler("onClientMarkerHit", root, function(elemento, dim)
    if elemento == localPlayer and dim then
        local idConcesionario = getElementData(source, "esConcesionario")
        if not idConcesionario then return end
        outputChatBox("🏪 Has entrado a un Concesionario. Presiona [E] para abrir el catálogo.", 255, 255, 0)
        bindKey("e", "down", alPresionarTeclaE, idConcesionario)
    end
end)

addEventHandler("onClientMarkerLeave", root, function(elemento)
    if elemento == localPlayer then
        local idConcesionario = getElementData(source, "esConcesionario")
        if not idConcesionario then return end 
        outputChatBox("👋 Saliste del rango del concesionario.", 200, 200, 200)
        unbindKey("e", "down", alPresionarTeclaE)
    end
end)

-- 7. SALIDA COMPLETA Y RESTAURACIÓN
salirConcesionario = function()
    mostrandoDX = false
    unbindKey("arrow_r", "down", navegarCatalogo)
    unbindKey("arrow_l", "down", navegarCatalogo)
    unbindKey("enter", "down", procesarCompra)
    unbindKey("backspace", "down", salirConcesionario) -- Desvinculamos el backspace
    
    setCameraTarget(localPlayer)
    
    if calleX == 0 and calleY == 0 then
        calleX, calleY, calleZ = -1657.0, 1205.0, 21.1 
    end
    
    setElementInterior(localPlayer, 0, calleX, calleY, calleZ)
    setElementDimension(localPlayer, 0) 
    setElementFrozen(localPlayer, false)
    toggleAllControls(true) 
    setElementAlpha(localPlayer, 255) 
    
    if isTimer(temporizadorRotacion) then killTimer(temporizadorRotacion) end
    if isElement(vehiculoExhibicion) then destroyElement(vehiculoExhibicion) end
    
    cargandoSala = false
    outputChatBox("🏪 Has regresado a la calle.", 255, 255, 0)
end
addCommandHandler("salirshop", salirConcesionario)

-- EVENTO PARA CERRAR LA INTERFAZ DESDE EL SERVIDOR TRAS COMPRA EXITOSA
addEvent("dealership:cerrarMenuCompra", true)
addEventHandler("dealership:cerrarMenuCompra", root, salirConcesionario)

addCommandHandler("testtienda", function()
    if cargandoSala then return end
    cargandoSala = true
    outputChatBox("✨ Forzando apertura manual...", 0, 255, 0)
    calleX, calleY, calleZ = getElementPosition(localPlayer)
    triggerServerEvent("dealership:solicitarCatalogo", localPlayer, 1)
end)