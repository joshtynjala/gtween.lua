--[[
gtween.lua
Copyright (c) 2011 Josh Tynjala
Licensed under the MIT license.

Based on GTween for ActionScript 3
http://gskinner.com/libraries/gtween/
Copyright (c) 2009 Grant Skinner
Released under the MIT license.
]]--
module(..., package.seeall)

local savedTweens = {}
local lastUpdateTime = 0

local function indexOf(t, value, start)
	if start == nil then
		start = 1
	end
	for i,v in ipairs(t) do
		if i >= start and v == value then
			return i
		end
	end
	return nil
end

local function copyTableTo(t1, t2)
  for k,v in pairs(t1) do
    t2[k] = v
  end
  return t2
end

local function copyTable(t)
  local t2 = {}
  return copyTableTo(t, t2)
end

local function updateTweens(event)
	local now = event.time / 1000
	local offset = now - lastUpdateTime
	local savedTweensCopy = copyTable(savedTweens)
	for i = 1,#savedTweensCopy do
		local tween = savedTweensCopy[i]
		tween:setPosition(tween.position + offset)
	end
	lastUpdateTime = now
end
	
local function registerTween(tween)
	table.insert(savedTweens, tween)
	if #savedTweens == 1 then
		lastUpdateTime = system.getTimer() / 1000
		Runtime:addEventListener("enterFrame", updateTweens)
	end
end
	
local function unregisterTween(tween)
	table.remove(savedTweens, indexOf(savedTweens, tween))
	if # savedTweens == 0 then
		Runtime:removeEventListener("enterFrame", updateTweens)
	end
end
	
local function invalidate(tween)
	tween.inited = false
	if tween.position > 0 or tween.position == nil then
		tween.position = 0
	end
	if tween.autoPlay then
		tween:play()
	end
end
	
local function setValues(tween, newValues)
	copyTableTo(newValues, tween.values)
	invalidate(tween)
end
		
local function resetValues(tween, newValues)
	tween.values = {}
	setValues(tween, newValues)
end
		
local function init(tween)
	tween.inited = true
	tween.initValues = {}
	tween.rangeValues = {}
	for i,v in pairs(tween.values) do
		if tween.values[i] ~= nil then
			tween.initValues[i] = tween.target[i]
			tween.rangeValues[i] = tween.values[i] - tween.initValues[i]
		end
	end
	if not tween.suppressEvents then
		if tween.onInit then
			tween.onInit(tween)
		end
	end
end

local backS = 1.70158
easing = {};
easing.inBack = function(ratio)
	return ratio*ratio*((backS+1)*ratio-backS)
end
easing.outBack = function(ratio)
	ratio = ratio - 1
	return ratio*ratio*((backS+1)*ratio+backS)+1
end
easing.inOutBack = function(ratio)
	ratio = ratio * 2
	if ratio < 1 then
		return 0.5*(ratio*ratio*((backS*1.525+1)*ratio-backS*1.525))
	else 
		ratio = ratio - 2
		return 0.5*(ratio*ratio*((backS*1.525+1)*ratio+backS*1.525)+2)
	end
end
easing.inBounce = function(ratio)
	return 1-easing.outBounce(1-ratio,0,0,0)
end
easing.outBounce = function(ratio)
	if ratio < 1/2.75 then
		return 7.5625*ratio*ratio
	elseif ratio < 2/2.75 then
		ratio = ratio - 1.5/2.75
		return 7.5625*ratio*ratio+0.75
	elseif ratio < 2.5/2.75 then
		ratio= ratio - 2.25/2.75
		return 7.5625*ratio*ratio+0.9375
	else
		ratio = ratio - 2.625/2.75
		return 7.5625*ratio*ratio+0.984375
	end
end
easing.inOutBounce = function(ratio)
	ratio = ratio * 2
	if ratio < 1 then 
		return 0.5*easing.inBounce(ratio,0,0,0)
	else
		return 0.5*easing.outBounce(ratio-1,0,0,0)+0.5
	end
end
easing.inCircular = function(ratio)
	return -(math.sqrt(1-ratio*ratio)-1)
end
easing.outCircular = function(ratio)
	return math.sqrt(1-(ratio-1)*(ratio-1))
