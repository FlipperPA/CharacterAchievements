-- ----------------------------------------------------------------------------
-- Character Achievements 
-- 		by Nasapunk88
-- ----------------------------------------------------------------------------

CharacterAchievements = {};
CharacterAchievementsDB = CharacterAchievementsDB or {};
CharacterAchievements_Debug = false;

local function cout(msg, premsg)
	premsg = premsg or "[".."Character Achievements".."]"
	print("|cFFE8A317"..premsg.."|r "..msg);
end

local function coutBool(msg,bool)
	if bool then
		print(msg..": true");
	else
		print(msg..": false");
	end
end

local function colorizeAchievement(button,account,character)
	--Color AchievementButtons
	if CharacterAchievementsDB.isAccountWide then
		if account and (not character) then
			button:SetBackdropBorderColor(0.129,0.671,0.875,1); --blue for account
		elseif (not button.accountWide) and character then
			button:SetBackdropBorderColor(0.7,0.15,0.05,1); --red for character
		end
	else
		if character then
			button:Saturate();
		else
			button:Desaturate();
			if account and not CharacterAchievementsDB.defaultSkin then
				--button:SetBackdropBorderColor(0.129,0.671,0.875,1);
				button:SetBackdropBorderColor(ACHIEVEMENT_BLUE_BORDER_COLOR:GetRGB());
				button.Icon:Saturate();
				button.Shield:Saturate();
				button.Shield.Points:SetVertexColor(1, 1, 1);
				button.Glow:SetVertexColor(0.10, 0.10, 0.10);
				button.TitleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders");
				button.TitleBar:SetTexCoord(0, 1, 0.66015625, 0.73828125);
			end
		end	
	end
end

local function showCompletedDate(button,account,character)
	if CharacterAchievementsDB.hideCompletedDate then
		button.DateCompleted:Hide();
	elseif character then 
		button.DateCompleted:Show();
	elseif CharacterAchievementsDB.defaultSkin then 
		if account and not character then
			if not CharacterAchievementsDB.isAccountWide then
				button.DateCompleted:Hide();
			elseif CharacterAchievementsDB.isAccountWide then
				button.DateCompleted:Show();
			end
		end
	end
end

local function updatePoints()
	--Update Achievement Pts
	if CharacterAchievementsDB.isAccountWide then
		AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(GetTotalAchievementPoints()));
	else
		if (IsInGuild()) then
			for i=1,GetNumGuildMembers() do 
				if Ambiguate(select(1,GetGuildRosterInfo(i)), "none") == CharacterAchievementsDB.fullName then 
					AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(select(12,GetGuildRosterInfo(i))));
					break;
				end 
			end 
		else 
			--AchievementFrame.Header.Points:SetText(CharacterAchievementsDB.characterPoints);
			AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(CharacterAchievementsDB.characterPoints));
		end
	end
end

