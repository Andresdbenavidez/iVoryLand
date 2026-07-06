-- ==========================================
-- REGISTRO DE CUENTAS
-- ==========================================
addEvent("core:solicitarRegistro", true)
addEventHandler("core:solicitarRegistro", root, function(usuario, contrasena)
    local cliente = client -- Jugador que gatilló el evento
    local bd = obtenerBD()

    -- Validaciones básicas
    if string.len(usuario) < 3 or string.len(contrasena) < 4 then
        triggerClientEvent(cliente, "core:respuestaAuth", cliente, false, "El usuario (min 3) o contraseña (min 4) son muy cortos.")
        return
    end

    -- Cifrar contraseña de forma segura (Hash Bcrypt)
    local contrasenaCifrada = passwordHash(contrasena, "bcrypt", {})

    -- Inserción asíncrona en MySQL usando callback
    dbQuery(function(queryHandle)
        local resultado, filasAfectadas, ultimoID = dbPoll(queryHandle, 0)
        
        if not resultado then
            triggerClientEvent(cliente, "core:respuestaAuth", cliente, false, "El nombre de usuario ya está registrado.")
        else
            outputDebugString("[Core-Auth] Cuenta registrada exitosamente en XAMPP: " .. usuario, 0, 0, 255, 0)
            triggerClientEvent(cliente, "core:respuestaAuth", cliente, true, "¡Registro exitoso! Ahora puedes iniciar sesión.")
        end
    end, bd, "INSERT INTO cuentas (usuario, contrasena) VALUES (?, ?)", string.lower(usuario), contrasenaCifrada)
end)

-- ==========================================
-- INICIO DE SESIÓN (LOGIN)
-- ==========================================
addEvent("core:solicitarLogin", true)
addEventHandler("core:solicitarLogin", root, function(usuario, contrasena)
    local cliente = client
    local bd = obtenerBD()

    -- Consulta asíncrona
    dbQuery(function(queryHandle)
        local resultados = dbPoll(queryHandle, 0)

        if not resultados or #resultados == 0 then
            triggerClientEvent(cliente, "core:respuestaAuth", cliente, false, "La cuenta no existe.")
            return
        end

        local datosCuenta = resultados[1]

        -- Verificar la contraseña enviada con el hash de la base de datos
        if passwordVerify(contrasena, datosCuenta.contrasena) then
            -- Guardar variables de sesión en memoria
            setElementData(cliente, "id_cuenta", datosCuenta.id)
            setElementData(cliente, "logeado", true)

            -- Avisar al cliente que el login fue exitoso (para que cierre la GUI)
            triggerClientEvent(cliente, "core:loginExitoso", cliente)
            
            -- ¡Aquí llamamos a la función que independizamos en spawn.lua!
            spawnearJugador(cliente, datosCuenta)

            outputChatBox("¡Bienvenido de vuelta, " .. usuario .. "!", cliente, 0, 255, 0)
            outputDebugString("[Core-Auth] Login exitoso: " .. usuario, 0)
        else
            triggerClientEvent(cliente, "core:respuestaAuth", cliente, false, "Contraseña incorrecta.")
        end
    end, bd, "SELECT * FROM cuentas WHERE usuario = ?", string.lower(usuario))
end)