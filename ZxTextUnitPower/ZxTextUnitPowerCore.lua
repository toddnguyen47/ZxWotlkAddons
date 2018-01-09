local function enableFrameMovement(frameInput)
	frameInput:SetMovable(true);
	frameInput:EnableMouse(true);
	frameInput:RegisterForDrag("LeftButton");
	frameInput:SetScript("OnDragStart", frameInput.StartMoving);
	frameInput:SetScript("OnDragStop", frameInput.StopMovingOrSizing);
end

local function SetFrameSize(frame, width, height)
	frame:SetWidth(width);
	frame:SetHeight(height);
end

local function createBlackBg(frame, alphaLevel)
	frame.texture1 = frame:CreateTexture(nil, "BACKGROUND");
	frame.texture1:SetTexture(0, 0, 0, alphaLevel);
	frame.texture1:SetAllPoints();
	
	return frame.texture1;
end

local function shortenNumber(number)
	local strNumber = nil

	if number < 1000 then
		strNumber = string.format("%d", number)
	elseif number < 1000000 then
		strNumber = string.format("%.1fK", number/1000)
	else
		strNumber = string.format("%.1fM", number/1000000)
	end

	return strNumber
end


local function getRgb()
	-- Get color
	local powerType, powerToken, altR, altG, altB = UnitPowerType("Player")
	local info = PowerBarColor[powerToken]

	if info then
		r, g, b = info.r, info.g, info.b
	else
		if not altR then
			-- couldn't find a power token entry. default to mana
			info = PowerBarColor[powerType] or PowerBarColor["MANA"]
			r, g, b = info.r, info.g, info.b
		else
			r, g, b = altR, altG, altB
		end
	end

	return r, g, b, powerToken
end

-- Wrapper function to register for multipke power types
local function registerForEvents(unitInput)
	ZxMasterFrame.MainFrame:RegisterEvent(unitInput)
end

-- Wrapper function to color texture
local function drawTexture(frameInput)
	local r, g, b, powerToken = getRgb();
	if (powerToken == "MANA") then
		frameInput:SetStatusBarColor(r, g, b, 0.5);
	else
		frameInput:SetStatusBarColor(r, g, b, 0.7);
	end 
end

powerRegistered = {
	"UNIT_MANA",
	"UNIT_RAGE",
	"UNIT_ENERGY",
	"UNIT_RUNIC_POWER"
}

local function writePowerValue()
	local _, value = UnitPowerType("Player");
	if (value == "UNIT_MANA" or value == "MANA") then
		local curPower = UnitPower("Player");
		local maxPower = UnitPowerMax("Player");
		local perPower = curPower / maxPower * 100;
		percentage = string.format("%.1f %%", perPower);
		ZxMasterFrame.MainFrame.UnitPowerDisplay:SetText(percentage);
	else
		ZxMasterFrame.MainFrame.UnitPowerDisplay:SetText(UnitPower("Player"));
	end
end

local function hasValue(value)
	for _, power in pairs(powerRegistered) do
		if (value == power) then
			return true;
		end
	end
	
	return false
end

local function playerSetMinMaxPower(frameInput)
	frameInput:SetMinMaxValues(0, UnitPowerMax("Player"));
	frameInput:SetValue(UnitPower("Player"));
end

local function createUnitDisplay(frameInput)

	local r, g, b, powerToken = getRgb();

	frameInput.statusB = CreateFrame("StatusBar", nil, frameInput);
	frameInput.statusB:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	frameInput.statusB:GetStatusBarTexture():SetHorizTile(false);
	frameInput.statusB:SetAllPoints();
	
	playerSetMinMaxPower(frameInput.statusB);
	drawTexture(frameInput.statusB);
	
	frameInput.UnitPowerDisplay = frameInput:CreateFontString(nil, "OVERLAY");
	frameInput.UnitPowerDisplay:SetFont("Interface\\AddOns\\ZxTextUnitPower\\PTSansBold.ttf", 16, "OUTLINE");
	frameInput.UnitPowerDisplay:SetAllPoints();
	_, unitPType = UnitPowerType("Player")
	writePowerValue()

	for _, power in pairs(powerRegistered) do 
		registerForEvents(power)
	end

	registerForEvents("UPDATE_SHAPESHIFT_FORM");
	
	frameInput:SetScript("OnEvent", function(self, event, unit)
		if (not(event == "UPDATE_SHAPESHIFT_FORM")) then
			playerSetMinMaxPower(frameInput.statusB);		
			writePowerValue();
		else
			playerSetMinMaxPower(frameInput.statusB);
			drawTexture(frameInput.statusB);
			writePowerValue();
		end
	end)
end

