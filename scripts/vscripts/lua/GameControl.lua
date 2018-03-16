local GameControl = {}
GameControl.__index = table

GameControl.nameHero = "npc_dota_hero_nevermore"

GameControl.number_creep = 1

GameControl.TEAM_RADIAN = 0
GameControl.TEAM_DIRE = 1

GameControl.hero = {}
GameControl.enemyHero = {}

SPIN_RETREAT_HERO_STATE = 0
WALK_RETREAT_HERO_STATE = 1
ATTACK_HERO_STATE = 2
SKILL_1_HERO_STATE = 3
SKILL_2_HERO_STATE = 4
SKILL_3_HERO_STATE = 5
IDLE_HERO_STATE = 6


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
	-- GameControl.hero['object']:SetBaseManaRegen(3)
	for i = 0,2 do
		GameControl.hero['ability'][i] = GameControl.hero['object']:GetAbilityByIndex(i)
	end

	for i = 0,3 do
		GameControl.hero['ability'][0]:UpgradeAbility(false)
	end
	GameControl.hero['old_health'] = GameControl.hero['object']:GetMaxHealth()
	PlayerResource:SetCameraTarget(GameControl.hero['object']:GetPlayerID(), GameControl.hero['object'])
	GameControl.hero['state'] = SKILL_3_HERO_STATE

	---- Enemy
	GameControl.enemyHero['ability'] = {}
	GameControl.enemyHero['object']:AddExperience(50000,0,false,false)
	-- GameControl.enemyHero['object']:SetBaseManaRegen(3)
	for i = 0,2 do
		GameControl.enemyHero['ability'][i] = GameControl.enemyHero['object']:GetAbilityByIndex(i)
		
	end
	
	for i = 0,3 do
		GameControl.enemyHero['ability'][0]:UpgradeAbility(false)
	end
	GameControl.enemyHero['old_health'] = GameControl.enemyHero['object']:GetMaxHealth()
	GameControl.enemyHero['state'] = SKILL_3_HERO_STATE

	print( GameControl.enemyHero['ability'][0]:GetCastRange() )

	GameControl:resetThing() 


end