local function postHook_Frame()
	
	--Update Achievements
	local function UpdateAchievementDisplay(self, elementData)
		if AchievementFrame.selectedTab == 1 or AchievementFrame.selectedTab == 3 then
			if elementData then
				local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(self.id);
				colorizeAchievement(self,completed,wasEarnedByMe);
				showCompletedDate(self,completed,wasEarnedByMe);
				updatePoints();
			end
		end
	end
	
	--Hook Achievement Button Display
	hooksecurefunc(AchievementTemplateMixin, "Init", UpdateAchievementDisplay)
	
	--Post Hook Summary Display
	local orig_AchievementFrameSummary_UpdateAchievements = AchievementFrameSummary_UpdateAchievements;
	function AchievementFrameSummary_UpdateAchievements(...)
		local result = orig_AchievementFrameSummary_UpdateAchievements(...);
		local buttons = AchievementFrameSummaryAchievements.buttons;
			if AchievementFrame.selectedTab == 1 or AchievementFrame.selectedTab == 3 then
			if ( buttons ) then
				for i=1, _G["ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS"] do
					local account = select(4,GetAchievementInfo(buttons[i].id));
					local character = select(13,GetAchievementInfo(buttons[i].id));
					colorizeAchievement(buttons[i],account,character);
					showCompletedDate(buttons[i],account,character);
				end
			end
			updatePoints();
		end
		return result;
	end
	
	
	--Update Compare achievements
	local function UpdateCompareAchievementDisplay(self, elementData)
		if elementData then
			local category = elementData.category;
			local index = elementData.index;
			local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(category, index);
			colorizeAchievement(self.Player,completed,wasEarnedByMe);
			showCompletedDate(self.Player,completed,wasEarnedByMe);
			updatePoints();
		end
	end
	
	--Hook Achievement Button Display
	hooksecurefunc(AchievementComparisonTemplateMixin , "Init", UpdateCompareAchievementDisplay)
	
	
	------------------------------------------------------------------------------
	--      Update points hookscripts
	------------------------------------------------------------------------------
	
	--Post Hook Achievement Frame Refresh View
	local orig_AchievementFrame_RefreshView = AchievementFrame_RefreshView;
	function AchievementFrame_RefreshView(...)
		local result = orig_AchievementFrame_RefreshView(...);
		if AchievementFrame.selectedTab == 1 or AchievementFrame.selectedTab == 3 then
			updatePoints();
		end
		return result;
	end
	
	--Post Hook Achievement Frame Tab Click
	local orig_AchievementFrameBaseTab_OnClick = AchievementFrameBaseTab_OnClick;
	function AchievementFrameBaseTab_OnClick(...)
		local result = orig_AchievementFrameBaseTab_OnClick(...);
		AchievementFrame_RefreshView();
		return result;
	end
	
end

local function toggleMove(bool)
	CharacterAchievementsDB.isMovementEnabled = bool;
	CharacterAchievements.Interface.Movement:SetChecked(CharacterAchievementsDB.isMovementEnabled);
	if bool then
		CharacterAchievements.Frame:SetMovable(true)
		CharacterAchievements.Frame:EnableMouse(true)
		CharacterAchievements.Frame:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not self.isMoving then
				self:StartMoving();
				self.isMoving = true;
			end
		end)
		CharacterAchievements.Frame:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and self.isMoving then
				self:StopMovingOrSizing();
				self.isMoving = false;
				--Set New location relative to AchievementFrame 
				--Allows other addons to move the frame with button
				self:ClearAllPoints();
				local x = (self:GetLeft() - AchievementFrame.Header:GetLeft());
				local y = (self:GetTop() - AchievementFrame.Header:GetTop());
				self:SetPoint("TOPLEFT", AchievementFrame.Header, "TOPLEFT", x, y);
				CharacterAchievementsDB.position = {
					point = "TOPLEFT",
					relativePoint = "TOPLEFT",
					xOffset = x,
					yOffset = y
				};
			end
		end)
		CharacterAchievements.Frame:SetScript("OnHide", function(self)
			if self.isMoving then
				self:StopMovingOrSizing();
				self.isMoving = false;
				--Set New location relative to AchievementFrame 
				--Allows other addons to move the frame with button
				self:ClearAllPoints();
				local x = (self:GetLeft() - AchievementFrame.Header:GetLeft());
				local y = (self:GetTop() - AchievementFrame.Header:GetTop());
				self:SetPoint("TOPLEFT", AchievementFrame.Header, "TOPLEFT", x, y);
				CharacterAchievementsDB.position = {
					point = "TOPLEFT",
					relativePoint = "TOPLEFT",
					xOffset = x,
					yOffset = y
				};
			end
		end)
	else
		CharacterAchievements.Frame:SetMovable(false)
		CharacterAchievements.Frame:EnableMouse(false)
		CharacterAchievements.Frame:SetScript("OnMouseDown", nil)
		CharacterAchievements.Frame:SetScript("OnMouseUp", nil)
		CharacterAchievements.Frame:SetScript("OnHide", nil)
	end
end

