local GameControl = {}
GameControl.__index = table

GameControl.nameHero = "npc_dota_hero_nevermore"

GameControl.number_creep = 1

GameControl.TEAM_RADIAN = 0
GameControl.TEAM_DIRE = 1

GameControl.hero = {}
GameControl.enemyHero = {}

function GameControl:InitialValue()

	--------- Hero Find
	allHero =  Entities:FindAllByName(GameControl.nameHero)
	for idx,hero in pairs( allHero ) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			GameControl.hero['object'] = hero
		else	
			GameControl.enemyHero['object'] = hero
		end
	end



	---- Hero
	GameControl.hero['ability'] = {}
	GameControl.hero['object']:AddExperience(50000,0,false,false)
	GameControl.hero['object']:SetBaseManaRegen(3)
	for i = 0,2 do
		GameControl.hero['ability'][i] = GameControl.hero['object']:GetAbilityByIndex(i)
	end

	for i = 0,2 do
		GameControl.hero['ability'][0]:UpgradeAbility(false)
	end
	GameControl.hero['old_health'] = GameControl.hero['object']:GetMaxHealth()

	---- Enemy
	GameControl.enemyHero['ability'] = {}
	GameControl.enemyHero['object']:AddExperience(50000,0,false,false)
	GameControl.enemyHero['object']:SetBaseManaRegen(3)
	for i = 0,2 do
		GameControl.enemyHero['ability'][i] = GameControl.enemyHero['object']:GetAbilityByIndex(i)
		
	end
	
	for i = 0,3 do
		GameControl.enemyHero['ability'][0]:UpgradeAbility(false)
	end
	GameControl.enemyHero['old_health'] = GameControl.enemyHero['object']:GetMaxHealth()
	print( GameControl.enemyHero['ability'][0]:GetCastRange() )

	GameControl:resetThing() 


end

function GameControl:resetThing() 
	FindClearSpaceForUnit(GameControl.hero['object'], RandomVector(1000) , true)
	FindClearSpaceForUnit(GameControl.enemyHero['object'], RandomVector(1000) , true)
	--RandomVector( RandomFloat( 0, 200 ))
	GameControl.hero['object']:SetHealth( GameControl.hero['object']:GetMaxHealth() )
	GameControl.enemyHero['object']:SetHealth( GameControl.enemyHero['object']:GetMaxHealth() )
end


--[[
        Run Function
--]] 

function GameControl:runAction(action, state, team)
	
	local hero = nil
	local enemyHero = nil

	if team == GameControl.TEAM_RADIAN then
		hero = GameControl.hero
		enemyhero = GameControl.enemyHero
	else
		hero = GameControl.enemyHero
		enemyhero = GameControl.hero
	end

	if action == 0 then
		hero['object']:Stop()
		return 0.1

	elseif action == 1 then -- spin
		local old_yaw = hero['object']:GetAngles()
		hero['object']:SetAngles(0, old_yaw+10%360, 0)
		return 0.02

	elseif action == 2 then --- forward
		local forward_vector = hero['object']:GetForwardVector()
		hero['object']:MoveToPosition(forward_vector + 100)
		return 0.2

	elseif action == 3 then --- cast skill 1 
		hero['ability'][0]:CastAbility()
		return 0.8

	elseif action == 4 then --- cast skill 2
		hero['ability'][1]:CastAbility()
		return 0.8

	elseif action == 5 then --- cast skill 3
		hero['ability'][2]:CastAbility()
		return 0.8

	elseif action == 6 then --- attack
		hero['object']:MoveToTargetToAttack(enemyhero['object'])
		return 0.8
		
	end

end

--[[
        Agent Function
--]] 
function GameControl:getState(team)
	local stateArray = {}

	local hero = nil
	local enemyHero = nil

	if team == GameControl.TEAM_RADIAN then
		hero = GameControl.hero
		enemyhero = GameControl.enemyHero
	else
		hero = GameControl.enemyHero
		enemyhero = GameControl.hero
	end

	local objPosition = hero['object']:GetAbsOrigin()
	local objPositionEnemy = enemyhero['object']:GetAbsOrigin()

	stateArray[1] = hero['object']:GetHealth() / hero['object']:GetMaxHealth()
	stateArray[2] = objPosition.x
	stateArray[3] = objPosition.y 
	stateArray[4] = hero['object']:TimeUntilNextAttack()
	stateArray[5] = hero['ability'][0]:GetCooldown()
	stateArray[6] = hero['ability'][1]:GetCooldown()
	stateArray[7] = hero['ability'][2]:GetCooldown()

	stateArray[8] = enemyhero['object']:GetHealth() / enemyhero['object']:GetMaxHealth()
	stateArray[9] = objPositionEnemy.x
	stateArray[10] = objPositionEnemy.y 
	stateArray[11] = enemyhero['object']:TimeUntilNextAttack()
	stateArray[12] = enemyhero['ability'][0]:GetCooldown()
	stateArray[13] = enemyhero['ability'][1]:GetCooldown()
	stateArray[14] = enemyhero['ability'][2]:GetCooldown()

	return stateArray


end

--[[
        Enemy Function
--]] 
function GameControl:hero_force_think(team)

	local hero = nil
	local enemyHero = nil

	if team == GameControl.TEAM_RADIAN then
		hero = GameControl.hero
		enemyhero = GameControl.enemyHero
	else
		hero = GameControl.enemyHero
		enemyhero = GameControl.hero
	end


	local distance = CalcDistanceBetweenEntityOBB( hero, enemyHero)
	local range1 = GameControl.enemyHero['ability'][0]:GetCastRange()
	local range2 = GameControl.enemyHero['ability'][1]:GetCastRange()
	local range3 = GameControl.enemyHero['ability'][2]:GetCastRange()

	local cooldown1 = GameControl.enemyHero['ability'][0]:GetCooldown()
	local cooldown2 = GameControl.enemyHero['ability'][1]:GetCooldown()
	local cooldown3 = GameControl.enemyHero['ability'][2]:GetCooldown()

	if  (distance > range1 - 50) and (distance < range1 + 50) and cooldown1 == 0 then
		return 3
	elseif (distance > range2 - 50) and (distance < range2 + 50) and cooldown2 == 0 then
		return 4 
	elseif (distance > range3 - 50) and (distance < range3 + 50) and cooldown3 == 0 then
		return 5
	else
		return 6
	end
end

--[[
        Other Function
--]] 

function GameControl:shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function normalize(value, min, max)
	return (value - min) / (max - min)
end

return GameControl