function GameControl:resetThing() 
	FindClearSpaceForUnit(GameControl.hero['object'], RandomVector(1000) , true)
	FindClearSpaceForUnit(GameControl.enemyHero['object'], Vector(1300,1300,0) , true)
	--RandomVector( RandomFloat( 0, 200 ))
	GameControl.hero['object']:SetHealth( GameControl.hero['object']:GetMaxHealth() )
	GameControl.enemyHero['object']:SetHealth( GameControl.enemyHero['object']:GetMaxHealth() )

	GameControl.hero['object']:SetMana( GameControl.hero['object']:GetMaxMana() )
	GameControl.enemyHero['object']:SetMana( GameControl.enemyHero['object']:GetMaxMana() )
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

	elseif action == 1 then -- spin left + 
		local old_yaw = hero['object']:GetAngles()
		hero['object']:Stop()
		hero['object']:SetAngles(0, (old_yaw[2]+20)%360, 0)
		--print("spin")
		return 0.002
	elseif action == 2 then --- forward
		local forward_vector = hero['object']:GetForwardVector()
		hero['object']:Stop()
		hero['object']:MoveToPosition( hero['object']:GetAbsOrigin() + forward_vector*100)
		return 0.2

	elseif action == 3 then --- cast skill 1 
		if  hero['ability'][0]:GetCooldownTimeRemaining() == 0 then
			hero['object']:Stop()
			hero['object']:CastAbilityNoTarget( hero['ability'][0], hero['object']:GetPlayerOwnerID() )
			return 1
		else
			return 0.1
		end

	elseif action == 4 then --- cast skill 2
		if  hero['ability'][1]:GetCooldownTimeRemaining() == 0 then
			hero['object']:Stop()
			hero['object']:CastAbilityNoTarget( hero['ability'][1], hero['object']:GetPlayerOwnerID() )
			return 1
		else
			return 0.1
		end

	elseif action == 5 then --- cast skill 3
		if  hero['ability'][2]:GetCooldownTimeRemaining() == 0 then
			hero['object']:Stop()
			hero['object']:CastAbilityNoTarget( hero['ability'][2], hero['object']:GetPlayerOwnerID() )
			return 1
		else
			return 0.1
		end

	elseif action == 6 then --- attack
		local distance = CalcDistanceBetweenEntityOBB( hero['object'], enemyhero['object'])
		if distance < hero['object']:GetAttackRange() or team == GameControl.TEAM_DIRE then
			hero['object']:Stop()
			hero['object']:MoveToTargetToAttack(enemyhero['object'])
			return 0.5
		else
			return 0.1
		end
	elseif action == 7 then -- spin right
		local old_yaw = hero['object']:GetAngles()
		local new_yaw = old_yaw[2] - 20
		if new_yaw < 0 then 
			new_yaw = new_yaw + 360
		end
		hero['object']:Stop()
		hero['object']:SetAngles(0, new_yaw, 0)
		-- print("spin")
		return 0.002	
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
	
	local yaw = hero['object']:GetAngles()[2]

	local angleTarget = angle360( objPosition.x, objPosition.y, objPositionEnemy.x, objPositionEnemy.y )

	local distance = CalcDistanceBetweenEntityOBB( hero['object'], enemyhero['object'])

	stateArray[1] = setRange( hero['object']:GetHealth() / hero['object']:GetMaxHealth() )
	stateArray[2] = setRange( objPosition.x / 1500 )
	stateArray[3] = setRange( objPosition.y / 1500 )
	stateArray[4] = setRange( hero['object']:TimeUntilNextAttack() )
	stateArray[5] = setRange( hero['ability'][0]:GetCooldownTimeRemaining() / hero['ability'][0]:GetCooldown(4) )
	stateArray[6] = setRange( hero['ability'][1]:GetCooldownTimeRemaining() / hero['ability'][1]:GetCooldown(4) )
	stateArray[7] = setRange( hero['ability'][2]:GetCooldownTimeRemaining() / hero['ability'][2]:GetCooldown(4) )
	stateArray[8] = setRange( ( angleTarget - yaw ) / 360 )
	stateArray[9] = setRange( hero['object']:GetMana() / hero['object']:GetMaxMana() )

	stateArray[10] = setRange( enemyhero['object']:GetHealth() / enemyhero['object']:GetMaxHealth() )
	stateArray[11] = setRange( objPositionEnemy.x / 1500 )
	stateArray[12] = setRange( objPositionEnemy.y / 1500 )
	stateArray[13] = setRange( enemyhero['object']:TimeUntilNextAttack() )
	stateArray[14] = setRange( enemyhero['ability'][0]:GetCooldownTimeRemaining() / enemyhero['ability'][0]:GetCooldown(4) )
	stateArray[15] = setRange( enemyhero['ability'][1]:GetCooldownTimeRemaining() / enemyhero['ability'][1]:GetCooldown(4) )
	stateArray[16] = setRange( enemyhero['ability'][2]:GetCooldownTimeRemaining() / enemyhero['ability'][2]:GetCooldown(4) )
	stateArray[17] = setRange( enemyhero['object']:GetMana() / enemyhero['object']:GetMaxMana() )

	stateArray[18] = setRange( distance / 3000 )

	-- for key,value in pairs(stateArray)do
	-- 	print(key.." "..value)
	-- end

	return stateArray


end

