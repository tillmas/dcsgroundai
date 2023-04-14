--dcsgroundai
--written using MIST 4.5.107

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

function zoneControl(numberTaskZones)

	--create a list of all the zones in the mission
	local zoneList = {}
	local output = {}

	for _, z in pairs(mist.DBs.zonesByName) do
		zoneList[#zoneList+1] = z
	end

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

-- 1. Zone Control

targetZones = zoneControl(5)

-- identify the starting state of blue and red controlled zones
local blueZones = {'1-1'}
local redZones = {'1-2','1-3','1-4','1-5','1-6','1-7','1-8','1-9','1-10'}

-- 3b.  Force Structure

local blueHQ =  'CHQ'
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

blueAssignedZone[blueHQ] = blueZones[1]


-- 5.  Movement Orders: Send units to waypoints based on commanders' missions

--all units except HQ
for i = 1,table.getn(bluePlatoons) do
	mist.groupToRandomZone(bluePlatoons[i] ,blueAssignedZone[bluePlatoons[i]] , nil ,nil ,50 ,true )
end

-- HQ
do
	mist.groupToRandomZone(blueHQ ,blueAssignedZone[blueHQ] , nil ,nil ,50 ,true )
end

