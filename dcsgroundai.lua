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

function table.invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

function assignMission(TargetZones,UnfriendlyZones,FriendlyZones,ReferenceUnit,numAttack,numDefend)

	--function will give a commander an attack order and a defend order
	--Unfriendly zones should be the array of unfriendly zones
	--friendly zones should be an array of the friendly zones
	--ReferenceUnit will be where the algorithm starts looking from
	--will return two tables, the attack zone and the defend zone
	
		local defDist = 1000000000
		defZone = {}
		attZone = {}
		local targetFriendly = {}
		local targetUnfriendly = {}
	
	-- this will put all of the target zones into either friendly or unfriendly
	for i=1,table.getn(TargetZones) do
		if table.contains(UnfriendlyZones,TargetZones[i]) == true then
			table.insert(targetUnfriendly,TargetZones[i])
		else
			table.insert(targetFriendly,TargetZones[i])
		end
	end
	--if the number of attacks is more than the number of unfriendly target zones, just return all of them
	
	if table.getn(targetUnfriendly) <= numAttack then
		attZone = targetUnfriendly
	
		else
		-- build a table with the distances between each zone and the reference
		local distances = {}
		
		for j = 1,table.getn(targetUnfriendly) do
			local testCoords = mist.getRandomPointInZone(targetUnfriendly[j],0)
			local refCoords = mist.getAvgPos(ReferenceUnit)
			
			local tempDistance = mist.utils.get2DDist(refCoords, testCoords)
			distances[targetUnfriendly[j]] = tempDistance
		end
		
		--sort the unfriendly zones by distance
		table.sort(distances)
		
		--invert the table to get the sorted index (zone names)
		table.invert(distances)
		
		for k = 1,numAttack do
		
			table.insert(attZone,distances[i])
		end
	end

	if table.getn(targetFriendly) <= numDefend then
		defZone = targetFriendly
	
		else
		-- build a table with the distances between each zone and the reference
		local distances = {}
		
		for j = 1,table.getn(targetFriendly) do
			local testCoords = mist.getRandomPointInZone(targetFriendly[j],0)
			local refCoords = mist.getAvgPos(ReferenceUnit)
			
			local tempDistance = mist.utils.get2DDist(refCoords, testCoords)
			distances[targetFriendly[j]] = tempDistance
		end
		
		--sort the unfriendly zones by distance
		table.sort(distances)
		
		--invert the table to get the sorted index (zone names)
		table.invert(distances)
		
		for k = 1,numDefend do
		
			table.insert(defZone,distances[i])
		end
	end

	
	return attZone, defZone
end

-- 1. Zone Control

numZones = 10 -- set by the mission designer
zoneList = {}

for i = 1,numZones do
	-- zones should be of the format 1-X, just let DCS increment X
	zoneList[i] = '1-'..tostring(i)

end

-- identify the starting state of blue and red controlled zones

blueZones = {'1-1'}
redZones = {'1-2','1-3','1-4','1-5','1-6','1-7','1-8','1-9','1-10'}

-- randomly choose five zones of interest for the mission

targetZones = {}

for i = 1,5 do
	testZone = zoneList[math.random(table.getn(zoneList))]
		if table.contains(targetZones,testZone)==false then
			table.insert(targetZones,testZone)
		else
			i = i-1
		end

end

-- 2.  Higher Order Command: Assign the commanders missions 

blueAttackZone,blueDefendZone = assignMission(targetZones,redZones,blueZones,blueHQ,1,1)

-- 3b.  Force Structure

blueHQ =  'CHQ'
bluePlatoons = {"C1-1","C2-1"}
bluePlatoonTypes = {"armor","armor"}

-- 4.  Force Disposition
-- create a table to disposition destinations for each platoon for blue - clearly not algorithmic at this time
-- the last entry is for the HQ unit

--this is where we can write some clever AI that behave differently.

for i 1,(table.getn(bluePlatoons)) do

	blueAssignedZone[bluePlatoons[i]] = blueAttackZone

end

blueAssignedZone[blueHQ] = blueZones[1]

blueAssignedZone = {blueAttackZone, blueDefendZone, blueDefendZone}



-- 5.  Movement Orders: Send units to waypoints based on commanders' missions

--all units except HQ
for i = 1,table.getn(bluePlatoons) do
	mist.groupToRandomZone(bluePlatoons[i] ,blueAssignedZone[bluePlatoons[i]] , nil ,nil ,50 ,true )
end

-- HQ
do
	mist.groupToRandomZone(blueHQ ,blueAssignedZone[blueHQ] , nil ,nil ,50 ,true )
end

