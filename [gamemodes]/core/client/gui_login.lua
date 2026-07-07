-- Variables locales para guardar los elementos GUI en memoria
local VentanaLogin = nil
local EditUsuario = nil
local EditContrasena = nil
local BotonLogin = nil
local BotonRegistro = nil
local LabelEstado = nil

-- Función para construir y mostrar la interfaz en pantalla
function mostrarPanelAuth()
    -- Si la ventana ya existe, no la duplicamos
    if isElement(VentanaLogin) then return end

    -- Activamos la cámara panorámica
    activarCamaraLogin()

    -- 🛑 SOLUCCIÓN AL RATÓN: Forzamos a que aparezca el cursor del mouse en pantalla
    showCursor(true)

    -- 🛑 SOLUCCIÓN TÉCNICA DEFINITIVA A LAS LETRAS DEL CHAT (T, I, F, etc.):
    -- Esto bloquea por completo que los comandos/binds del juego se gatillen mientras escribes
    guiSetInputMode("no_binds_when_editing")

    -- Obtener la resolución de la pantalla del jugador para centrar la ventana perfecto
    local pantallaX, pantallaY = guiGetScreenSize()
    local ancho, alto = 320, 260
    local posX = (pantallaX / 2) - (ancho / 2)
    local posY = (pantallaY / 2) - (alto / 2)

    -- 1. Crear Ventana Principal
    VentanaLogin = guiCreateWindow(posX, posY, ancho, alto, "Servidor - Autenticación", false)
    guiWindowSetSizable(VentanaLogin, false) -- Evitar que el usuario la estire

    -- 2. Etiquetas e Inputs de Usuario
    guiCreateLabel(20, 35, 280, 20, "Nombre de Usuario:", false, VentanaLogin)
    EditUsuario = guiCreateEdit(20, 55, 280, 30, "", false, VentanaLogin)
    guiEditSetMaxLength(EditUsuario, 30)

    -- 3. Etiquetas e Inputs de Contraseña
    guiCreateLabel(20, 95, 280, 20, "Contraseña:", false, VentanaLogin)
    EditContrasena = guiCreateEdit(20, 115, 280, 30, "", false, VentanaLogin)
    guiEditSetMaxLength(EditContrasena, 50)
    -- ¡Importante! Ocultar texto para que se vean asteriscos (*)
    guiEditSetMasked(EditContrasena, true)

    -- 4. Botones
    BotonLogin = guiCreateButton(20, 160, 135, 35, "Iniciar Sesión", false, VentanaLogin)
    BotonRegistro = guiCreateButton(165, 160, 135, 35, "Registrarse", false, VentanaLogin)

    -- 5. Etiqueta inferior para mensajes de error o éxito
    LabelEstado = guiCreateLabel(20, 205, 280, 40, "Por favor ingresa tus datos.", false, VentanaLogin)
    guiLabelSetHorizontalAlign(LabelEstado, "center", true)
    guiLabelSetColor(LabelEstado, 200, 200, 200)

    -- ==========================================
    -- CAPTURA DE EVENTOS (CLICS)
    -- ==========================================
    
    -- Clic en INICIAR SESIÓN
    addEventHandler("onClientGUIClick", BotonLogin, function(boton, estado)
        if boton ~= "left" or estado ~= "up" then return end
        
        local usr = guiGetText(EditUsuario)
        local pass = guiGetText(EditContrasena)

        if usr == "" or pass == "" then
            guiSetText(LabelEstado, "Error: Llena todos los campos.")
            guiLabelSetColor(LabelEstado, 255, 50, 50)
            return
        end

        guiSetText(LabelEstado, "Conectando con el servidor...")
        guiLabelSetColor(LabelEstado, 255, 255, 0)
        
        -- Disparamos el evento hacia server/auth.lua
        triggerServerEvent("core:solicitarLogin", localPlayer, usr, pass)
    end, false)

    -- Clic en REGISTRARSE
    addEventHandler("onClientGUIClick", BotonRegistro, function(boton, estado)
        if boton ~= "left" or estado ~= "up" then return end
        
        local usr = guiGetText(EditUsuario)
        local pass = guiGetText(EditContrasena)

        if usr == "" or pass == "" then
            guiSetText(LabelEstado, "Error: Llena todos los campos.")
            guiLabelSetColor(LabelEstado, 255, 50, 50)
            return
        end

        guiSetText(LabelEstado, "Registrando cuenta en MySQL...")
        guiLabelSetColor(LabelEstado, 255, 255, 0)
        
        -- Disparamos el evento hacia server/auth.lua
        triggerServerEvent("core:solicitarRegistro", localPlayer, usr, pass)
    end, false)
end

-- Función para destruir la ventana cuando el login es exitoso
function cerrarPanelAuth()
    if isElement(VentanaLogin) then
        destroyElement(VentanaLogin)
        VentanaLogin = nil
    end
    
    -- 🔓 DEVOLVEMOS EL CONTROL AL JUEGO:
    -- Ocultamos el cursor del mouse y reactivamos las teclas nativas (como la T para chatear)
    showCursor(false)
    guiSetInputMode("allow_binds")
    
    desactivarCamaraLogin()
end

-- Abrir el panel automáticamente cuando se descarga el recurso en el cliente
addEventHandler("onClientResourceStart", resourceRoot, function()
    mostrarPanelAuth()
end)

-- ==========================================
-- RESPUESTAS DESDE EL SERVIDOR
-- ==========================================

-- Evento para recibir mensajes de error o confirmación de registro
addEvent("core:respuestaAuth", true)
addEventHandler("core:respuestaAuth", root, function(exito, mensaje)
    if not isElement(LabelEstado) then return end
    
    guiSetText(LabelEstado, mensaje)
    
    if exito then
        -- Si se registró bien, pintamos en verde
        guiLabelSetColor(LabelEstado, 50, 255, 50)
    else
        -- Si hubo error (ej. usuario duplicado), pintamos en rojo
        guiLabelSetColor(LabelEstado, 255, 50, 50)
    end
end)

-- Evento cuando el servidor aprueba el login
addEvent("core:loginExitoso", true)
addEventHandler("core:loginExitoso", root, function()
    -- Cerramos GUI y devolvemos el control al personaje
    cerrarPanelAuth()
end)