local function toggleAccountWide(bool)
	--Checked = Account-earned, Unchecked = Character specific
	if (not IsInGuild() and not bool and CharacterAchievementsDB.achievementEarned) then
		CharacterAchievementsDB.accountAchievementsHidden = AreAccountAchievementsHidden();
		ShowAccountAchievements(true);
		InspectAchievements(UnitName("player"));
		CharacterAchievementsDB.characterInspect = true;
	end
	CharacterAchievementsDB.isAccountWide = bool;
	CharacterAchievements.CheckButton:SetChecked(CharacterAchievementsDB.isAccountWide);
	CharacterAchievements.Interface.AccountWide:SetChecked(CharacterAchievementsDB.isAccountWide);
	AchievementFrame_ForceUpdate();
	AchievementFrameSummary_Update();
	AchievementFrameComparison_ForceUpdate();
	--AchievementFrame_RefreshView();
end

local function toggleButton(bool)
	CharacterAchievementsDB.isEnabled = bool;
	CharacterAchievements.Interface.EnableFrame:SetChecked(CharacterAchievementsDB.isEnabled);
	if bool then
		CharacterAchievements.Frame:Show();
	else
		CharacterAchievements.Frame:Hide();
	end
end

local function toggleDate(bool)
	CharacterAchievementsDB.hideCompletedDate = bool;
	CharacterAchievements.Interface.Date:SetChecked(CharacterAchievementsDB.hideCompletedDate);
	AchievementFrame_ForceUpdate();
	AchievementFrameSummary_Update();
end

local function toggleDefaultSkin(bool)
	CharacterAchievementsDB.defaultSkin = bool;
	CharacterAchievements.Interface.DefaultSkin:SetChecked(CharacterAchievementsDB.defaultSkin);
	AchievementFrame_ForceUpdate();
	AchievementFrameSummary_Update();
end


local function resetConfig()
	CharacterAchievementsDB.position = {
		point = "TOPLEFT",
		relativePoint = "TOPLEFT",
		xOffset = -7.8,
		yOffset = -53.5
	};
	if (IsInGuild()) then
		toggleAccountWide(false);
	else
		CharacterAchievementsDB.achievementEarned = true;
		toggleAccountWide(true);
	end
	toggleMove(false);
	toggleButton(true);
	toggleDate(false);
	toggleDefaultSkin(false);
	CharacterAchievements.Frame:ClearAllPoints();
	CharacterAchievements.Frame:SetPoint("TOPLEFT", AchievementFrame.Header, "TOPLEFT", CharacterAchievementsDB.position.xOffset, CharacterAchievementsDB.position.yOffset);
end

------------------------------------------------
-- Interface Options
------------------------------------------------

local function interfaceOptions_OnShow(self)
	if not (CharacterAchievements.Interface.AccountWide == nil) then
		CharacterAchievements.Interface.AccountWide:SetChecked(CharacterAchievementsDB.isAccountWide);
	end
	if not (CharacterAchievements.Interface.EnableFrame == nil) then
		CharacterAchievements.Interface.EnableFrame:SetChecked(CharacterAchievementsDB.isEnabled);
	end
	if not (CharacterAchievements.Interface.Movement == nil) then
		CharacterAchievements.Interface.Movement:SetChecked(CharacterAchievementsDB.isMovementEnabled);
	end
	if not (CharacterAchievements.Interface.Date == nil) then
		CharacterAchievements.Interface.Date:SetChecked(CharacterAchievementsDB.hideCompletedDate);
	end
	if not (CharacterAchievements.Interface.DefaultSkin == nil) then
		CharacterAchievements.Interface.DefaultSkin:SetChecked(CharacterAchievementsDB.defaultSkin);
	end
end

local function interfaceOptions_Okay(self)
	--Settings save as they are changed automatically
end

local function interfaceOptions_Cancel(self)
	--Settings save as they are changed automatically
end

local function interfaceOptions_Default(self)
	resetConfig();
end