local function getPercentHp()
	local roundTo = 10.0 * 100.0;
	local curHp = UnitHealth("Target");
	local maxHp = UnitHealthMax("Target");
	local percentHp = nil;
	-- Save some calculation cycles
	if (maxHp == 0) then
		return maxHp;
	else
		percentHp = curHp / maxHp; -- for more accurate comparisons
		if (cur ~= 1.0) then
			percentHp = math.floor(percentHp * roundTo + 0.5) / roundTo;
		end
	end

	percentHp = percentHp * 100.0;
	return percentHp;
end

local function reverseBar(healthBar, currentHp)
	backgroundFrame = healthBar:GetParent();
	healthBar:SetMinMaxValues(0, currentHp);
	healthBar:ClearAllPoints();
	healthBar:SetPoint("BOTTOMRIGHT");		
	local tempWidth = backgroundFrame:GetWidth();
	local tempLocation = tempWidth - (tempWidth * currentHp / 100.0)
	healthBar:SetPoint("TOPLEFT", backgroundFrame, "TOPLEFT", tempLocation, 0);
end

local function showComboText(comboTextDisplay)
	local parent = comboTextDisplay:GetParent();
	local comboPointsDisplay = 	{
			"1",
			"2",
			"3",
			"4",
			"5 !!"
	}
	
	local comboPoints = GetComboPoints("Player", "Target");
			
	-- Only display if there IS a combo point
	if (comboPoints == 0) then
		parent:Hide();
	else
		comboTextDisplay:SetText(comboPointsDisplay[comboPoints]);
		parent:Show();
	end
end

-- MAIN TARGET HP FUNCTION
local function createTargetHp()	
	local bgFrame = CreateFrame("Frame", "ZxCreateTargetHpFrame", ZxMasterFrame);
	bgFrame:SetWidth(75);
	bgFrame:SetHeight(20);
	bgFrame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 0, -10);
	enableFrameMovement(bgFrame);
	bgFrame.texture1 = createBlackBg(bgFrame, 0.8);
	bgFrame:Hide(); -- Hide background frames initially
	
	-- Create green texture for health bars
	bgFrame.curHealthBar = CreateFrame("StatusBar", nil, ZxCreateTargetHpFrame);
	bgFrame.curHealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	bgFrame.curHealthBar:GetStatusBarTexture():SetHorizTile(false);
	bgFrame.curHealthBar:SetStatusBarColor(0, 1, 0, 0.5);
	
	-- Create health bar text
	bgFrame.textHealth = bgFrame:CreateFontString(nil, "OVERLAY");
	bgFrame.textHealth:SetFont("Interface\\AddOns\\ZxTextUnitPower\\PTSansBold.ttf", 16, "OUTLINE");
	bgFrame.textHealth:SetTextColor(1.0, 1.0, 1.0, 1.0);
	bgFrame.textHealth:SetAllPoints();
	
	-- Create combo point display
	bgFrame.comboPointBg = CreateFrame("Frame", nil, ZxCreateTargetHpFrame);
	bgFrame.comboPointBg.texture1 = createBlackBg(bgFrame.comboPointBg, 0.5);
	SetFrameSize(bgFrame.comboPointBg, math.floor(bgFrame:GetWidth() / 2), bgFrame:GetHeight());
	bgFrame.comboPointBg:SetPoint("BOTTOM", ZxCreateTargetHpFrame, "TOP", 0, 0);
	
	bgFrame.comboPointBg.comboText = bgFrame.comboPointBg:CreateFontString(nil, "OVERLAY");
	bgFrame.comboPointBg.comboText:SetFont("Interface\\AddOns\\ZxTextUnitPower\\PTSansBold.ttf", 16, "OUTLINE");
	bgFrame.comboPointBg.comboText:SetTextColor(1.0, 1.0, 0.0, 1.0);
	bgFrame.comboPointBg.comboText:SetAllPoints();
	bgFrame.comboPointBg:Hide();
	
	bgFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	bgFrame:RegisterEvent("UNIT_HEALTH");
	bgFrame:RegisterEvent("UNIT_COMBO_POINTS");
	
	bgFrame:SetScript("OnEvent", function(self, event, unit)
		if (event == "PLAYER_TARGET_CHANGED") then
			tempHp = getPercentHp();
			-- If no target selected, then hide the frames
			if (tempHp == 0) then
				bgFrame:Hide();
				return;
			else
				showComboText(bgFrame.comboPointBg.comboText);				
				
				--reverseBar(bgFrame.curHealthBar, tempHp);
				bgFrame.curHealthBar:SetMinMaxValues(0, UnitHealthMax("Target"));
				bgFrame.curHealthBar:SetAllPoints();
				bgFrame.curHealthBar:SetValue(UnitHealth("Target"));
				
				bgFrame.textHealth:SetText(string.format("%0.1f%%", tempHp))
				bgFrame:Show();
			end
		
		elseif (event == "UNIT_HEALTH") then
			tempHp = getPercentHp();
			--reverseBar(bgFrame.curHealthBar, tempHp);
			bgFrame.curHealthBar:SetMinMaxValues(0, UnitHealthMax("Target"));
			bgFrame.curHealthBar:SetAllPoints();
			bgFrame.curHealthBar:SetValue(UnitHealth("Target"));
			
			bgFrame.textHealth:SetText(string.format("%0.1f%%", tempHp))
		end
		
		if (event == "UNIT_COMBO_POINTS") then
			showComboText(bgFrame.comboPointBg.comboText);	
		end
	end)
