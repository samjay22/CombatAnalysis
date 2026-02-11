
--[[

A Standard LOTRO Tab.

]]--

_G.Tab = class(Turbine.UI.Control);

function Tab:Constructor(tabbedPane,tabIndex,tabName,content)
	Turbine.UI.Control.Constructor(self);
  
	self.enabled = (content ~= nil);
	self.tabIndex = tabIndex;
	self.tabbedPane = tabbedPane;
	self.content = content;
  self.accentColor = Theme.Colors.accent;
	self.hovered = false;
	self.pressed = false;
	
	if (self.enabled) then
		self.content:SetPosition(2,24);
	end
	
	self:SetMouseVisible(true);
	self:SetParent(self.tabbedPane);
	self:SetPosition((tabIndex-1)*95,2);	
	self:SetSize(95,21);
	self:SetZOrder(-2);

	self.background = Turbine.UI.Control();
	self.background:SetParent(self);
	self.background:SetMouseVisible(false);
	self.background:SetZOrder(-1);
  Theme.ApplyInsetSurface(self.background);

	self.highlight = Turbine.UI.Control();
	self.highlight:SetParent(self);
	self.highlight:SetMouseVisible(false);
	self.highlight:SetZOrder(0);
	self.highlight:SetBackColor(self.accentColor);
	self.highlight:SetVisible(false);
	
	-- tab text
	self.text = Turbine.UI.Label();
	self.text:SetParent(self);
	self.text:SetText(tabName);
	self.text:SetSize(95,21);
	self.text:SetFont(Theme.Fonts.body);
	self.text:SetForeColor(self.enabled and controlColor or controlDisabledColor);
	self.text:SetFontStyle(Turbine.UI.FontStyle.None);
	self.text:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.text:SetMouseVisible(false);	

	self.SizeChanged = function()
		local w,h = self:GetSize();
		self.background:SetSize(w,h);
		self.highlight:SetSize(w,2);
		self.highlight:SetTop(h-2);
		self.text:SetSize(w,h);
	end

	self:SizeChanged();
	self:UpdateVisualState();
end

function Tab:SetColor(color)
  if (color == "Red") then
    self.accentColor = Theme.Colors.accentActive;
  elseif (color == "Yellow") then
    self.accentColor = Theme.Colors.accentHover;
  else
    self.accentColor = Theme.Colors.accent;
  end
  self.highlight:SetBackColor(self.accentColor);
  self:UpdateVisualState();
end

function Tab:SetSelected(selected)
	if (self.selected == selected) then return end
  
	self.selected = selected;
	self:UpdateVisualState();
	self.content:SetParent(self.selected and self.tabbedPane or nil);
  
  if (self.content.ContentSelected ~= nil) then
    if (selected) then
      self.content:ContentSelected();
    else
      self.content:ContentDeselected();
    end
  end
end

-- tab highlight events
function Tab:MouseEnter(args)
	if (self.enabled) then
		self.hovered = true;
		self:UpdateVisualState();
	end
end

function Tab:MouseLeave(args)
	if (self.enabled) then
		self.hovered = false;
		self.pressed = false;
		self:UpdateVisualState();
	end
end

function Tab:MouseDown(args)
	if (self.tabbedPane.window ~= nil) then WindowManager.MouseWasPressed(self.tabbedPane.window) end
	
	if (self.enabled) then
		self.pressed = true;
		self:UpdateVisualState();
	end
end

function Tab:MouseUp(args)
	if (self.enabled) then
		self.pressed = false;
		self:UpdateVisualState();
	end
end

function Tab:MouseClick(args)
	if (self.enabled) then
		self.tabbedPane:SelectTab(self.tabIndex);
	end
end

function Tab:UpdateVisualState()
	if (not self.enabled) then
		Theme.ApplyInsetSurface(self.background);
		self.highlight:SetVisible(false);
		self.text:SetForeColor(controlDisabledColor);
		return;
	end

	if (self.selected) then
		Theme.ApplyRaisedSurface(self.background);
		self.highlight:SetVisible(true);
		self.highlight:SetBackColor(self.accentColor);
		self.text:SetForeColor(self.pressed and Theme.Colors.accentActive or Theme.Colors.textPrimary);
	elseif (self.hovered) then
		Theme.ApplySurfaceBackground(self.background);
		self.highlight:SetVisible(true);
		self.highlight:SetBackColor(Theme.Colors.accentMuted);
		self.text:SetForeColor(Theme.Colors.accentHover);
	else
		Theme.ApplyInsetSurface(self.background);
		self.highlight:SetVisible(self.pressed);
		self.highlight:SetBackColor(self.accentColor);
		self.text:SetForeColor(controlColor);
	end

	if (self.pressed and self.selected) then
		self.highlight:SetBackColor(self.accentColor);
	end
end
