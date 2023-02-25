function switch(n, ...)
  for _,v in ipairs {...} do
    if v[1] == n or v[1] == nil then
      return v[2]()
    end
  end
end

function case(n,f)
  return {n,f}
end

function default(f)
  return {nil,f}
end

function isDoneTrain() 
	if data.race_state == 117 or data.race_state == 4 or earlyStop or data.time > 18000 then 
		return true 
	else 
		return false
	end
end

function getLapsize() 
	local size = 0
	local c = true
	switch( data.track,
	  case( 35, function() size = 28  end),
	  case( 11, function() size = 12  end),
	  case( 23, function() size = 48  end),
	  case( 73, function() size = 28  end), 
	  case( 44, function() size = 16  end),
	  case( 63, function() size = 40  end),
	  case( 44, function() size = 36  end),
	  case( 27, function() size = 28  end),
	  case( 37, function() size = 36  end),
	  case( 26, function() size = 44  end),
	  case( 70, function() size = 40  end),
	  case( 69, function() size = 36  end),
	  case( 4, function() size = 40   end),
	  case( 36, function() size = 52  end),
	  case( 12, function() size = 40  end),
	  case( 51, function() size = 48  end),
	  default( function() size = 28   end)
	)
	return size + 1
end


data.oldCpChange = data.cp_change
data.lastCheckpoint = -1
lapsize = getLapsize()
checkpointValue = math.floor(8700 / (((lapsize)/4)*3))
function checkpointPassed()
	local checkpoint = data.cp  
	local lap = data.lap
	
	if data.lastCheckpoint == checkpoint + (lap -1)*lapsize then
		return false
	end
	if checkpoint + (lap)*lapsize > data.lastCheckpoint then
		data.lastCheckpoint = checkpoint + (lap)*lapsize
		return true
	else 
		return false
	end

end

function getReward() 
	local wall_c = -10
	local cp_c = checkpointValue * (1.4 - data.place/10)
	local terrain_c = -15
	local time_c = -1
	local backwards_c = -2
	if data.race_state == 115 or data.race_state == 113 or data.race_state == 81 then 
		return wall_c * getWallPenalty() + cp_c * getCpReward() + terrain_c * getTerrainPenalty() 
			+ time_c * getTimePenalty() + backwards_c * getBackwardsPenalty() 
	end
	return 0
end

function getTerrainPenalty()
	if data.time ~= 0 then 
		if not isSafeTerrain() and data.time % 50 == 0 then
			return 1
		end
	end
	return 0
end

function getCpReward()
	local current_cp = 0 
	local value = 0
	if data.cp_change == 49 then
		if checkpointPassed() then
			value = 1
		end
	end
	data.oldCpChange = data.cp_change
	return value
end

function getBackwardsPenalty() 
	if (data.isGoingBackwards > 15) and data.time % 10 == 0 then
		return 1
	end
	return 0
end

function isSafeTerrain()
	if data.boosting == 80 and data.speed > 700 then 
		return true
	end
	if data.terrainType == 2 or data.terrainType == 7 then
		return true -- ok
	elseif (data.courseType == 4 or data.courseType == 22 or data.courseType == 56) and data.terrainType == 3 then 
		return true --ok
	elseif (data.courseType == 30 or data.courseType == 11) and data.terrainType == 4 then
		return true --ok
	elseif data.courseType == 20 and data.terrainType == 5 then
		return true
	end
	return false
end

function getTimePenalty() 
	if data.time ~= 0 and data.race_state == 115 then
		if data.time % 50 == 0 then
			if data.speed > 1080 then
				return 0.5
			else 
				return 1
			end
		end
	end
	return 0
end

wallHits = 0 
wallTimer = 0
earlyStop = false 
oldHit = data.hit
-- oldSpeed = 0
function getWallPenalty() 
	wallTimer = wallTimer + 1
	reward = 0

	if data.hit ~= oldHit then 
		if data.hit == 1 and  data.boosting == 0 and data.speed < 600 then 
			wallHits = wallHits + 1
			if wallHits >= 7 then 
				earlyStop = true
			end

			reward = 1
		end
	end
	if wallTimer > 800 then 
		wallTimer = 0
		wallHits = 0
	end
	oldHit = data.hit

	return reward
end