--[[
        Enemy Function
--]] 
function GameControl:hero_force_think3(team)

	local hero = nil
	local enemyHero = nil

	if team == GameControl.TEAM_RADIAN then
		hero = GameControl.hero
		enemyhero = GameControl.enemyHero
	else
		hero = GameControl.enemyHero
		enemyhero = GameControl.hero
	end


	local distance = CalcDistanceBetweenEntityOBB( hero['object'], enemyhero['object'])
	local range1 = hero['ability'][0]:GetCastRange()
	local range2 = hero['ability'][1]:GetCastRange()
	local range3 = hero['ability'][2]:GetCastRange()

	local cooldown1 = hero['ability'][0]:GetCooldownTimeRemaining()
	local cooldown2 = hero['ability'][1]:GetCooldownTimeRemaining()
	local cooldown3 = hero['ability'][2]:GetCooldownTimeRemaining()
	

	local objPosition = hero['object']:GetAbsOrigin()
	local objPositionEnemy = enemyhero['object']:GetAbsOrigin()

	local yaw = hero['object']:GetAngles()[2]

	local angleTarget = angle360( objPosition.x, objPosition.y, objPositionEnemy.x, objPositionEnemy.y )
	local cond = cooldown1 > 0 and cooldown2 > 0  and cooldown3 > 0


	local d1 = angleTarget - yaw
	local d2 = nil
	if angleTarget > yaw then
		d2 = angleTarget - (yaw +360)
	else
		d2 = (angleTarget+360) - yaw
	end

	local resultAngle = 0
	if math.abs(d1) < math.abs(d2) then
		resultAngle = d1
	else
		resultAngle = d2
	end
	
	

	local prob = math.random()
	--print("resultAngle:"..resultAngle)
	if cond or cooldown3 > 0 then
		local forwardPos = hero['object']:GetAbsOrigin() + hero['object']:GetForwardVector()*100

		if math.abs(resultAngle) < 130 then
			return 1
		else
			return 2
		end

	else -- have skill
		if math.abs(resultAngle)  < 10 then -- right direct
			if  (distance > range1 - 50) and (distance < range1 + 50) and cooldown1 == 0 then
				return 3
			elseif (distance > range2 - 50) and (distance < range2 + 50) and cooldown2 == 0 then
				return 4 
			elseif (distance > range3 - 50) and (distance < range3 + 50) and cooldown3 == 0 then
				return 5
			elseif prob < 0.5 then
				return 5
			else 
				return 6		
			end
		else -- not right direct
			if resultAngle > 0   then -- counter clock
				return 1
			else -- clock wise
				return 7
			end
		end
	end
end

function GameControl:hero_force_think2(team)

	local hero = nil
	local enemyHero = nil

	if team == GameControl.TEAM_RADIAN then
		hero = GameControl.hero
		enemyhero = GameControl.enemyHero
	else
		hero = GameControl.enemyHero
		enemyhero = GameControl.hero
	end


	local distance = CalcDistanceBetweenEntityOBB( hero['object'], enemyhero['object'])
	local range1 = hero['ability'][0]:GetCastRange()
	local range2 = hero['ability'][1]:GetCastRange()
	local range3 = hero['ability'][2]:GetCastRange()

	local cooldown1 = hero['ability'][0]:GetCooldownTimeRemaining()
	local cooldown2 = hero['ability'][1]:GetCooldownTimeRemaining()
	local cooldown3 = hero['ability'][2]:GetCooldownTimeRemaining()

	local prob = math.random()
	-- print("dis:"..distance)
	if  (distance > range1 - 200) and (distance < range1 + 200) and cooldown1 == 0 then
		return 3
	elseif (distance > range2 - 200) and (distance < range2 + 200) and cooldown2 == 0 then
		return 4 
	elseif (distance > range3 - 200) and (distance < range3 + 200) and cooldown3 == 0 then
		return 5

	else
		return 6
	end