local function setupInterfaceOptions()
	CharacterAchievements.Interface = {};
	CharacterAchievements.InterfacePanel = CreateFrame("Frame", "CharacterAchievements_InterfacePanel", InterfaceOptionsFramePanelContainer);
	CharacterAchievements.InterfacePanel.name = "Character Achievements";
	CharacterAchievements.InterfacePanel:Hide();
	CharacterAchievements.InterfacePanel.okay = function(self) interfaceOptions_Okay(self) end
	CharacterAchievements.InterfacePanel.cancel = function(self) interfaceOptions_Cancel(self) end
	CharacterAchievements.InterfacePanel.default = function(self) interfaceOptions_Default(self) end
	CharacterAchievements.InterfacePanel:SetScript("OnShow", function(self) interfaceOptions_OnShow(self) end);
	
	--Title
	CharacterAchievements.Interface.ConfigTitle = CharacterAchievements.InterfacePanel:CreateFontString("CharacterAchievements_ConfigTitle", "ARTWORK", "GameFontNormalLarge");
    CharacterAchievements.Interface.ConfigTitle:SetPoint("TOPLEFT", 16, -16);
    CharacterAchievements.Interface.ConfigTitle:SetText("Character Achievements");
	
	--Description
	CharacterAchievements.Interface.ConfigSubtitle = CharacterAchievements.InterfacePanel:CreateFontString("CharacterAchievements_ConfigSubtitle", "ARTWORK", "GameFontHighlight");
    CharacterAchievements.Interface.ConfigSubtitle:SetHeight(22);
    CharacterAchievements.Interface.ConfigSubtitle:SetPoint("TOPLEFT", CharacterAchievements_ConfigTitle, "BOTTOMLEFT", 0, -8);
    CharacterAchievements.Interface.ConfigSubtitle:SetPoint("RIGHT", CharacterAchievements_InterfacePanel, -32, 0);
    CharacterAchievements.Interface.ConfigSubtitle:SetNonSpaceWrap(false);
	CharacterAchievements.Interface.ConfigSubtitle:SetWordWrap(true);
    CharacterAchievements.Interface.ConfigSubtitle:SetJustifyH("LEFT");
    CharacterAchievements.Interface.ConfigSubtitle:SetJustifyV("TOP");
    CharacterAchievements.Interface.ConfigSubtitle:SetText("Toggle Achievement display between highlighting Account-earned or Character Achievements");
	
	--Account Wide CheckButton
	CharacterAchievements.Interface.AccountWide = CreateFrame("CheckButton", "CharacterAchievements_AccountWide", CharacterAchievements.InterfacePanel, "InterfaceOptionsCheckButtonTemplate");
    CharacterAchievements.Interface.AccountWide:SetPoint("TOPLEFT", CharacterAchievements_ConfigSubtitle, "BOTTOMLEFT", 16, -6);
	_G[CharacterAchievements.Interface.AccountWide:GetName().."Text"]:SetText("Display Account-earned Achievements");
	CharacterAchievements.Interface.AccountWide:SetScript("OnClick", function(self, button, down)  
		PlaySound(self:GetChecked() and 856 or 857);
		toggleAccountWide(self:GetChecked() and true or false);
		end);
	CharacterAchievements.Interface.AccountWide.tooltipText = "Account-earned";
	CharacterAchievements.Interface.AccountWide.tooltipRequirement = "Enable Account-earned Style.";
	
	--Enable EnableFrame CheckButton
	CharacterAchievements.Interface.EnableFrame = CreateFrame("CheckButton", "CharacterAchievements_EnableFrame", CharacterAchievements.InterfacePanel, "InterfaceOptionsCheckButtonTemplate");
    CharacterAchievements.Interface.EnableFrame:SetPoint("TOPLEFT", CharacterAchievements_AccountWide, "BOTTOMLEFT", 0, -15);
	_G[CharacterAchievements.Interface.EnableFrame:GetName().."Text"]:SetText("Enable Button on Achievement Frame");
	CharacterAchievements.Interface.EnableFrame:SetScript("OnClick", function(self, button, down)	
		PlaySound(self:GetChecked() and 856 or 857);
		toggleButton(self:GetChecked() and true or false);
		end);
	CharacterAchievements.Interface.EnableFrame.tooltipText = "Button";
	CharacterAchievements.Interface.EnableFrame.tooltipRequirement = "Enable Display of the Button on the Achievement Frame.";
	
	--Enable Movement CheckButton
	CharacterAchievements.Interface.Movement = CreateFrame("CheckButton", "CharacterAchievements_Move", CharacterAchievements.InterfacePanel, "InterfaceOptionsCheckButtonTemplate");
    CharacterAchievements.Interface.Movement:SetPoint("TOPLEFT", CharacterAchievements_EnableFrame, "BOTTOMLEFT", 0, 0);
	_G[CharacterAchievements.Interface.Movement:GetName().."Text"]:SetText("Enable Movement of Button");
	CharacterAchievements.Interface.Movement:SetScript("OnClick", function(self, button, down)	
		PlaySound(self:GetChecked() and 856 or 857);
		toggleMove(self:GetChecked() and true or false);
		end);
	CharacterAchievements.Interface.Movement.tooltipText = "Movement";
	CharacterAchievements.Interface.Movement.tooltipRequirement = "Enable Movement of the Achievement Display Button.";
	
	--Hide Completed Date
	CharacterAchievements.Interface.Date = CreateFrame("CheckButton", "CharacterAchievements_Date", CharacterAchievements.InterfacePanel, "InterfaceOptionsCheckButtonTemplate");
    CharacterAchievements.Interface.Date:SetPoint("TOPLEFT", CharacterAchievements_Move, "BOTTOMLEFT", 0, -15);
	_G[CharacterAchievements.Interface.Date:GetName().."Text"]:SetText("Hide Completed Date");
	CharacterAchievements.Interface.Date:SetScript("OnClick", function(self, button, down)	
		PlaySound(self:GetChecked() and 856 or 857);
		toggleDate(self:GetChecked() and true or false);
		end);
	CharacterAchievements.Interface.Date.tooltipText = "Completed Date";
	CharacterAchievements.Interface.Date.tooltipRequirement = "Hide the completed date for all achievements.";
	
	--Default Style no account wide achievement
	CharacterAchievements.Interface.DefaultSkin = CreateFrame("CheckButton", "CharacterAchievements_DefaultSkin", CharacterAchievements.InterfacePanel, "InterfaceOptionsCheckButtonTemplate");
    CharacterAchievements.Interface.DefaultSkin:SetPoint("TOPLEFT", CharacterAchievements_Date, "BOTTOMLEFT", 0, -15);
	_G[CharacterAchievements.Interface.DefaultSkin:GetName().."Text"]:SetText("Disable Account-wide coloring");
	CharacterAchievements.Interface.DefaultSkin:SetScript("OnClick", function(self, button, down)	
		PlaySound(self:GetChecked() and 856 or 857);
		toggleDefaultSkin(self:GetChecked() and true or false);
		end);
	CharacterAchievements.Interface.DefaultSkin.tooltipText = "Default Skin";
	CharacterAchievements.Interface.DefaultSkin.tooltipRequirement = "Colors achievements as if there was no Account-Wide";
	
	--Reset Settings
	CharacterAchievements.Interface.ResetUI = CreateFrame("Button", "CharacterAchievements_ResetUI", CharacterAchievements.InterfacePanel, "UIPanelButtonTemplate");
	CharacterAchievements.Interface.ResetUI:SetText("Reset Settings and Position");
	CharacterAchievements.Interface.ResetUI:SetWidth(177);
	CharacterAchievements.Interface.ResetUI:SetHeight(24);
	CharacterAchievements.Interface.ResetUI:SetPoint("TOPLEFT", CharacterAchievements_DefaultSkin, "BOTTOMLEFT",0,-40);
	CharacterAchievements.Interface.ResetUI:SetScript("OnClick", function()
		resetConfig();
	end);
	CharacterAchievements.Interface.ResetUI.tooltipText = "Reset's all settings to default values";
	
	--Note: Not in guild
	CharacterAchievements.Interface.ConfigSubtitle = CharacterAchievements.InterfacePanel:CreateFontString("CharacterAchievements_ConfigSubtitle", "ARTWORK", "GameFontHighlight");
    CharacterAchievements.Interface.ConfigSubtitle:SetHeight(18);
    CharacterAchievements.Interface.ConfigSubtitle:SetPoint("TOPLEFT", CharacterAchievements_ResetUI, "BOTTOMLEFT", 0, -40);
    CharacterAchievements.Interface.ConfigSubtitle:SetPoint("RIGHT", CharacterAchievements_InterfacePanel, -32, 0);
    CharacterAchievements.Interface.ConfigSubtitle:SetNonSpaceWrap(false);
	CharacterAchievements.Interface.ConfigSubtitle:SetWordWrap(true);
    CharacterAchievements.Interface.ConfigSubtitle:SetJustifyH("LEFT");
    CharacterAchievements.Interface.ConfigSubtitle:SetJustifyV("TOP");
    CharacterAchievements.Interface.ConfigSubtitle:SetText("Note: Workaround required for characters not in a guild.");
	
	InterfaceOptions_AddCategory(CharacterAchievements.InterfacePanel);
