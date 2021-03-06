require "Window"

local IconTrigger  = {} 
IconTrigger .__index = IconTrigger

setmetatable(IconTrigger, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function IconTrigger.new(icon, buffWatch)
	local self = setmetatable({}, IconTrigger)

	self.buffWatch = buffWatch

	self.Name = ""
	self.Type = "Cooldown"
	self.Behaviour = "Pass"
	self.TriggerDetails = {}
	self.TriggerEffects = {}
	self.Icon = icon

	self.isSet = false

	self.lastKeypress = 0

	return self
end

function IconTrigger:Load(saveData)
	if saveData ~= nil then
		self.Name = saveData.Name
		self.Type = saveData.Type
		self.Behaviour = saveData.Behaviour or "Pass"
		self.TriggerDetails = saveData.TriggerDetails

		if self.Type == "Buff" or self.Type == "Debuff" then
			if not self.TriggerDetails.Stacks then
				self.TriggerDetails.Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			end
		elseif self.Type == "Cooldown" then
			if not self.TriggerDetails.Charges then
				self.TriggerDetails.Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			end
		elseif self.Type == "Keybind" then
			if self.TriggerDetails.Key ~= nil then
				self.TriggerDetails.Input = {
					Key = self.TriggerDetails.Key,
					Shift = false,
					Control = false,
					Alt = false
				}
				self.TriggerDetails.Key = nil
			end
		end

		if saveData.TriggerEffects ~= nil then
			GeminiPackages:Require('AuraMastery:TriggerEffect', function(TriggerEffect)
				for _, triggerEffectData in pairs(saveData.TriggerEffects) do
					local triggerEffect = TriggerEffect.new(self)
					triggerEffect:Load(triggerEffectData)
					table.insert(self.TriggerEffects, triggerEffect)
				end
			end)
		end

		self:AddToBuffWatch()
	end
end

function IconTrigger:Save()
	local saveData = { }
	saveData.Name = self.Name
	saveData.Type = self.Type
	saveData.Behaviour = self.Behaviour
	saveData.TriggerDetails = self.TriggerDetails
	saveData.TriggerEffects = {}
	for _, triggerEffect in pairs(self.TriggerEffects) do
		table.insert(saveData.TriggerEffects, triggerEffect:Save())
	end
	return saveData
end

function IconTrigger:SetConfig(editor)
	self:RemoveFromBuffWatch()
	if self.Icon.SimpleMode then
		self.Type = string.sub(editor:FindChild("AuraType"):GetData():GetName(), 10)
		self.Name = self.Type .. ":" .. self.Icon.iconName

		if self.Type == "Cooldown" then
			self.TriggerDetails = {
				SpellName = self.Icon.iconName,
				Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		elseif self.Type == "Buff" then
			self.TriggerDetails = {
				BuffName = self.Icon.iconName,
				Target = {
					Player = editor:FindChild("AuraBuffUnit_Player"):IsChecked(),
					Target = editor:FindChild("AuraBuffUnit_Target"):IsChecked()
				},
				Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		elseif self.Type == "Debuff" then
			self.TriggerDetails = {
				DebuffName = self.Icon.iconName,
				Target = {
					Player = editor:FindChild("AuraBuffUnit_Player"):IsChecked(),
					Target = editor:FindChild("AuraBuffUnit_Target"):IsChecked()
				},
				Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		end
	else
		self.Name = editor:FindChild("TriggerName"):GetText()
		self.Type = editor:FindChild("TriggerType"):GetText()
		self.Behaviour = editor:FindChild("TriggerBehaviour"):GetText()
		local selectedTriggerEffectItem = editor:FindChild("TriggerEffectsList"):GetData()
		if selectedTriggerEffectItem ~= nil and selectedTriggerEffectItem:GetData() ~= nil then
			selectedTriggerEffectItem:GetData():SetConfig(editor:FindChild("TriggerEffects"))
		end

		if self.Type == "Action Set" then
			self.TriggerDetails = {	
				ActionSets = {
					editor:FindChild("ActionSet1"):IsChecked(),
					editor:FindChild("ActionSet2"):IsChecked(),
					editor:FindChild("ActionSet3"):IsChecked(),
					editor:FindChild("ActionSet4"):IsChecked()
				}
			}
		elseif self.Type == "Cooldown" then
			self.TriggerDetails = {
				SpellName = editor:FindChild("SpellName"):GetText(),
				Charges = {
					Enabled = editor:FindChild("ChargesEnabled"):IsChecked(),
					Operator = editor:FindChild("Charges"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Charges"):FindChild("ChargesValue"):GetText())
				}
			}
		elseif self.Type == "Buff" then
			self.TriggerDetails = {
				BuffName = editor:FindChild("BuffName"):GetText(),
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
					Target = editor:FindChild("TargetTarget"):IsChecked()
				},
				Stacks = {
					Enabled = editor:FindChild("StacksEnabled"):IsChecked(),
					Operator = editor:FindChild("Stacks"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Stacks"):FindChild("StacksValue"):GetText())
				}
			}
		elseif self.Type == "Debuff" then
			self.TriggerDetails = {
				DebuffName = editor:FindChild("DebuffName"):GetText(),
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
					Target = editor:FindChild("TargetTarget"):IsChecked()
				},
				Stacks = {
					Enabled = editor:FindChild("StacksEnabled"):IsChecked(),
					Operator = editor:FindChild("Stacks"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Stacks"):FindChild("StacksValue"):GetText())
				}
			}
		elseif self.Type == "Resources" then
			self.TriggerDetails = { }
			if editor:FindChild("ManaEnabled"):IsChecked() then
				local resourceEditor = editor:FindChild("Mana")
				self.TriggerDetails.Mana = {
					Operator = resourceEditor:FindChild("Operator"):GetText(),
					Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
					Percent = resourceEditor:FindChild("Percent"):IsChecked()
				}
			end
			if editor:FindChild("ResourceEnabled"):IsChecked() then
				local resourceEditor = editor:FindChild("Resource")
				self.TriggerDetails.Resource = {
					Operator = resourceEditor:FindChild("Operator"):GetText(),
					Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
					Percent = resourceEditor:FindChild("Percent"):IsChecked()
				}
			end
		elseif self.Type == "Health" then
			self.TriggerDetails = { 
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
					Target = editor:FindChild("TargetTarget"):IsChecked()
				}
			}
			if editor:FindChild("HealthEnabled"):IsChecked() then
				local resourceEditor = editor:FindChild("Health")
				self.TriggerDetails.Health = {
					Operator = resourceEditor:FindChild("Operator"):GetText(),
					Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
					Percent = resourceEditor:FindChild("Percent"):IsChecked()
				}
			end
			if editor:FindChild("ShieldEnabled"):IsChecked() then
				local resourceEditor = editor:FindChild("Shield")
				self.TriggerDetails.Shield = {
					Operator = resourceEditor:FindChild("Operator"):GetText(),
					Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
					Percent = resourceEditor:FindChild("Percent"):IsChecked()
				}
			end
		elseif self.Type == "Moment Of Opportunity" then
			self.TriggerDetails = { 
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
					Target = editor:FindChild("TargetTarget"):IsChecked()
				}
			}
		elseif self.Type == "Limited Action Set Checker" then
			self.TriggerDetails = {
				AbilityName = editor:FindChild("AbilityName"):GetText()
			}
		elseif self.Type == "Scriptable" then
			self.TriggerDetails = {
				Script = editor:FindChild("Script"):GetText()
			}
			editor:FindChild("ScriptErrors"):SetText("")
			local script, loadScriptError = loadstring("local trigger = ...\n" .. self.TriggerDetails.Script)
			if script ~= nil then
				local status, result = pcall(script, self)
				if not status then
					editor:FindChild("ScriptErrors"):SetText(tostring(result))
				end
			else
				editor:FindChild("ScriptErrors"):SetText("Unable to load script due to a syntax error: " .. tostring(loadScriptError))
			end
		elseif self.Type == "Keybind" then
			self.TriggerDetails = {
				Input = editor:FindChild("KeybindTracker_KeySelect"):GetData(),
				Duration = tonumber(editor:FindChild("KeybindTracker_Duration"):GetText()) or 1
			}
			editor:FindChild("KeybindTracker_Duration"):SetText(tostring(self.TriggerDetails.Duration))
		elseif self.Type == "Gadget" then
			self.TriggerDetails = {
				Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		end
	end
	self:AddToBuffWatch()
end

function IconTrigger:RemoveEffect(effect)
	for triggerId, triggerEffect in pairs(self.TriggerEffects) do
		if triggerEffect == effect then
			table.remove(self.TriggerEffects, triggerId)
			break
		end
	end
end

function IconTrigger:AddToBuffWatch()
	if self.Type == "Cooldown" then
		self.currentSpell = self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName
		self:AddCooldownToBuffWatch(self.currentSpell)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
		self.buffName = self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName
		if self.buffName == "" then
			self.buffName = self.Icon.iconName
		end

		if self.TriggerDetails.Target.Player then
			self:AddBuffToBuffWatch("Player", self.buffName)
		end
		
		if self.TriggerDetails.Target.Target then
			self:AddBuffToBuffWatch("Target", self.buffName)
		end
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" or self.Type == "Gadget" then
		self:AddBasicToBuffWatch()
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
		if self.TriggerDetails.Target.Player then
			self:AddCooldownToBuffWatch("Player")
		end
		if self.TriggerDetails.Target.Target then
			self:AddCooldownToBuffWatch("Target")
		end
	elseif self.Type == "Keybind" then
		self:AddCooldownToBuffWatch(self.TriggerDetails.Input.Key)
	elseif self.Type == "Limited Action Set Checker" then
		self.currentSpell = self.TriggerDetails.AbilityName == "" and self.Icon.iconName or self.TriggerDetails.AbilityName
		self:AddCooldownToBuffWatch(self.currentSpell)
	end
end

function IconTrigger:AddCooldownToBuffWatch(option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][option] == nil then
		self.buffWatch[triggerType][option] = {}
	end
	self.buffWatch[triggerType][option][tostring(self)] = function(result) self:ProcessOptionEvent(result) end
end

function IconTrigger:AddBasicToBuffWatch()
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType] == nil then
		self.buffWatch[triggerType] = {}
	end
	self.buffWatch[triggerType][tostring(self)] = function(result) self:ProcessEvent(result) end
end

function IconTrigger:AddBuffToBuffWatch(target, option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][target][option] == nil then
		self.buffWatch[triggerType][target][option] = {}
	end
	self.buffWatch[triggerType][target][option][tostring(self)] = function(spell) self:ProcessBuff(spell) end
end

function IconTrigger:RemoveFromBuffWatch()
	if self.Type == "Cooldown" or self.Type == "Limited Action Set Checker" then
		self:RemoveCooldownFromBuffWatch(self.currentSpell)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
		if self.TriggerDetails.Target.Player then
			self:RemoveBuffFromBuffWatch("Player", self.buffName)
		end
		
		if self.TriggerDetails.Target.Target then
			self:RemoveBuffFromBuffWatch("Target", self.buffName)
		end
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" or self.Type == "Gadget" then
		self:RemoveBasicFromBuffWatch()
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
		if self.TriggerDetails.Target.Player then
			self:RemoveCooldownFromBuffWatch("Player")
		end
		if self.TriggerDetails.Target.Target then
			self:RemoveCooldownFromBuffWatch("Target")
		end
	elseif self.Type == "Keybind" then
		self:RemoveCooldownFromBuffWatch(self.TriggerDetails.Input.Key)
	end
end

function IconTrigger:RemoveBasicFromBuffWatch()
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType] ~= nil then
		self.buffWatch[triggerType][tostring(self)] = nil
	end
end

function IconTrigger:RemoveCooldownFromBuffWatch(option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][option] ~= nil then
		self.buffWatch[triggerType][option][tostring(self)] = nil
	end
end

function IconTrigger:RemoveBuffFromBuffWatch(target, option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][target][option] ~= nil then
		self.buffWatch[triggerType][target][option][tostring(self)] = nil
	end
end

function IconTrigger:ResetTrigger()
	self.Stacks = nil
	self.Time = nil
	if self.Type ~= "Action Set" and self.Type ~= "Limited Action Set Checker" then
		self.isSet = false
	end
end

function IconTrigger:IsPass()
	if self.Behaviour == "Pass" then
		return self.isSet
	elseif self.Behaviour == "Fail" then
		return not self.isSet
	elseif self.Behaviour == "Ignore" then
		return true
	end
	return false
end

function IconTrigger:IsSet()
	if self.Type == "Scriptable" then
		self:ProcessScriptable()
	elseif self.Type == "Keybind" then
		local timeSinceKeypress = (Apollo.GetTickCount() - self.lastKeypress) / 1000
		self.isSet = timeSinceKeypress < self.TriggerDetails.Duration
		if self.isSet then
			self.Time = self.TriggerDetails.Duration - timeSinceKeypress
			self.MaxDuration = self.TriggerDetails.Duration
		end
	end

	self.isPass = self:IsPass()
	return self.isPass
end

function IconTrigger:ProcessEffects()
	for _, triggerEffect in pairs(self.TriggerEffects) do
		triggerEffect:Update(self.isPass)
	end
end

function IconTrigger:StopEffects()
	for _, triggerEffect in pairs(self.TriggerEffects) do
		triggerEffect:EndTimed()
	end
end

function IconTrigger:GetSpellCooldown(spell)
	local charges = spell:GetAbilityCharges()
	if charges and charges.nChargesMax > 0 then
		return charges.fRechargePercentRemaining * charges.fRechargeTime, charges.fRechargeTime, charges.nChargesRemaining, charges.nChargesMax
	else
		return spell:GetCooldownRemaining(), spell:GetCooldownTime(), 0, 0
	end
end

function IconTrigger:ProcessScriptable()
	local script = loadstring("local trigger = ...\n" .. self.TriggerDetails.Script)
	if script ~= nil then
		local status, result = pcall(script, self)
		if status then
			self.isSet = result
		end
	end
end

function IconTrigger:ProcessOptionEvent(result)
	if self.Type == "Cooldown" then
		self:ProcessSpell(result)
	elseif self.Type == "Health" then
		self:ProcessHealth(result)
	elseif self.Type == "Moment Of Opportunity" then
		self:ProcessMOO(result)
	elseif self.Type == "Keybind" then
		self:ProcessKeybind(result)
	elseif self.Type == "Limited Action Set Checker" then
		self:ProcessLASChange(result)
	end
end

function IconTrigger:ProcessSpell(spell)
	local cdRemaining, cdTotal, chargesRemaining, chargesMax = self:GetSpellCooldown(spell)
	self.Charges = chargesRemaining
	self.Sprite = spell:GetIcon()
	if not (self.Time and self.Time > cdRemaining) then
		self.Time = cdRemaining
		self.MaxDuration = math.max(cdRemaining, cdTotal)
		self.MaxCharges = chargesMax
		if ((not self.TriggerDetails.Charges.Enabled) and (cdRemaining == 0 or chargesRemaining > 0))
			or (self.TriggerDetails.Charges.Enabled and self:IsOperatorSatisfied(chargesRemaining, self.TriggerDetails.Charges.Operator, self.TriggerDetails.Charges.Value)) then
			self.isSet = false
			if cdRemaining == 0 then
				self.Time = 0
			end
		else
			self.isSet = true
		end
	end
end

function IconTrigger:ProcessBuff(buff)
	if not self.TriggerDetails.Stacks.Enabled or self:IsOperatorSatisfied(buff.nCount, self.TriggerDetails.Stacks.Operator, self.TriggerDetails.Stacks.Value) then
		self.isSet = true
		self.Time = buff.fTimeRemaining
		if self.MaxDuration == nil or self.MaxDuration < self.Time then
			self.MaxDuration = self.Time
		end
		self.Stacks = buff.nCount
		self.Sprite = buff.splEffect:GetIcon()
	end
end

function IconTrigger:ProcessEvent(result)
	if self.Type == "Action Set" then
		self.isSet = self.TriggerDetails.ActionSets[result]
	elseif self.Type == "Resources" then
		return self:ProcessResources(result)
	elseif self.Type == "Gadget" then
		self:ProcessSpell(result)
	else
		self.isSet = true
	end
end

function IconTrigger:ProcessResources(result)
	self.isSet = true
	if self.TriggerDetails["Mana"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Mana, result.Mana, result.MaxMana)
	end

	if self.TriggerDetails["Resource"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Resource, result.Resource, result.MaxResource)
	end

	self.Resources = result
end

function IconTrigger:ProcessHealth(result)
	self.isSet = true
	if self.TriggerDetails["Health"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Health, result.Health, result.MaxHealth)
	end

	if self.TriggerDetails["Shield"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Shield, result.Shield, result.MaxShield)
	end
end

function IconTrigger:ProcessResource(operation, resource, maxResource)
	local resourceValue = 0
	if resource ~= nil then
		if operation.Percent then
			resourceValue = (resource / maxResource) * 100
		else
			resourceValue = resource
		end

		if operation.Operator == "==" then
			return resourceValue == operation.Value
		elseif operation.Operator == "!=" then
			return resourceValue ~= operation.Value
		elseif operation.Operator == ">" then
			return resourceValue > operation.Value
		elseif operation.Operator == "<" then
			return resourceValue < operation.Value
		elseif operation.Operator == ">=" then
			return resourceValue >= operation.Value
		elseif operation.Operator == "<=" then
			return resourceValue <= operation.Value
		end
	end
end

function IconTrigger:ProcessMOO(result)
	if result.TimeRemaining > 0 then
		self.isSet = true
		self.Time = result.TimeRemaining
		if self.MaxDuration == nil or self.MaxDuration < self.Time then
			self.MaxDuration = self.Time
		end
	else
		self.MaxDuration = nil
	end
end

function IconTrigger:ProcessKeybind(iKey)
	if (self.TriggerDetails.Input.Shift and not Apollo.IsShiftKeyDown()) or
		(self.TriggerDetails.Input.Control and not Apollo.IsControlKeyDown()) or
		(self.TriggerDetails.Input.Alt and not Apollo.IsAltKeyDown()) then
		return
	end
	self.lastKeypress = Apollo.GetTickCount()
end

function IconTrigger:ProcessLASChange(result)
	self.isSet = result
end

function IconTrigger:IsOperatorSatisfied(value, operator, compValue)
	if operator == "==" then
		return value == compValue
	elseif operator == "!=" then
		return value ~= compValue
	elseif operator == ">" then
		return value > compValue
	elseif operator == "<" then
		return value < compValue
	elseif operator == ">=" then
		return value >= compValue
	elseif operator == "<=" then
		return value <= compValue
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)