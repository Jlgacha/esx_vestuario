local HasAlreadyEnteredMarker, isInJail, unJail = false, false, false
local LastZone, CurrentAction, CurrentActionMsg
local CurrentActionData = {}
ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end
end)

function OpenVestuariosMenu()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'vestuarios_menu',
        {
            title    = 'Vestuario Hospital',
            elements = {
                {label = 'Ropa Civil', value = 'civil'},
                {label = 'Ropa Paciente', value = 'paciente'} 
            }  
        },
        function(data, menu)
            if data.current.value == 'civil' then
                TriggerEvent('esx_vestuarios:ropaCivil')
                print("Ropa de civil cargada")
				exports['mythic_notify']:SendAlert('inform', 'Te acabas de poner la ropa de civil')
				menu.close()
        elseif data.current.value == 'paciente' then
                TriggerEvent('esx_vestuarios:ropaPaciente')
                print("Ropa de paciente cargada")
                exports['mythic_notify']:SendAlert('inform', 'Te acabas de poner la ropa de paciente')
                menu.close()     
            end  
        end,   
        function(data, menu)
            menu.close() 
        end 
    )
end 
  
RegisterNetEvent('esx_vestuarios:ropaCivil')
AddEventHandler('esx_vestuarios:ropaCivil', function()

	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:loadSkin', skin)
	end) 
end)   

RegisterNetEvent('esx_vestuarios:ropaPaciente')
AddEventHandler('esx_vestuarios:ropaPaciente', function()
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
		TriggerEvent('skinchanger:getSkin', function(skin)
			if skin.sex == 0 then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.paciente.male)
			else
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.paciente.female)
			end
        end)
    end
end) 

AddEventHandler('esx_vestuarios:hasEnteredMarker', function(zone)
	CurrentAction = 'vestuarios_menu'
	CurrentActionMsg = "Presiona ~INPUT_CONTEXT~ para acceder al Vestuario"
	CurrentActionData = {}
end)

-- Exited Marker
AddEventHandler('esx_vestuarios:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)
 
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		ESX.UI.Menu.CloseAll()
	end
end)

-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true

		for k,v in pairs(Config.Zones) do
			local distance = #(playerCoords - v.Coords)

			if distance < Config.DrawDistance then
				letSleep = false

				if Config.MarkerInfo.Type ~= -1 then
					DrawMarker(Config.MarkerInfo.Type, v.Coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerInfo.x, Config.MarkerInfo.y, Config.MarkerInfo.z, Config.MarkerInfo.r, Config.MarkerInfo.g, Config.MarkerInfo.b, 100, false, true, 2, false, false, false, false)
				end

				if distance < Config.MarkerInfo.x then
					isInMarker, currentZone = true, k
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			TriggerEvent('esx_vestuarios:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_vestuarios:hasExitedMarker', LastZone)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end	
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'vestuarios_menu' then
					OpenVestuariosMenu()
				end
 
				CurrentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)