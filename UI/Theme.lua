local Theme = {}

Theme.Colors = {
  background = Turbine.UI.Color(0.82, 0.14, 0.16, 0.24),
  surface = Turbine.UI.Color(0.78, 0.12, 0.14, 0.2),
  surfaceHighlight = Turbine.UI.Color(0.65, 0.22, 0.28, 0.36),
  surfaceMuted = Turbine.UI.Color(0.55, 0.12, 0.15, 0.26),
  border = Turbine.UI.Color(0.88, 0.42, 0.5, 0.62),
  borderSoft = Turbine.UI.Color(0.5, 0.24, 0.32, 0.44),
  accent = Turbine.UI.Color(1, 0.46, 0.66, 0.98),
  accentMuted = Turbine.UI.Color(0.92, 0.36, 0.54, 0.9),
  accentHover = Turbine.UI.Color(1, 0.54, 0.72, 0.98),
  accentActive = Turbine.UI.Color(1, 0.62, 0.78, 0.98),
  textPrimary = Turbine.UI.Color(1, 0.98, 0.98, 0.95),
  textSecondary = Turbine.UI.Color(1, 0.92, 0.9, 0.86),
  textMuted = Turbine.UI.Color(0.92, 0.74, 0.72, 0.82),
  controlOutline = Turbine.UI.Color(0.5, 0, 0, 0),
  overlay = Turbine.UI.Color(0.28, 0.12, 0.2, 0.32),
  shadow = Turbine.UI.Color(0.25, 0, 0, 0)
}

Theme.Fonts = {
  title = Turbine.UI.Lotro.Font.TrajanPro18,
  heading = Turbine.UI.Lotro.Font.TrajanPro16,
  body = Turbine.UI.Lotro.Font.TrajanPro14,
  small = Turbine.UI.Lotro.Font.TrajanPro13
}

function Theme.ApplySurfaceBackground(control)
  control:SetBackColor(Theme.Colors.surface)
  control:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay)
end

function Theme.ApplyRaisedSurface(control)
  control:SetBackColor(Theme.Colors.surfaceHighlight)
  control:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay)
end

function Theme.ApplyInsetSurface(control)
  control:SetBackColor(Theme.Colors.surfaceMuted)
  control:SetBackColorBlendMode(Turbine.UI.BlendMode.Overlay)
end

function Theme.ApplyBorder(control, soft)
  control:SetBackColor(soft and Theme.Colors.borderSoft or Theme.Colors.border)
end

function Theme.SetLabelColor(label, muted)
  label:SetForeColor(muted and Theme.Colors.textSecondary or Theme.Colors.textPrimary)
  label:SetOutlineColor(Theme.Colors.controlOutline)
end

function Theme.SetAccentLabel(label, state)
  if state == "hover" then
    label:SetForeColor(Theme.Colors.accentHover)
  elseif state == "active" then
    label:SetForeColor(Theme.Colors.accentActive)
  else
    label:SetForeColor(Theme.Colors.accent)
  end
  label:SetOutlineColor(Theme.Colors.controlOutline)
end

_G.Theme = Theme

return Theme
