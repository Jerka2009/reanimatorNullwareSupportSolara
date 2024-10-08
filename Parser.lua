local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jerka2009/reanimatorNullwareSupportSolara/main/Utility.lua"))()

local tinsert, tsort = table.insert, table.sort
local format = string.format

local Parser = {}

function Parser:parsePoseData(pose)
	if pose.ClassName ~= "Pose" then
		error(format("invalid argument 1 to 'parsePoseData' (Pose expected, got %s)", pose.ClassName))
	end
	local poseData = {
		Name = pose.Name,
		CFrame = pose.CFrame,
		EasingDirection = Utility:convertEnum(pose.EasingDirection),
		EasingStyle = Utility:convertEnum(pose.EasingStyle),
		Weight = pose.Weight,
	}
	if #pose:GetChildren() > 0 then
		poseData.Subpose = {}
		local Children = pose:GetChildren()
		for count = 1, #Children do
			local p = Children[count]
			if p.ClassName ~= "Pose" then
				continue
			end
			tinsert(poseData.Subpose, Parser:parsePoseData(p))
		end
	end
	return poseData
end

function Parser:parseKeyframeData(keyframe)
	if keyframe.ClassName ~= "Keyframe" then
		error(format("invalid argument 1 to 'parseKeyframeData' (Keyframe expected, got %s)", keyframe.ClassName))
	end
	local keyframeData = { Name = keyframe.Name, Time = keyframe.Time, Pose = {} }
	local Children = keyframe:GetChildren()
	for count = 1, #Children do
		local p = Children[count]
		if p.ClassName == "Pose" then
			tinsert(keyframeData.Pose, Parser:parsePoseData(p))
		elseif p.ClassName == "KeyframeMarker" then
			if not keyframeData["Marker"] then
				keyframeData.Marker = {}
			end
			if not keyframeData.Marker[p.Name] then
				keyframeData.Marker[p.Name] = {}
			end
			tinsert(keyframeData.Marker[p.Name], p.Value)
		end
	end
	return keyframeData
end

function Parser:parseAnimationData(keyframeSequence)
	if keyframeSequence.ClassName ~= "KeyframeSequence" then
		error(
			format(
				"invalid argument 1 to 'parseAnimationData' (KeyframeSequence expected, got %s)",
				keyframeSequence.ClassName
			)
		)
	end
	local animationData = { Loop = keyframeSequence.Loop, Priority = keyframeSequence.Priority, Frames = {} }
	local Children = keyframeSequence:GetChildren()
	for count = 1, #Children do
		local f = Children[count]
		if f.ClassName ~= "Keyframe" then
			continue
		end
		tinsert(animationData.Frames, Parser:parseKeyframeData(f))
	end

	tsort(animationData.Frames, function(l, r)
		return l.Time < r.Time
	end)

	return animationData
end

return Parser
