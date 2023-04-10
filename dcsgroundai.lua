--dcsgroundai
--written using MIST XXXX

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
		
		for i=1,getn(UnfriendlyZones) do
			testCoords = mist.getRandomPointInZone(UnfriendlyZones[i],0)
			currentCoords = mist.getAvgPos(ReferenceUnit)
			
			distance = mist.utils.get2DDist(currentCoords, testCoords)
			if distance < attDist 
				attDist = distance
				attZone = i
			end
		
		end
	
	--for now, the defended zone will be the closest friendly zone to where they are (should be the currently occupied zone)
		for k=1,getn(FriendlyZones) do
			testCoords = mist.getRandomPointInZone(FriendlyZones[i],0)
			currentCoords = mist.getAvgPos(ReferenceUnit)
			
			distance = mist.utils.get2DDist(currentCoords, testCoords)
			if distance < attDist 
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

-- 2.  Identify commanders for both sides

blueHQ =  'CHQ'

-- 3.  Define forces for both sides
-- define the forces for blue

blueAttack = {"C1-1"}
blueSupport = {} --currently not used
blueDefend = {"C2-1"}
blueScout = {} -- currently not used

-- define the forces for red
-- not currently implemented

-- 4.  Assign the commanders missions

blueAttackZone,blueDefendZone = assignMission(redZones,blueZones,blueHQ)

-- 5.  Send units to waypoints based on commanders' missions

do
	mist.groupToRandomZone(blueAttack ,blueAttackZone , nil ,nil ,50 ,true )
end

do
	mist.groupToRandomZone(blueDefend ,blueDefendZone , nil ,nil ,50 ,true )
end
