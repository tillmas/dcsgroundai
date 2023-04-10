--dcsgroundai
--written using MIST 4.5.107

-- function definitions

function assignMission(UnfriendlyZones,FriendlyZones,ReferenceUnit)

	--function will give a commander an attack order and a defend order
	--Unfriendly zones should be the array of unfriendly zones
	--friendly zones should be an array of the friendly zones
	--should work for both red and blue
	--ReferenceUnit will be where the algorithm starts looking from
	-- will return two arguments, the attack zone and the defend zone
	--for now, the attack zone will be the closest unfriendly zone to where they are
		defDist = 1000000000
		attDist = 1000000000
		defZone = 0
		attZone = 0
		
		for i=1,table.getn(UnfriendlyZones) do
			testCoords = mist.getRandomPointInZone(UnfriendlyZones[i],0)
			currentCoords = mist.getAvgPos(ReferenceUnit)
			
			distance = mist.utils.get2DDist(currentCoords, testCoords)
			if distance < attDist then
				attDist = distance
				attZone = i
			end
		
		end
	
	--for now, the defended zone will be the closest friendly zone to where they are (should be the currently occupied zone)
		for k=1,table.getn(FriendlyZones) do
			testCoords = mist.getRandomPointInZone(FriendlyZones[i],0)
			currentCoords = mist.getAvgPos(ReferenceUnit)
			
			distance = mist.utils.get2DDist(currentCoords, testCoords)
			if distance < attDist then
				defDist = distance
				defZone = i
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


-- 2.  Higher Order Command: Assign the commanders missions 

blueAttackZone,blueDefendZone = assignMission(redZones,blueZones,blueHQ)

-- 3b.  Force Structure

blueHQ =  'CHQ'
bluePlatoons = {"C1-1","C2-1"}
bluePlatoonTypes = {"armor","armor"}

-- 4.  Force Disposition
-- create a table to disposition destinations for each platoon for blue - clearly not algorithmic at this time
-- the last entry is for the HQ unit

blueAssignedZone = {blueAttackZone, blueDefendZone, blueDefendZone}



-- 5.  Movement Orders: Send units to waypoints based on commanders' missions

--all units except HQ
for i = 1,table.getn(bluePlatoons) do
	mist.groupToRandomZone(bluePlatoons[i] ,blueAssignedZone[i] , nil ,nil ,50 ,true )
end

-- HQ
do
	mist.groupToRandomZone(blueHQ ,blueAssignedZone[table.getn(blueAssignedZone)] , nil ,nil ,50 ,true )
end

