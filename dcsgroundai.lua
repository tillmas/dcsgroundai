--dcsgroundai
--written using MIST 4.5.107

-- *********************************************************
-- Function definitions
-- *********************************************************
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.invert(table)
   local s={}
   for k,v in pairs(table) do
     s[v]=k
   end
   return s
end

function assignMission(TargetZones,ReferenceUnit,numZones)
--a simple version for testing, returns as many are as asked for
--reference unit is not currently used, but is left to allow for calculation of zone proximity

	attZone = {}

	if table.getn(TargetZones) <= numZones then
	
		attZone = TargetZones
	
	else

		for i=1,numZones do
			attZone[i] = TargetZones[math.random(1,table.getn(TargetZones))]
		end
	
	end
	
	return attZone
	

end

function zoneSelector(zoneList,numberTaskZones)

	-- randomly choose five zones of interest for the mission
	-- this could be done with some kind of weighted value function
	local targetZones = {}

	for i = 1,numberTaskZones do
		testZone = zoneList[math.random(table.getn(zoneList))]
			if table.contains(targetZones,testZone)==false then
				table.insert(targetZones,testZone)
			else
				i = i-1
			end
	end
	
	return targetZones
	
end

function getAllZonesWithPrefix(prefix)
	-- Returns list of all zones with names containing the prefix [prefix]
	local list = {}
	for _, z in pairs(mist.DBs.zonesByName) do
	
		-- If zone name starts with specified prefix, add the zone to the list.
		if (string.sub(z.name, 1, #prefix) == prefix) then
			local newZone = z
			local zoneControlPrefix = string.sub(z.name, 1, #prefix + 1)
			
			-- If zone name has the form 'prefixR ', set controlledBy to "Red"
			if (zoneControlPrefix == prefix .. "R") then
				z["controlledBy"] = "Red"
				
			-- If zone name has the form 'prefixR ', set controlledBy to "Blue"
			elseif (zoneControlPrefix == prefix .. "B") then
				z["controlledBy"] = "Blue"
		
			-- Otherwise, set controlledBy to "Neutral"
			else
				z["controlledBy"] = "Neutral"
			end

			list[#list+1] = z
		end
	end
	return list
end

function generateCommander()

	-- Commander Strategy Enumerations
	-- DEFAULT: 
	
	-- TODO: Commander strategy enumerations, and 
	-- 		add logic to assign a strategy to commanders
	--	
	--	Need to consider how commanders can persist 
	--		between missions.
	
	return {
		["strategy"] = "DEFAULT",
		["forces"] = {}
	}
end

function getForceStructure(prefix) 
	-- Returns a list of commanders and their forces
	-- {
	--		["Commander1"] = {
	--			["strategy"] = "STRATEGY_NAME",
	--			["forces"] = {
	--				"Unit/Group 1 name"
	--				"Unit/Group 2 name"
	--			}
	--		}
	-- }

	-- Get forces in battlefield with user-defined prefix
	local forceStructure = {}
	for _, g in pairs(mist.DBs.groupsByName) do
		-- Parse group object name into prefix, commander's name, and group's name
		-- [PREFIX]_[COMMANDERNAME]_[GROUPNAME]
		local groupPrefix, commanderName, groupName = string.match(g.groupName, "(.*)_(.*)_(.*)")

		if (groupPrefix == prefix) then
		
			--	Check if commander object already exists. If not, create it.
			if (forceStructure[commanderName] == nil) then
				forceStructure[commanderName] = generateCommander()
			end
			
			-- 	Add unit/group to commander object's "forces" table.
			table.insert(forceStructure[commanderName]["forces"], g.groupName)
		end
	end
	
	return forceStructure
end


-- *********************************************************
-- ****************** 		   MAIN 		****************
-- *********************************************************
-- 0. Setup
-- *********************************************************
--need a random number seed here

-- mission editor inputs

local _NUM_TARGET_ZONES = 5

-- mission editors may change the prefix below to whatever they wish to use in the mission.
-- if the zone name prefix is followed by an R (e.g. 'GAZR-1), the zone will be flagged as Red
-- if the zone name prefix is followed by an B (e.g. 'GAZB-1), the zone will be flagged as Blue
-- if the zone name prefix is not followed by a B or and R, the zone will be flagged as Neutral
local _PREFIX = 'GAZ'

-- *********************************************************
-- 1. Zone Control
-- *********************************************************
local zoneList = {}
zoneList = getAllZonesWithPrefix(_PREFIX)

local targetZones = {}
targetZones = zoneSelector(zoneList, _NUM_TARGET_ZONES)


-- *********************************************************
-- 3b.  Force Structure
-- *********************************************************
local forceStucture = getForceStructure(_PREFIX)

-- *********************************************************
-- 2.  Higher Order Command: Assign the commanders missions 
-- *********************************************************
local moveZones = {}
-- TODO: forceStructure["C1"]["forces"] is temporary code to make Higher Order Command still work.
-- This will be updated in issue #6.
moveZones = assignMission(targetZones, forceStructure["C1"]["forces"], 2)


-- *********************************************************
-- 4.  Force Disposition
-- *********************************************************
-- create a table to disposition destinations for each platoon for blue - clearly not algorithmic at this time
-- the last entry is for the HQ unit

--this is where we can write some clever AI that behave differently.
local blueAssignedZone={}

for i=1,(table.getn(bluePlatoons)) do

	blueAssignedZone[bluePlatoons[i]] = moveZones[i]

end


-- *********************************************************
-- 5.  Movement Orders: Send units to waypoints based on commanders' missions
-- *********************************************************
for i = 1,table.getn(bluePlatoons) do
	mist.groupToRandomZone(bluePlatoons[i] ,blueAssignedZone[bluePlatoons[i]] , nil ,nil ,50 ,true )
end


