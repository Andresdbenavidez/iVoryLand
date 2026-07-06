addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Ocultamos el radar predeterminado si tienes pensado hacer uno moderno más adelante
    -- showPlayerHudComponent("radar", false)
    
    outputConsole("[Core-Client] Interfaz y módulos de cámara inicializados.")
end)