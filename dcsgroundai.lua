--dcsgroundai
--written using MIST XXXX

-- function definitions

function assignMission(UnfriendlyZones,FriendlyZones,Location)

	--function will give a commander an attack order and a defend order
	--Unfriendly zones should be the array of unfriendly zones
	--friendly zones should be an array of the friendly zones
	--should work for both red and blue
	--location will be the zone where the function starts looking, this can be used to alter commander behavior
	-- will return two arguments, the attack zone and the defend zone
	--for now, the attack zone will be the closest unfriendly zone to where they are
		defDist = 1000000000
		attDist = 1000000000
		defZone = 0
		attZone = 0
		
		for i=1,getn(UnfriendlyZones) do
			testZone = ZONE:FindByName(UnfriendlyZones[i])
			testCoords = ZONE_BASE:GetCoordinate(testZone)
			currentZone = ZONE:FindByName(Location)
			currentCoords = ZONE_BASE:GetCoordinate(currentZone)
			
			distance = math.sqrt((testCoords.x - currentCoords.x)^2 + (testCoords.y - currentCoords.y)^2)
			if distance < attDist 
				attDist = distance
				attZone = i
			end
		
		end
	
	--for now, the defended zone will be the closest friendly zone to where they are (should be the currently occupied zone)
		for k=1,getn(FriendlyZones) do
			testZone = ZONE:FindByName(FriendlyZones[k])
			testCoords = ZONE_BASE:GetCoordinate(testZone)
			currentZone = ZONE:FindByName(Location)
			currentCoords = ZONE_BASE:GetCoordinate(currentZone)
			
			distance = math.sqrt((testCoords.x - currentCoords.x)^2 + (testCoords.y - currentCoords.y)^2)
			if distance < defDist
				defDist = distance
				defZone = k
			end
		
		end
	
	return attZone, defZone


end

-- 1. make a list of all the zones in the mission

numZones = 10 -- set by the mission designer
zoneList = {}

for i = 1,numZones do
	-- zones should be of the format 1-X, just let DCS increment X
	zoneList[i] = '1-'..tostring(i)

end

-- identify the starting state of blue and red controlled zones

blueZones = {'1-1'}
redZones = {'1-2','1-3','1-4','1-5','1-6','1-7','1-8','1-9','1-10'}

-- 2.  Identify commanders for both sides

	--blueHQ =  

-- 3.  Define forces for both sides
-- define the forces for blue

	blueAttack = {"C1-1"}
	blueSupport = {} --currently not used
	blueDefend = {"C2-1"}
	blueScout = {} -- currently not used

-- define the forces for red

-- 4.  Assign the commanders missions


-- 5.  Send units to waypoints based on commanders' missions
