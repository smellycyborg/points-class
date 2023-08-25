local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Comm)
local Signal = require(ReplicatedStorage.Signal)

local serverComm = Comm.ServerComm.new(ReplicatedStorage, "PointsComm")

local points = {}
local pointsPrototype = {}
local pointsPrivate = {}

function points.new(player: Player, name: StringValue, amount: number, multiplier: number)
	assert(player, "Attempt to index nil with player instance.")
	assert(name, "Attempt to index nil with name.")
	
	local instance = {}
	local private = {}
	
	local name = name or "Points"
	local amount = amount or 0
	local multiplier = multiplier or 1
	
	instance.pointsChanged = Signal.new()
	
	private.multiplier = multiplier
	private.name = name
	
	private.pointsValue = Instance.new("IntValue")
	private.pointsValue.Name = name
	private.pointsValue.Value = amount
	private.pointsValue.Parent = player
	
	private.pointsProperty = serverComm:CreateProperty(name, amount)
	
	
	private.pointsValue:GetPropertyChangedSignal("Value"):Connect(function()
		local newPoints = private.pointsValue.Value
		
		instance.pointsChanged:Fire(player, newPoints)
		private.pointsProperty:SetFor(player, newPoints)
	end)
	
	pointsPrivate[instance] = private
	
	return setmetatable(instance, pointsPrototype)
end

function pointsPrototype:setMultiplier(amount)
	local private = pointsPrivate[self]
	
	private.multiplier = amount
end

function pointsPrototype:getName()
	local private = pointsPrivate[self]
	
	return private.name
end

function pointsPrototype:getPoints()
	local private = pointsPrivate[self]
	
	return private.pointsValue.Value
end

function pointsPrototype:addPoints(amount: number)
	local private = pointsPrivate[self]
	
	private.pointsValue.Value+=amount * private.multiplier
	
	return private.pointsValue.Value
end

function pointsPrototype:subtractPoints(amount: number)
	local private = pointsPrivate[self]

	private.pointsValue.Value-=amount

	return private.pointsValue.Value
end

function pointsPrototype:destroy()
	local private = pointsPrivate[self]
	
	private.pointsProperty:Destroy()
	
	self.pointsChanged:Destroy()
	self = nil
end

pointsPrototype.__index = pointsPrototype
pointsPrototype.__metatable = "This metatable is locked."
pointsPrototype.__newindex = function(_, _, _)
	error("This metatable is locked.")
end

return points