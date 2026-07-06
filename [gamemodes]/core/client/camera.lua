-- Función para activar el modo "espectador" de login
function activarCamaraLogin()
    -- Desvanecer la pantalla y mostrar el cursor del mouse
    fadeCamera(true)
    showCursor(true)
    
    -- Congelar al jugador para que no caiga por el mapa
    setElementFrozen(localPlayer, true)
    
    -- Colocar la cámara en una vista panorámica (En este caso, mirando hacia Los Santos)
    -- setCameraMatrix(PosX, PosY, PosZ, MirarX, MirarY, MirarZ)
    setCameraMatrix(1468.87, -919.25, 100.15, 1468.38, -918.42, 99.88)
end

-- Función para volver a la cámara normal cuando inicia sesión
function desactivarCamaraLogin()
    -- Devolver la cámara al personaje
    setCameraTarget(localPlayer)
    showCursor(false)
    setElementFrozen(localPlayer, false)
end