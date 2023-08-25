--[[

	name:  PointsClass
	description:  add and manage any type of points
	
	// server
	
	-- require PointsClass
	
	local pointsPerPlayer = {}
	
	function playerAdded(player)
		pointsPerPlayer[player] = PointsClass.new(player, "cash")
		
		local playerPoints = pointsPerPlayer[player]
		playerPoints.pointsChanged:Connect(function()
			-- do whatever
		end)
		
		playerPoints:addPoints(50)
		
	end
	
	// client
	
	-- the name of your client comm is "PointsComm"
	-- get your comm property which will be under the name of your points (in this example it's cash)
	
	local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "PointsComm")
	local cash = clientComm:GetProperty("cash")
	
	cash:Observe(function(newPoints)
		-- do whatever 
	end)

]]

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
	
	local valuesFolder = player:FindFirstChild("Values")
	if not valuesFolder then
		valuesFolder = Instance.new("Folder", player)
		valuesFolder.Name = "Values"
	end
	
	instance.pointsChanged = Signal.new()
	
	private.multiplier = multiplier
	private.name = name
	
	private.pointsValue = Instance.new("IntValue", valuesFolder)
	private.pointsValue.Name = name
	private.pointsValue.Value = amount
	
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
