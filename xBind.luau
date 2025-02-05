--[[
	Client-Based User-Input wrapper 
	ocelot81, 2025
]]


local UserInputService = game:GetService("UserInputService")
local EnumNumbers = {[0] = "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"};

local xBind = {};
local _Debug = false;

xBind.BindsInUse = {};
xBind.LookupCache = {};

--[[
	Enables listener engine, starts reacting to keystrokes
	
	@returns nil
]]
function xBind.Init(self : typeof(xBind)) : nil
	self.KeyboardConnection = UserInputService.InputBegan:Connect(function(InputObject: InputObject, Resolved: boolean)
		if Resolved then return end;
	
		if not self.BindsInUse[InputObject.KeyCode] then
			return
		end
		
		return task.spawn(function()
			for _, BindObject in ipairs(self.BindsInUse[InputObject.KeyCode]) do
				
				if BindObject.Parallel then
					task.spawn(BindObject.Func, BindObject.Args)
					continue
				end
				
				BindObject.Func(BindObject.Args);
			end
		end)
	end)
end

--[[
	Binds a function to keyboard key, with options
	
	// Required: @Name, @Func, @Key
	
	@BindPriority?‎: (Default: last) Use false for auto-pick
	@Parallel?‎: (Default: true) Executes as a thread
	
	@returns nil
]]
function xBind.Bind (self : typeof(xBind), Name : string, Func : ()->(), Key : string | Enum.KeyCode, BindPriority : number?, Parallel : boolean?, ...:any?) : nil
	Key = self.ToKeycode(Key)
	
	if not Key then 
		return warn(`Could not resolve Keycode for {typeof(Key)} {Key}`) 
	end
	
	if self.LookupCache[Name] then
		return warn(`Keybind of name {Name} already exists!`) 
	end
	
	-------------
	local KeyTree = self.BindsInUse[Key]
	
	if not KeyTree then
		self.BindsInUse[Key] = {}; KeyTree = self.BindsInUse[Key];
	end
	
	local LastPosition = #KeyTree + 1
	
	BindPriority = math.min(BindPriority or LastPosition, LastPosition)
	-------------
	
	self.LookupCache[Name] = { Key = Key; PositionIndex = BindPriority }

	if _Debug then 
		warn(`Registered Bind {Name} at position {BindPriority}`) 
	end
	
	return table.insert(KeyTree, BindPriority, { Func = Func; Name = Name; Args = ...; Parallel = Parallel})
end

--[[
	Unbinds a function by before-provided Name
	 
	@returns nil
]]
function xBind.Unbind (self: typeof(xBind), Name : string) : nil
	local Lookup = self.LookupCache[Name];

	return table.remove(self.BindsInUse[Lookup.Key], Lookup.PositionIndex)
end

--[[
	Parses formats into Enum.KeyCode
	
	@Key: string / number / Enum.KeyCode / userdata
	
	use __Keycode to add Keycodes into userdata MTs
	
	@returns nil or Enum.KeyCode
]]
function xBind.ToKeycode (Key : string | number | Enum.KeyCode) : Enum.KeyCode | nil
	if typeof(Key) == Enum then
		return Key;
	end

	if typeof(Key) == "string" then
		local EnumIndex =  Enum.KeyCode[Key]

		if EnumIndex then return EnumIndex end

	elseif typeof(Key) == "number" then
		local NumIndex = EnumNumbers[Key];

		if NumIndex then return Enum.KeyCode[NumIndex] end	
		
	elseif typeof(Key) == "userdata" then
		local Meta = getmetatable(Key);
		local MetaIndex = Meta and Meta.__Keycode

		if MetaIndex then return Enum.KeyCode[MetaIndex] end	
	end

	return nil
end 

--[[
	Disables listener engine
	
	@returns nil
]]
function xBind.Disable (self : typeof(xBind)) : nil
	if self.KeyboardConnection then 
		self.KeyboardConnection:Disconnect() 
	end
	
	self.KeyboardConnection = nil;
end

--[[
	Internal fuction not connected to self obj
	
	@returns nil
]]
function xBind.__Flush (Tab : {[any] : any})
	for Index, Value in Tab do
		if type(Value) == "table" then
			xBind.__Flush(Value);
			continue
		end
		Tab[Index] = nil;
	end
	table.clear(Tab)
end

--[[
	Internal debug function
	
	@returns nil
]]
function xBind.__Dump () : nil
	for i,v in xBind.BindsInUse do
		print(i, v);
	end
	
	for i,v in xBind.LookupCache do
		warn(i, v);
	end
end

--[[
	Clears all set before key-binds
	
	@returns nil
]]
function xBind.Flush (self : typeof(xBind)) : nil
	return self.__Flush(self.BindsInUse);
end

return xBind