end

local function openInterfaceOptions()
	InterfaceOptionsFrame_OpenToCategory(CharacterAchievements.InterfacePanel)
end

CharacterAchievements.cout = cout;
CharacterAchievements.toggleMove = toggleMove;
CharacterAchievements.postHook_Frame = postHook_Frame;
CharacterAchievements.toggleAccountWide = toggleAccountWide;
CharacterAchievements.toggleButton = toggleButton;
CharacterAchievements.toggleDate = toggleDate;
CharacterAchievements.toggleDefaultSkin = toggleDefaultSkin;
CharacterAchievements.setupInterfaceOptions = setupInterfaceOptions;
CharacterAchievements.openInterfaceOptions = openInterfaceOptions;
CharacterAchievements.resetConfig = resetConfig;
------------------------------------------------
-- Global Functions
------------------------------------------------

function CharacterAchievements.OnEvent(self,event,...)
	if event == "PLAYER_LOGIN" then
		CharacterAchievements.Frame:UnregisterEvent("PLAYER_LOGIN");
		--Added to fix conflict with SLASH_CharacterAchievement1 addon
		if not AchievementFrame then  
			AchievementFrame_LoadUI();  
		end
		if next (CharacterAchievementsDB) == nil then
			resetConfig();
		else
			if (IsInGuild()) then
				toggleAccountWide(CharacterAchievementsDB.isAccountWide);
			else
				--Force Character Point Update on login
				CharacterAchievementsDB.characterPoints = GetTotalAchievementPoints();
				CharacterAchievementsDB.achievementEarned = true;
				toggleAccountWide(true);
			end
			toggleMove(CharacterAchievementsDB.isMovementEnabled);
			toggleButton(CharacterAchievementsDB.isEnabled);
			toggleDate(CharacterAchievementsDB.hideCompletedDate);
			toggleDefaultSkin(CharacterAchievementsDB.defaultSkin);
		end

		--Update Full name
		CharacterAchievementsDB.fullName = UnitName("player"); --.."-"..GetRealmName();
		--Post Hook Achievement Frame to enable toggle switch
		postHook_Frame();
		
	elseif (event == "INSPECT_ACHIEVEMENT_READY") then
		if (CharacterAchievementsDB.characterInspect) then
			CharacterAchievementsDB.characterPoints = GetComparisonAchievementPoints();
			AchievementFrame.Header.Points:SetText(CharacterAchievementsDB.characterPoints);
			CharacterAchievementsDB.characterInspect = false;
			CharacterAchievementsDB.achievementEarned = false;
			ShowAccountAchievements(CharacterAchievementsDB.accountAchievementsHidden);
		end
	elseif (event == "ACHIEVEMENT_EARNED") then
		--Force Character Point Update
		if (not IsInGuild()) then
			CharacterAchievementsDB.achievementEarned = true;
			toggleAccountWide(true);
		end
	end