end
easing.inOutCircular = function(ratio)
	ratio = ratio * 2
	if ratio < 1 then
		return -0.5*(math.sqrt(1-ratio*ratio)-1)
	else
		ratio = ratio - 2
		return 0.5*(math.sqrt(1-ratio*ratio)+1)
	end
end
easing.inCubic = function(ratio)
	return ratio*ratio*ratio
end
easing.outCubic = function(ratio)
	ratio = ratio - 1
	return ratio*ratio*ratio+1
end
easing.inOutCubic = function(ratio)
	if ratio < 0.5 then
		return 4*ratio*ratio*ratio
	else
		ratio = ratio - 1
		return 4*ratio*ratio*ratio+1
	end
end
local elasticA = 1;
local elasticP = 0.3;
local elasticS = elasticP/4;
easing.inElastic = function(ratio)
	if ratio == 0 or ratio == 1 then
		return ratio
	end
	ratio = ratio - 1
	return -(elasticA * math.pow(2, 10 * ratio) * math.sin((ratio - elasticS) * (2 * math.pi) / elasticP));
end
easing.outElastic = function(ratio)
	if ratio == 0 or ratio == 1 then
		return ratio
	end
	return elasticA * math.pow(2, -10 * ratio) *  math.sin((ratio - elasticS) * (2 * math.pi) / elasticP) + 1;
end
easing.inOutElastic = function(ratio)
	if ratio == 0 or ratio == 1 then
		return ratio
	end
	ratio = ratio*2-1
	if ratio < 0 then
		return -0.5 * (elasticA * math.pow(2, 10 * ratio) * math.sin((ratio - elasticS*1.5) * (2 * math.pi) /(elasticP*1.5)));
	end
	return 0.5 * elasticA * math.pow(2, -10 * ratio) * math.sin((ratio - elasticS*1.5) * (2 * math.pi) / (elasticP*1.5)) + 1;
end
easing.inExponential = function(ratio)
	if ratio == 0 then
		return 0
	end
	return math.pow(2, 10 * (ratio - 1))
end
easing.outExponential = function(ratio)
	if ratio == 1 then
		return 1
	end
	return 1-math.pow(2, -10 * ratio)
end
easing.inOutExponential = function(ratio)
	if ratio == 0 or ratio == 1 then 
		return ratio
	end
	ratio = ratio*2-1
	if 0 > ratio then
		return 0.5*math.pow(2, 10*ratio)
	end
	return 1-0.5*math.pow(2, -10*ratio)
end
easing.noneLinear = function(ratio)
	return ratio
end
easing.inQuadratic = function(ratio)
	return ratio*ratio
end
easing.outQuadratic = function(ratio)
	return -ratio*(ratio-2)
end
easing.inOutQuadratic = function(ratio)
	if ratio < 0.5 then
		return 2*ratio*ratio
	end
	return -2*ratio*(ratio-2)-1
end
easing.inQuartic = function(ratio)
	return ratio*ratio*ratio*ratio
end
easing.outQuartic = function(ratio)
	ratio = ratio - 1
	return 1-ratio*ratio*ratio*ratio
end
easing.inOutQuartic = function(ratio)
	if ratio < 0.5 then
		return 8*ratio*ratio*ratio*ratio
	end
	ratio = ratio - 1
	return -8*ratio*ratio*ratio*ratio+1
end
easing.inQuintic = function(ratio)
	return ratio*ratio*ratio*ratio*ratio
end
easing.outQuintic = function(ratio)
	ratio = ratio - 1
	return 1+ratio*ratio*ratio*ratio*ratio
end
easing.inOutQuintic = function(ratio)
	if ratio < 0.5 then
		return 16*ratio*ratio*ratio*ratio*ratio
	end
	ratio = ratio - 1
	return 16*ratio*ratio*ratio*ratio*ratio+1
end
easing.inSine = function(ratio)
	return 1-math.cos(ratio * (math.pi / 2))
end
easing.outSine = function(ratio)
	return math.sin(ratio * (math.pi / 2))
end
easing.inOutSine = function(ratio)
	return -0.5*(math.cos(ratio*math.pi)-1)
end