end

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


	local distance = CalcDistanceBetweenEntityOBB( hero['object'], enemyhero['object'])
	local range1 = hero['ability'][0]:GetCastRange()
	local range2 = hero['ability'][1]:GetCastRange()
	local range3 = hero['ability'][2]:GetCastRange()

	local cooldown1 = hero['ability'][0]:GetCooldownTimeRemaining()
	local cooldown2 = hero['ability'][1]:GetCooldownTimeRemaining()
	local cooldown3 = hero['ability'][2]:GetCooldownTimeRemaining()
	

	local objPosition = hero['object']:GetAbsOrigin()
	local objPositionEnemy = enemyhero['object']:GetAbsOrigin()

	local yaw = hero['object']:GetAngles()[2]

	local angleTarget = angle360( objPosition.x, objPosition.y, objPositionEnemy.x, objPositionEnemy.y )
	local cond = cooldown1 > 0 and cooldown2 > 0  and cooldown3 > 0


	local d1 = angleTarget - yaw
	local d2 = nil
	if angleTarget > yaw then
		d2 = angleTarget - (yaw +360)
	else
		d2 = (angleTarget+360) - yaw
	end

	local resultAngle = 0
	if math.abs(d1) < math.abs(d2) then
		resultAngle = d1
	else
		resultAngle = d2
	end
	
	-- print("state: "..hero['state'])

	if hero['state'] == SPIN_RETREAT_HERO_STATE then
		-- print(math.abs(resultAngle) )
		if math.abs(resultAngle) < 130 then
			return 1
		else
			hero['state'] = WALK_RETREAT_HERO_STATE
			return 2
		end

	elseif hero['state'] == WALK_RETREAT_HERO_STATE then
		local forwardPos = hero['object']:GetAbsOrigin() + hero['object']:GetForwardVector()*100
		if forwardPos.x > 1400 or forwardPos.x < -1400 or forwardPos.y > 1400 or forwardPos.y < -1400 then --- hit edge stadium
			return 1
		else
			-- print("distance :"..distance)
			if cooldown1 == 0 and distance > range1 - 200 then
				hero['state'] = IDLE_HERO_STATE
			elseif cooldown2 == 0 and distance > range2 - 200 then
				hero['state'] = IDLE_HERO_STATE
			elseif cooldown3 == 0 and distance > range3 - 200 then 
				hero['state'] = IDLE_HERO_STATE
			end
			return 2
		end

	elseif hero['state'] == ATTACK_HERO_STATE then
		hero['state'] = IDLE_HERO_STATE
		return 6

	elseif hero['state'] == SKILL_1_HERO_STATE then
		return useSkill(range1,resultAngle,distance,hero)
		
	elseif hero['state'] == SKILL_2_HERO_STATE then
		return useSkill(range2,resultAngle,distance,hero)

	elseif hero['state'] == SKILL_3_HERO_STATE then
		return useSkill(range3,resultAngle,distance,hero)

	elseif hero['state'] == IDLE_HERO_STATE then
		if hero['object']:GetMana() < 90  then
			hero['state'] = ATTACK_HERO_STATE

		elseif cooldown3 == 0 then
			hero['state'] = SKILL_3_HERO_STATE
		elseif cooldown2 == 0 then
			hero['state'] = SKILL_2_HERO_STATE
		elseif cooldown1 == 0 then
			hero['state'] = SKILL_1_HERO_STATE
		else 
			hero['state'] = SPIN_RETREAT_HERO_STATE
		end

		return 0
	end

	
	
end


function useSkill(numskill,resultAngle,distance,hero)
	if math.abs(resultAngle) < 10 then  -- right direction
		if (distance > numskill - 200) and (distance < numskill + 200) then
			local value = nil
			if hero['state'] == SKILL_1_HERO_STATE then
				value = 3
			elseif hero['state'] == SKILL_2_HERO_STATE then
				value = 4
			elseif hero['state'] == SKILL_3_HERO_STATE then
				value = 5
			end

			hero['state'] = IDLE_HERO_STATE
			return value
		elseif distance < numskill - 200 then -- too near
			hero['state'] = SPIN_RETREAT_HERO_STATE
			return 1
		elseif distance > numskill + 200  then -- too far
			return 2
		end
	else
		if resultAngle > 0   then -- counter clock
			return 1
		else -- clock wise
			return 7
		end
	end
end

--[[
        Other Function
--]] 

function angle(cx, cy, ex, ey) 
	local dy = ey - cy
	local dx = ex - cx
	local theta = math.atan2(dy, dx) -- range (-PI, PI]
	theta = theta * 180 / math.pi -- rads to degs, range (-180, 180]
	return theta

end

function angle360(cx, cy, ex, ey) 
	local theta = angle(cx, cy, ex, ey) -- range (-180, 180]
	if (theta < 0) then
		 theta = 360 + theta -- range [0, 360)
	end
	return theta

end

function setRange(value)
	return (value * 2) - 1
end

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

