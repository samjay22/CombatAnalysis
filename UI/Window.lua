
--[[ A Silver LOTRO Window with a Correctly Centered Title Bar ]]--

_G.Window = class(Turbine.UI.Window);

-- colors
Window.TitleColor = Theme.Colors.textPrimary;
Window.TitleAccentColor = Theme.Colors.accent;

function Window:Constructor(dialog)
	Turbine.UI.Window.Constructor(self);
  
	if (not dialog) then
		table.insert(allWindows,self);
	end
	
	-- hidden lotro window so that the window can grab focus and to get the movement arrows
	--   (no more movement arrows as of RoI update 1)
	self.hidden = Turbine.UI.Lotro.Window();
	self.hidden:SetOpacity(0);
	self.hidden.PositionChanged = function(sender, args)
		if (type(self.PositionChanged) == "function") then
			self:PositionChanged(args);
		end
	end
	self.hidden.MouseUp = function(sender,args)
		-- save state after window moved
		self:SaveState();
	end
	
	self.titleWidth = 250;
	self:SetParent(self.hidden);
	self:SetMouseVisible(false);
	
	-- title label
	self.title = Turbine.UI.Label();
	self.title:SetParent(self);
	self.title:SetPosition(0,0);
	self.title:SetSize(0,26);
	self.title:SetZOrder(5);
	self.title:SetFont(Theme.Fonts.title);
	self.title:SetFontStyle(Turbine.UI.FontStyle.None);
	self.title:SetForeColor(Window.TitleColor);
	self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.title:SetMouseVisible(false);
  self.title:SetVisible(false);

  self.titleUnderline = Turbine.UI.Control();
  self.titleUnderline:SetParent(self);
  self.titleUnderline:SetSize(0,2);
  self.titleUnderline:SetZOrder(4);
  self.titleUnderline:SetBackColor(Window.TitleAccentColor);
  self.titleUnderline:SetMouseVisible(false);
  self.titleUnderline:SetVisible(false);

	-- top left corner
	self.topLeft = Turbine.UI.Control();
	self.topLeft:SetParent(self);
	self.topLeft:SetSize(36,36);
	self.topLeft:SetZOrder(-1);
	self.topLeft:SetMouseVisible(false);
	self.topLeft:SetBackColor(Theme.Colors.border);
	self.topLeft:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);

	-- topRight
	self.topRight = Turbine.UI.Control();
	self.topRight:SetParent(self);
	self.topRight:SetSize(36,36);
	self.topRight:SetZOrder(-1);
	self.topRight:SetMouseVisible(false);
	self.topRight:SetBackColor(Theme.Colors.border);
	self.topRight:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);
	
	-- bottomLeft
	self.bottomLeft = Turbine.UI.Control();
	self.bottomLeft:SetParent(self);
	self.bottomLeft:SetSize(36,36);
	self.bottomLeft:SetZOrder(-1);
	self.bottomLeft:SetMouseVisible(false);
	self.bottomLeft:SetBackColor(Theme.Colors.border);
	self.bottomLeft:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);

	-- bottomRight
	self.bottomRight = Turbine.UI.Control();
	self.bottomRight:SetParent(self);
	self.bottomRight:SetSize(36,36);
	self.bottomRight:SetZOrder(-1);
	self.bottomRight:SetMouseVisible(false);
	self.bottomRight:SetBackColor(Theme.Colors.border);
	self.bottomRight:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);

	-- top side
	self.top = Turbine.UI.Control();
	self.top:SetParent(self);
	self.top:SetSize(36,36);
	self.top:SetZOrder(-1);
	self.top:SetMouseVisible(false);
	self.top:SetBackColor(Theme.Colors.border);
	self.top:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);

	-- left side
	self.left = Turbine.UI.Control();
	self.left:SetParent(self);
	self.left:SetSize(36,36);
	self.left:SetZOrder(-1);
	self.left:SetMouseVisible(false);
	self.left:SetBackColor(Theme.Colors.border);
	self.left:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);

	-- right side
	self.right = Turbine.UI.Control();
	self.right:SetParent(self);
	self.right:SetSize(36,36);
	self.right:SetZOrder(-1);
	self.right:SetMouseVisible(false);
	self.right:SetBackColor(Theme.Colors.border);
	self.right:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);
	
	-- bottom side
	self.bottom = Turbine.UI.Control();
	self.bottom:SetParent(self);
	self.bottom:SetSize(36,36);
	self.bottom:SetZOrder(-1);
	self.bottom:SetMouseVisible(false);
	self.bottom:SetBackColor(Theme.Colors.border);
	self.bottom:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay);
	
	-- center
	self.center = Turbine.UI.Control();
	self.center:SetParent(self);
	self.center:SetZOrder(-1);
	self.center:SetMouseVisible(false);
  Theme.ApplySurfaceBackground(self.center);
	
	-- title left
	self.titleLeft = Turbine.UI.Control();
	self.titleLeft:SetParent(self);
	self.titleLeft:SetSize(35,42);
	self.titleLeft:SetZOrder(1);
	self.titleLeft:SetMouseVisible(false);
  Theme.ApplyRaisedSurface(self.titleLeft);
  self.titleLeft:SetVisible(false);

	-- title mid
	self.titleMid = Turbine.UI.Control();
	self.titleMid:SetParent(self);
	self.titleMid:SetSize(20,42);
	self.titleMid:SetZOrder(1);
	self.titleMid:SetMouseVisible(false);
  Theme.ApplyRaisedSurface(self.titleMid);
  self.titleMid:SetVisible(false);
	
	-- title right
	self.titleRight = Turbine.UI.Control();
	self.titleRight:SetParent(self);
	self.titleRight:SetSize(35,42);
	self.titleRight:SetZOrder(1);
	self.titleRight:SetMouseVisible(false);
  Theme.ApplyRaisedSurface(self.titleRight);
  self.titleRight:SetVisible(false);
	
	-- close button
	self.close = Turbine.UI.Label();
	self.close:SetParent(self);
	self.close:SetSize(16,16);
	self.close:SetZOrder(4);
	self.close:SetFont(Theme.Fonts.body);
	self.close:SetFontStyle(Turbine.UI.FontStyle.None);
	self.close:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.close:SetForeColor(Theme.Colors.textMuted);
	self.close:SetBackColor(Turbine.UI.Color(0,0,0,0));
	self.close:SetText("X");
	self.close.pressed = false;
	self.close.MouseEnter = function(sender, args)
		self.close:SetForeColor(Theme.Colors.accentHover);
		self.close:SetBackColor(Theme.Colors.overlay);
	end
	self.close.MouseLeave = function(sender, args)
		self.close.pressed = false;
		self.close:SetForeColor(Theme.Colors.textMuted);
		self.close:SetBackColor(Turbine.UI.Color(0,0,0,0));
	end
	self.close.MouseDown = function(sender, args)
		if (args.Button ~= Turbine.UI.MouseButton.Left) then return end
		WindowManager.MouseWasPressed(self);
		self.close.pressed = true;
		self.close:SetForeColor(Theme.Colors.accentActive);
	end
	self.close.MouseUp = function(sender, args)
		if (self.close.pressed) then
			self.close:SetForeColor(Theme.Colors.accentHover);
		end
		self.close.pressed = false;
	end
	self.close.MouseClick = function(sender, args)
		if (args.Button == Turbine.UI.MouseButton.Left) then
			self:Close();
		end
	end