end

------------------------------------------------
-- Slash Commands
------------------------------------------------
local function slashHandler(msg)
	msg = msg:lower() or "";
	if (msg == "account" or msg == "a") then
		CharacterAchievements.toggleAccountWide(true);
	elseif (msg == "character" or msg == "c") then
		CharacterAchievements.toggleAccountWide(false);
	elseif (msg == "options" or msg == "gui") then
		CharacterAchievements.openInterfaceOptions();
	elseif (msg == "lock") then
		CharacterAchievements.toggleMove(false);
	elseif (msg == "unlock") then
		CharacterAchievements.toggleMove(true);
	elseif (msg == "hide") then
		CharacterAchievements.toggleButton(false);
	elseif (msg == "show") then
		CharacterAchievements.toggleButton(true);
	elseif (msg == "reset") then
		resetConfig();
	else
		print("|cff33ff99Character Achievements|r: Arguments to |cffffff78/ca|r :");
		print("  |cffffff78 options|r - Display the options");
		print("  |cffffff78 account|r - Display Account-earned style");
		print("  |cffffff78 character|r - Display Character style");
		print("  |cffffff78 hide|r - Hide button");
		print("  |cffffff78 show|r - Show button");
		print("  |cffffff78 unlock|r - Unlock button");
		print("  |cffffff78 lock|r - Lock button");
		print("  |cffffff78 reset|r - Restores default settings and button position");
	end
