
_G.allWindows = {}
_G.idCounter = 1;

_G.windowsLocked = false;
_G.windowsHidden = false;

_G.lageFonts = false;

import "CombatAnalysis.UI.Theme"

local Colors = Theme.Colors;
local Fonts = Theme.Fonts;

-- 14 standard 18 large
_G.statFont = Fonts.body;

-- set some UI default colors based on the shared theme

_G.borderColor = Colors.border;
_G.backgroundColor = Colors.surface;
_G.darkBackgroundColor = Colors.surfaceMuted;

_G.blueBorderColor = Colors.borderSoft;

_G.controlColor = Colors.textPrimary;
_G.control2Color = Colors.accent;
_G.controlSelectedColor = Colors.accentActive;
_G.controlLightColor = Colors.textSecondary;
_G.control2LightColor = Colors.accentHover;
_G.controlYellowColor = Colors.accent;
_G.control2YellowColor = Colors.accentMuted;
_G.controlDisabledColor = Colors.textMuted;

-- imports

import "CombatAnalysis.UI.Cursor"

import "CombatAnalysis.UI.TooltipManager"
import "CombatAnalysis.UI.Tooltip"

import "CombatAnalysis.UI.DragBar"

import "CombatAnalysis.UI.WindowManager"
import "CombatAnalysis.UI.Window"
import "CombatAnalysis.UI.ResizableWindow"

import "CombatAnalysis.UI.DialogManager"
import "CombatAnalysis.UI.Dialog"

import "CombatAnalysis.UI.SuggestionsPopup"
import "CombatAnalysis.UI.SuggestionsTextBox"

import "CombatAnalysis.UI.NotificationIcon"

import "CombatAnalysis.UI.Tab"
import "CombatAnalysis.UI.TabbedPane"

import "CombatAnalysis.UI.MenuLabel"
import "CombatAnalysis.UI.MenuCheckBox"
import "CombatAnalysis.UI.PanelDivider"
import "CombatAnalysis.UI.LabelledComboBox"
import "CombatAnalysis.UI.ColoredLabelledComboBox"
import "CombatAnalysis.UI.Slider"
import "CombatAnalysis.UI.ColorPicker"

import "CombatAnalysis.UI.FileSelectDialog"

import "CombatAnalysis.UI.CombatAnalysisSpecific"