function new(target, duration, values, props)

	local gtween = {}
	gtween.inited = false
	gtween.isPlaying = false
	gtween.ratio = nil
	gtween.calculatedPosition = nil
	gtween.positionOld = nil
	gtween.ratioOld = nil
	gtween.calculatedPositionOld = nil
	gtween.values = nil
	gtween.initValues = nil
	gtween.rangeValues = nil
	
	gtween.autoPlay = true
	gtween.delay = 0
	gtween.duration = 1
	gtween.transitionEase = easing.linear
	gtween.ease = nil
	gtween.nextTween = nil
	gtween.onInit = nil
	gtween.onChange = nil
	gtween.onComplete = nil
	gtween.position = 0
	gtween.repeatCount = 1
	gtween.reflect = false
	gtween.supressEvents = false
	gtween.target = nil
		
	function gtween:play()
		if self.isPlaying then
			return
		end
		self.isPlaying = true
		if self.position == nil or self.repeatCount ~= 0 and self.position >= self.repeatCount * self.duration then
			-- reached the end, reset.
			self.inited = false
			self.positionOld = 0
			self.calculatedPosition = 0
			self.calculatedPositionOld = 0
			self.ratio = 0
			self.ratioOld = 0
			self.position = -self.delay
		end
		registerTween(self)
	end
	function gtween:pause()
		if not self.isPlaying then
			return
		end
		self.isPlaying = false
		unregisterTween(self)
	end
	
	function gtween:toBeginning()
		self:setPosition(0)
		self:pause()
	end
	
	function gtween:toEnd()
		if self.repeatCount > 0 then
			self:setPosition(self.repeatCount * self.duration)
		else
			self:setPosition(self.duration)
		end
	end
	
	function gtween:setPosition(value)
		self.positionOld = self.position
		self.ratioOld = self.ratio
		self.calculatedPositionOld = self.calculatedPosition
		
		local maxPosition = self.repeatCount * self.duration
		
		local hasEnded = value >= maxPosition and self.repeatCount > 0
		if hasEnded then
			if self.calculatedPositionOld == maxPosition then
				return
			end
			self.position = maxPosition
			if self.reflect and (self.repeatCount % 2 == 0) then
				self.calculatedPosition = 0
			else
				self.calculatedPosition = self.duration
			end
		else
			self.position = value
			if self.position < 0 then
				self.calculatedPosition = 0
			else
				self.calculatedPosition = self.position % self.duration
			end
			
			if self.reflect and math.floor(self.position / self.duration) % 2 ~= 0 then
				self.calculatedPosition = self.duration - self.calculatedPosition
			end
		end
			
		if self.duration == 0 and self.position >= 0 then
			self.ratio = 1
		else
			if self.ease ~= nil then
				self.ratio = self.ease(self.calculatedPosition / self.duration, 0, 1, 1)
			elseif self.transitionEase ~= nil then
				self.ratio = self.transitionEase(self.calculatedPosition, self.duration, 0, 1)
			end
		end
		
		
		if self.target and (self.position >= 0 or self.positionOld >= 0) and self.calculatedPosition ~= self.calculatedPositionOld then
			if not self.inited then
				init(self)
			end
			for i,v in pairs(values) do
				local initVal = self.initValues[i]
				local rangeVal = self.rangeValues[i]
				local val = initVal + rangeVal * self.ratio
				self.target[i] = val
			end
		end
		
		if not self.suppressEvents then
			if self.onChange ~= nil then
				self.onChange(self)
			end
		end
		
		if hasEnded then
			self:pause()
			if self.nextTween then
				self.nextTween:play()
			end
			if not self.suppressEvents then
				if self.onComplete ~= nil then
					self.onComplete(self)
				end
			end
		end
	end
	
	gtween.target = target
	if duration == nil then
		gtween.duration = 1
	else
		gtween.duration = duration
	end
	if props then
		copyTableTo(props, gtween)
	end
	if values == nil then
		values = {}
	end
	if gtween.delay ~= 0 then
		gtween.position = -gtween.delay
	end
	resetValues(gtween, values)
	if gtween.duration == 0 and gtween.delay == 0 and gtween.autoPlay then
		gtween:setPosition(0)
	end
	
	return gtween
end