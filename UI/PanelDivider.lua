
_G.PanelDivider = class(Turbine.UI.Label);

function PanelDivider:Constructor(text,parent)
    Turbine.UI.Label.Constructor(self);
  
    self:SetFont(Theme.Fonts.heading);
    self:SetForeColor(Theme.Colors.textPrimary);
    self:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
    self:SetFontStyle(Turbine.UI.FontStyle.None);
    self:SetOutlineColor(Theme.Colors.controlOutline);
    self:SetBackColor(Turbine.UI.Color(0,0,0,0));
    self:SetSize(400,30);
    self:SetMouseVisible(false);
    
    self:SetText(text);
    self:SetParent(parent);

    self.line = Turbine.UI.Control();
    self.line:SetParent(self);
    self.line:SetMouseVisible(false);
    self.line:SetBackColor(Theme.Colors.accentMuted);
    self.line:SetHeight(2);
    self.line:SetLeft(0);
    self.line:SetTop(self:GetHeight()-4);
    self.line:SetWidth(self:GetWidth());

    self.glow = Turbine.UI.Control();
    self.glow:SetParent(self);
    self.glow:SetMouseVisible(false);
    self.glow:SetBackColor(Theme.Colors.overlay);
    self.glow:SetHeight(4);
    self.glow:SetLeft(0);
    self.glow:SetTop(self:GetHeight()-6);
    self.glow:SetWidth(self:GetWidth());

    self.SizeChanged = function()
        local w,h = self:GetSize();
        self.line:SetWidth(w);
        self.line:SetTop(h-3);
        self.glow:SetWidth(w);
        self.glow:SetTop(h-6);
    end
    self:SizeChanged();
end
