dkjson = package.loaded['game/dkjson']
local GameControl = require("lua/GameControl")
local DQN = require("lua/dqn")

-- Generated from template
if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
	print( "Template addon is loaded." )

	GameRules:GetGameModeEntity():SetFixedRespawnTime(1)

	----------- Create Hero
	GameRules:GetGameModeEntity():SetCustomGameForceHero(GameControl.nameHero)
	CreateUnitByName( GameControl.nameHero ,  RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
	
	SendToServerConsole( "dota_all_vision 1" )

	----------- Set Event Listener
	ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CAddonTemplateGameMode, 'OnEntity_hurt' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CAddonTemplateGameMode, 'OnEntity_kill' ), self )
	ListenToGameEvent( "player_chat", Dynamic_Wrap( CAddonTemplateGameMode, 'OnInitial' ), self ) ---- when player chat the game will reset

end

function CAddonTemplateGameMode:OnInitial()	
	GameControl:InitialValue()

	ai_state = STATE_GETMODEL
	check_done = false
	check_send = false
	all_reward = {}
	all_reward['Radian'] = 0
	all_reward['Dire'] = 0
	reward = {}
	reward['Radian'] = 0
	reward['Dire'] = 0

	GameControl.enemyHero['object']:Stop()

	state = {}
	new_state = {}
	action = {}

	episode = 0

	GameRules:GetGameModeEntity():SetThink( "state_loop", self, 1)

end

STATE_GETMODEL = 0
-- STATE_GETMODEL2 = 1
STATE_SIMULATING = 2
STATE_UPDATEMODEL = 3
STATE_UPDATEMODEL2 = 4

baseURL = "http://localhost:5000"
-- baseURLEnemy = "http://localhost:4000"

function CAddonTemplateGameMode:state_loop()
	timestate = 3

	if ai_state == STATE_GETMODEL then
		request = CreateHTTPRequestScriptVM( "GET", baseURL .. "/model")
		request:Send( 	function( result ) 
							if result["StatusCode"] == 200 and ai_state == STATE_GETMODEL then
								local data = package.loaded['game/dkjson'].decode(result['Body'])
								-- self:UpdateModel(data)
								dqn_agent = DQN.new(data['num_input'], data['num_output'], data['hidden'])
								print("gettt")
								dqn_agent.weight_array = data['weights_all']
								dqn_agent.bias_array = data['bias_all']
								
								ai_state = STATE_SIMULATING		

								GameRules:GetGameModeEntity():SetThink( "bot_loop", self)	
								GameRules:GetGameModeEntity():SetThink( "botEnemy_loop", self)	

								state['Radian'] = GameControl:getState(GameControl.TEAM_RADIAN)								
								state['Dire'] = GameControl:getState(GameControl.TEAM_DIRE)
								
							end
						end )

	elseif ai_state == STATE_SIMULATING then
		check_send = false
	elseif ai_state == STATE_UPDATEMODEL then
		if check_send == false then
			check_send = true
			data_send = {}
			data_send['mem'] = dqn_agent.memory
			data_send['all_reward'] = all_reward['Radian']
			data_send['team'] = GameControl.TEAM_RADIAN
			print('update')
			request = CreateHTTPRequestScriptVM( "POST", baseURL .. "/update")
			request:SetHTTPRequestHeaderValue("Accept", "application/json")		
			request:SetHTTPRequestRawPostBody('application/json', package.loaded['game/dkjson'].encode(data_send))
			request:Send( 	function( result ) 
								if result["StatusCode"] == 200 and ai_state == STATE_UPDATEMODEL then  

									print("get update1")

									---### don't need update
									-- local data = package.loaded['game/dkjson'].decode(result['Body'])
									-- dqn_agent.weight_array = data['weights_all']
									-- dqn_agent.bias_array = data['bias_all']     
									dqn_agent.memory = {}         														
									check_send = false
									all_reward['Radian'] = 0
									reward['Radian'] = 0
									ai_state = STATE_UPDATEMODEL2	

								end
							end )
		end
		-- timestate = 10
	elseif ai_state == STATE_UPDATEMODEL2 then
		if check_send == false then
			check_send = true
			data_send = {}
			data_send['mem'] = dqn_agent.memory2
			data_send['all_reward'] = all_reward['Dire']
			data_send['team'] = GameControl.TEAM_DIRE
			print('update2')
			request = CreateHTTPRequestScriptVM( "POST", baseURL .. "/update")
			request:SetHTTPRequestHeaderValue("Accept", "application/json")		
			request:SetHTTPRequestRawPostBody('application/json', package.loaded['game/dkjson'].encode(data_send))
			request:Send( 	function( result ) 
								print(result["StatusCode"])
								if result["StatusCode"] == 200 and ai_state == STATE_UPDATEMODEL2 then  
									-- Say(hero, "Model Updated", false)
									print("get update2")
									local data = package.loaded['game/dkjson'].decode(result['Body'])
									dqn_agent.weight_array = data['weights_all']
									dqn_agent.bias_array = data['bias_all']     
									dqn_agent.memory2 = {} 

									all_reward['Dire'] = 0	
									reward['Dire'] = 0				
																	
									GameRules:GetGameModeEntity():SetThink( "change_state", self )								
																
								end
							end )
		end

	else
		Warning("Some shit has gone bad..")
	end
	-- print(ai_state)
	
	return timestate
