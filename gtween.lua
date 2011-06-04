--[[
gtween.lua
Copyright (c) 2011 Josh Tynjala
Licensed under the MIT license.

Based on GTween for ActionScript 3
http://gskinner.com/libraries/gtween/
Copyright (c) 2009 Grant Skinner
Released under the MIT license.

Easing functions adapted from Robert Penner's AS3 tweening equations.
]]--
module(..., package.seeall)

local savedTweens = {}
local savedTime = 0

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
	local t = savedTime
	savedTime = event.time / 1000
	if pauseAll then
		return
	end
	local offset = savedTime - t
	local savedTweensCopy = copyTable(savedTweens)
	for i = 1,#savedTweensCopy do
		local tween = savedTweensCopy[i]
		tween:setPosition(tween.position + offset)
	end
end
	
local function registerTween(tween)
	table.insert(savedTweens, tween)
	if #savedTweens == 1 then
		savedTime = system.getTimer() / 1000
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

pauseAll = false
	
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

local transitionEasing = easing

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
	local tween = {}
	tween.inited = false
	tween.isPlaying = false
	tween.ratio = nil
	tween.calculatedPosition = nil
	tween.positionOld = nil
	tween.ratioOld = nil
	tween.calculatedPositionOld = nil
	tween.values = nil
	tween.initValues = nil
	tween.rangeValues = nil
	
	tween.autoPlay = true
	tween.delay = 0
	tween.duration = 1
	tween.transitionEase = transitionEasing.linear
	tween.nextTween = nil
	tween.onInit = nil
	tween.onChange = nil
	tween.onComplete = nil
	tween.position = 0
	tween.repeatCount = 1
	tween.reflect = false
	tween.supressEvents = false
	tween.target = nil
		
	function tween:play()
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
	function tween:pause()
		if not self.isPlaying then
			return
		end
		self.isPlaying = false
		unregisterTween(self)
	end
	
	function tween:toBeginning()
		self:setPosition(0)
		self:pause()
	end
	
	function tween:toEnd()
		if self.repeatCount > 0 then
			self:setPosition(self.repeatCount * self.duration)
		else
			self:setPosition(self.duration)
		end
	end
	
	function tween:setPosition(value)
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
	
	tween.target = target
	if duration == nil then
		tween.duration = 1
	else
		tween.duration = duration
	end
	if props then
		copyTableTo(props, tween)
	end
	if values == nil then
		values = {}
	end
	if tween.delay ~= 0 then
		tween.position = -tween.delay
	end
	resetValues(tween, values)
	if tween.duration == 0 and tween.delay == 0 and tween.autoPlay then
		tween:setPosition(0)
	end
	
	return tween
end