end

SlashCmdList.CharacterAchievement = function(msg) slashHandler(msg) end;
SLASH_CharacterAchievement1 = "/ca";
SLASH_CharacterAchievement2 = "/characterachievements";
SLASH_CharacterAchievement3 = "/characterachievement";

------------------------------------------------
-- Character Achievement Frame Setup
------------------------------------------------
CharacterAchievements.Frame = CreateFrame("Frame", "CharacterAchievementsFrame", AchievementFrame.Header,BackdropTemplateMixin and "BackdropTemplate");
CharacterAchievements.Frame:SetPoint("TOPLEFT", AchievementFrame.Header, "TOPLEFT", 9, -58);

CharacterAchievements.Frame:SetWidth(188);
CharacterAchievements.Frame:SetHeight(41);
CharacterAchievements.Frame:SetFrameStrata("HIGH");
CharacterAchievements.Frame:SetClampedToScreen(true);
CharacterAchievements.Frame:SetBackdrop({bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Category-Background", 
                                            --edgeFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-WoodBorder", 
                                            tile = false, tileSize = 64, --edgeSize = 4, 
                                            insets = { left = 1, right = 1, top = 1, bottom = 1 }});
CharacterAchievements.Frame:SetBackdropBorderColor(ACHIEVEMENT_GOLD_BORDER_COLOR:GetRGB());

CharacterAchievements.Frame:SetScript("OnEvent", function(self,event,...) CharacterAchievements.OnEvent(self,event,...) end);
CharacterAchievements.Frame:SetScript("OnShow", function(self)
	if CharacterAchievementsDB and CharacterAchievementsDB.position then
		CharacterAchievements.Frame:ClearAllPoints();
		CharacterAchievements.Frame:SetPoint("TOPLEFT", AchievementFrame.Header, "TOPLEFT", CharacterAchievementsDB.position.xOffset, CharacterAchievementsDB.position.yOffset);
	end
	if CharacterAchievements.CheckButton then
		CharacterAchievements.CheckButton:SetChecked(CharacterAchievementsDB.isAccountWide);
	end
end);
CharacterAchievements.Frame:RegisterEvent("PLAYER_LOGIN");
CharacterAchievements.Frame:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
CharacterAchievements.Frame:RegisterEvent("ACHIEVEMENT_EARNED");

-- Implement the check button ontop of frame
CharacterAchievements.CheckButton = CreateFrame("CheckButton", "CharacterAchievements_CheckButton", CharacterAchievements.Frame, "UICheckButtonTemplate");
CharacterAchievements.CheckButton:SetPoint("LEFT", CharacterAchievements.Frame, "LEFT", 5,1.8);
CharacterAchievements.CheckButton:SetWidth(28);
CharacterAchievements.CheckButton:SetHeight(28);
CharacterAchievements.CheckButton.tooltip = "This toggles the display of Account-earned or Character Achievements";
CharacterAchievements.CheckButton:SetScript("OnClick", function(self, button, down)
	CharacterAchievements.toggleAccountWide(self:GetChecked() and true or false);
end);
_G[CharacterAchievements.CheckButton:GetName() .. "Text"]:SetText("Account-earned")

--Implement Interface Options
CharacterAchievements.setupInterfaceOptions();