end


function CAddonTemplateGameMode:change_state()
	GameControl:resetThing()	

	state['Radian'] = GameControl:getState(GameControl.TEAM_RADIAN)
	state['Dire'] = GameControl:getState(GameControl.TEAM_DIRE)

	ai_state = STATE_SIMULATING	
	check_done = false
	check_send = false
	print("finish update")
	return nil
end


function CAddonTemplateGameMode:bot_loop()
	-- print(ai_state)
	if ai_state ~= STATE_SIMULATING then
		return 0.2
	end

	new_state['Radian'] =  GameControl:getState(GameControl.TEAM_RADIAN)

	if check_done then

		-- radian
		dqn_agent:remember({state['Radian'], action['Radian'], reward['Radian'], new_state['Radian'],true})
		print("reward Radian: "..reward['Radian'])
		all_reward['Radian'] = all_reward['Radian'] + reward['Radian']
		reward['Radian'] = 0	
		
		
		-- dire
		dqn_agent:remember2({state['Dire'], action['Dire'], reward['Dire'], new_state['Dire'],true})
		print("reward Dire: "..reward['Dire'])
		all_reward['Dire'] = all_reward['Dire'] + reward['Dire']
		reward['Dire'] = 0	
		print("All reward: "..all_reward['Radian'].." "..all_reward['Dire'])


		episode = episode + 1
		ai_state = STATE_UPDATEMODEL
	
	else
		
		dqn_agent:remember({state['Radian'], action['Radian'], reward['Radian'], new_state['Radian'],false})
		
		all_reward['Radian'] = all_reward['Radian'] + reward['Radian']
		reward['Radian'] = 0
	end

	state['Radian'] = new_state['Radian']
	-- ------------------------
	if episode % 10 == 0 then  --- force learning		
		action['Radian'] = GameControl:hero_force_think(GameControl.TEAM_RADIAN)
	elseif episode % 15 == 0 then
		action['Radian'] = GameControl:hero_force_think2(GameControl.TEAM_RADIAN)
	else
		action['Radian'] = dqn_agent:act(state['Radian']) - 1
		-- print("act--")
	end
	-- action['Radian'] = 1
	-- print( GameControl.hero['object']:GetAngles()[2] )

	-- print("action :"..action['Radian'] )

	local time_return = GameControl:runAction(action['Radian'], state['Radian'], GameControl.TEAM_RADIAN)
	-- print( GameRules:GetGameTime())
	
	return time_return

end

function CAddonTemplateGameMode:botEnemy_loop()
	-- print(ai_state)
	if ai_state ~= STATE_SIMULATING then
		return 0.2
	end

	new_state['Dire'] =  GameControl:getState(GameControl.TEAM_DIRE)
	GameControl.enemyHero['object']:Stop()
	if check_done == false then
		-- dqn_agent:remember2({state['Dire'], action['Dire'], reward['Dire'], new_state['Dire'], false})
		all_reward['Dire'] = all_reward['Dire'] + reward['Dire']
		reward['Dire'] = 0
	end

	state['Dire'] = new_state['Dire']
	------------------------
	-- if episode % 2 == 0 then  --- force learning
		
		action['Dire'] = GameControl:hero_force_think2(GameControl.TEAM_DIRE)
	-- else
		-- action['Dire'] = dqn_agent:act(state['Dire']) - 1
	-- end

	local time_return = GameControl:runAction(action['Dire'], state['Dire'], GameControl.TEAM_DIRE)
	
	return time_return

end


function CAddonTemplateGameMode:OnEntity_kill(event)
	local killed = EntIndexToHScript(event.entindex_killed);
	local attaker = EntIndexToHScript(event.entindex_attacker );

	if(killed:GetName() == GameControl.nameHero )then
		if check_done == false then
			if killed:GetTeam() == DOTA_TEAM_GOODGUYS then
				-- reward['Radian'] = -1000
				reward['Dire'] = 100
			else 
				reward['Radian'] = 100
				-- reward['Dire'] = -1000
			end
			print("die-------")
			check_done = true
		end		
	end
end


function CAddonTemplateGameMode:OnEntity_hurt(event)

	local killed = EntIndexToHScript(event.entindex_killed);
	local attaker = EntIndexToHScript(event.entindex_attacker );
	local damage = event.damagebits
	-- print(killed:GetName())
	if(killed == GameControl.hero['object'] )then
		local cur_health = GameControl.hero['object']:GetHealth()
		if ( cur_health - GameControl.hero['old_health'] ) < -150 then
			reward['Dire'] = 10
			print("skill")
		end
		GameControl.hero['old_health'] = cur_health
	end

	if(killed == GameControl.enemyHero['object'] )then
		local cur_health = GameControl.enemyHero['object']:GetHealth()
		if ( cur_health - GameControl.enemyHero['old_health'] ) < -150 then
			reward['Radian'] = 10
			print("skill")
		end
		GameControl.enemyHero['old_health'] = cur_health
	end

end