end

function Window:SetText(text)
	self.title:SetText(text);
  self.title:SetVisible(text ~= nil and text ~= "");
  self.titleLeft:SetVisible(text ~= nil and text ~= "");
  self.titleMid:SetVisible(text ~= nil and text ~= "");
  self.titleRight:SetVisible(text ~= nil and text ~= "");
	self.titleUnderline:SetVisible(text ~= nil and text ~= "");
end

function Window:GetParent()
	return nil;
end

function Window:Activate()
	self.hidden:Activate();
  Turbine.UI.Window.Activate(self);
end

function Window:Close()
	Turbine.UI.Window.Close(self);
	self.hidden:Close();
	
	for i,window in ipairs(allWindows) do
		if (window == self) then
			table.remove(allWindows,i);
			return;
		end
	end
end

function Window:SetSize(width,height,dontLayout)
	Turbine.UI.Window.SetSize(self,width,height);
	self.hidden:SetSize(width, height);
	if (not dontLayout) then self:Layout() end
end

function Window:SetPosition(x,y)
	self.hidden:SetPosition(x,y);
end

function Window:GetPosition()
	return self.hidden:GetPosition();
end

function Window:SetVisible(visible,dontActivate)
	Turbine.UI.Window.SetVisible(self,visible);
	self.hidden:SetVisible(visible);
	if (visible and not dontActivate) then self:Activate() end
end

function Window:Layout()
	local width, height = self:GetSize();
	if (width < 200) then
		width = 200;
	end
	if (height < 140) then
		height = 140;
	end
	
	local titleWidth = math.min(self.titleWidth, width - 96);
	local spacer = (width - titleWidth) / 2;
	self.titleLeft:SetPosition(spacer, -4);
	self.titleLeft:SetHeight(34);
	self.titleMid:SetPosition(spacer + 35, -4);
	self.titleMid:SetWidth(titleWidth - 70);
	self.titleMid:SetHeight(34);
	self.titleRight:SetPosition(width - spacer - 35, -4);
	self.titleRight:SetHeight(34);
	self.title:SetPosition(spacer + 18, 4);
	self.title:SetWidth(titleWidth - 76);
	self.title:SetHeight(26);
	self.titleUnderline:SetPosition(self.title:GetLeft(), self.title:GetTop() + self.title:GetHeight() - 2);
	self.titleUnderline:SetWidth(math.max(0,self.title:GetWidth()));

	local offset = 20;
	self.close:SetPosition(width - 23, offset + 6);
	self.topLeft:SetPosition(0, offset);
	self.top:SetPosition(36, offset);
	self.topRight:SetPosition(width - 36, offset);
	self.bottomLeft:SetPosition(0, height - 36);
	self.bottom:SetPosition(36, height - 36);
	self.bottomRight:SetPosition(width - 36, height - 36);
	self.left:SetPosition(0, 36 + offset);
	self.right:SetPosition(width - 36, 36 + offset);
	self.center:SetPosition(36, 36 + offset);
	
	self.top:SetWidth(width - 72);
	self.bottom:SetWidth(width - 72);
	self.left:SetHeight(height - 72 - offset);
	self.right:SetHeight(height - 72 - offset);
	self.center:SetSize(width - 72, height - 72 - offset)
end

function Window:SaveState()
	-- does nothing (override in subclass if desired)
	
end