end

local function threatCheck()
	local _, _, scaledPercent =  UnitDetailedThreatSituation("Player", "Target");
	if scaledPercent == nil then
		scaledPercent = 0
	end
	
	return scaledPercent
end

local function createThreatDisplay()
	-- Create threat display
	local threatFrameBg = CreateFrame("Frame", "ZxThreatFrameBg", ZxMasterFrame);
	threatFrameBg:SetWidth(75);
	threatFrameBg:SetHeight(20);
	--threatFrameBg:SetPoint("BOTTOMRIGHT", TargetFrame, "TOPRIGHT", -40, -5);
	threatFrameBg:SetPoint("LEFT", ZxCreateTargetHpFrame, "RIGHT", 40, 0);
	enableFrameMovement(threatFrameBg);
	threatFrameBg.texture1 = createBlackBg(threatFrameBg, 0.8);
	
	-- Create actual texture of threat
	threatFrameBg.StatusBarThreat = CreateFrame("StatusBar", nil, ZxThreatFrameBg)
	threatFrameBg.StatusBarThreat:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	threatFrameBg.StatusBarThreat:GetStatusBarTexture():SetHorizTile(false);
	threatFrameBg.StatusBarThreat:SetMinMaxValues(0, 100);
	threatFrameBg.StatusBarThreat:SetAllPoints();
	
	-- Create text
	threatFrameBg.ThreatText = threatFrameBg:CreateFontString(nil, "OVERLAY")
	threatFrameBg.ThreatText:SetFont("Interface\\AddOns\\ZxTextUnitPower\\PTSansBold.ttf", 16, "OUTLINE");
	threatFrameBg.ThreatText:SetTextColor(1.0, 1.0, 1.0, 1.0);
	threatFrameBg.ThreatText:SetAllPoints();
	
	-- Initially hide
	threatFrameBg:Hide();
	threatFrameBg:RegisterEvent("PLAYER_TARGET_CHANGED");
	threatFrameBg:RegisterEvent("UNIT_HEALTH");
	
	threatFrameBg:SetScript("OnEvent", function(self, event, unit)
		if (event == "PLAYER_TARGET_CHANGED") then
			local maxHp = UnitHealthMax("Target");
			if maxHp == 0 then
				threatFrameBg:Hide();
			else
				local threatAmt = threatCheck()
				if threatAmt < 100 then
					threatFrameBg.StatusBarThreat:SetStatusBarColor(0.9, 0.8, 0.7, 0.8);
				else
					threatFrameBg.StatusBarThreat:SetStatusBarColor(1.0, 0.0, 0.0, 0.6);
				end
				
				threatFrameBg.StatusBarThreat:SetValue(threatAmt)
				threatFrameBg.ThreatText:SetText(string.format("%0.1f%%", threatAmt));
				
				threatFrameBg:Show();
			end
			
		elseif (event == "UNIT_HEALTH") then
			local threatAmt = threatCheck()
			if threatAmt < 100 then
				threatFrameBg.StatusBarThreat:SetStatusBarColor(0.9, 0.8, 0.7, 0.8);
			else
				threatFrameBg.StatusBarThreat:SetStatusBarColor(1.0, 0.0, 0.0, 0.6);
			end
			
			threatFrameBg.StatusBarThreat:SetValue(threatAmt)
			threatFrameBg.ThreatText:SetText(string.format("%0.1f%%", threatAmt));
		end
	end)
end

local function init()
	ZxMasterFrame = CreateFrame("Frame", "ZxMasterFrame", UIParent);
	ZxMasterFrame:SetPoint("CENTER", 0, 0);
	
	ZxMasterFrame.MainFrame = CreateFrame("Frame", "MainFrame", ZxMasterFrame)
	ZxMasterFrame.MainFrame:SetSize(75,20)
	ZxMasterFrame.MainFrame:SetPoint("BOTTOMLEFT", PlayerFrame, "TOP", -20, -15)
	enableFrameMovement(ZxMasterFrame.MainFrame);
	createBlackBg(ZxMasterFrame.MainFrame, 0.8);
	
	createUnitDisplay(ZxMasterFrame.MainFrame)
	createTargetHp();
	createThreatDisplay();
end


local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_LOGIN");
events:SetScript("OnEvent", function(self, event, addonName)
	if (event == "PLAYER_LOGIN") then
		init();
		self:UnregisterEvent("PLAYER_LOGIN");
	end
end)