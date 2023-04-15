--dcsgroundai
--written using MIST 4.5.107

-- mission editor inputs

local numberTargetZones = 5
-- mission editors may change the prefix below to whatever they wish to use in the mission.
-- if the zone name prefix is followed by an R (e.g. 'GAZR-1), the zone will be flagged as Red
-- if the zone name prefix is followed by an B (e.g. 'GAZB-1), the zone will be flagged as Blue
-- if the zone name prefix is not followed by a B or and R, the zone will be flagged as Neutral
local prefix = 'GAZ'

-- function definitions
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

-- 0. Setup
--need a random number seed here

-- 1. Zone Control

local zoneList = {}
zoneList = getAllZonesWithPrefix(prefix)

local targetZones = {}
targetZones = zoneSelector(zoneList,numberTargetZones)


-- 3b.  Force Structure
local bluePlatoons = {"C1-1","C2-1"}
local bluePlatoonTypes = {"armor","armor"}


-- 2.  Higher Order Command: Assign the commanders missions 
local moveZones = {}
moveZones = assignMission(targetZones,bluePlatoons,2)

-- 4.  Force Disposition
-- create a table to disposition destinations for each platoon for blue - clearly not algorithmic at this time
-- the last entry is for the HQ unit

--this is where we can write some clever AI that behave differently.
local blueAssignedZone={}

for i=1,(table.getn(bluePlatoons)) do

	blueAssignedZone[bluePlatoons[i]] = moveZones[i]

end



-- 5.  Movement Orders: Send units to waypoints based on commanders' missions
for i = 1,table.getn(bluePlatoons) do
	mist.groupToRandomZone(bluePlatoons[i] ,blueAssignedZone[bluePlatoons[i]] , nil ,nil ,50 ,true )
end


