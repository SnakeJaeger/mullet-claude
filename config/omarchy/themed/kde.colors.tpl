# KDE color scheme generated from the current Omarchy theme.
# ~/.config/omarchy/hooks/theme-set.d/kde-qt-theme.hook merges the [Colors:*]
# sections into ~/.config/kdeglobals (what Dolphin, Kdenlive… read) and links
# this file as ~/.local/share/color-schemes/Omarchy.colors.

[General]
ColorScheme=Omarchy
Name=Omarchy

# Window (Places panel, toolbar) a shade darker than View (the files), like
# Nautilus's sidebar and header bar.
[Colors:Window]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ background_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:View]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ lighter_background_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Button]
BackgroundNormal={{ lighter_background_rgb }}
BackgroundAlternate={{ selection_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Selection]
BackgroundNormal={{ accent_rgb }}
BackgroundAlternate={{ mix_rgb accent background 40% }}
ForegroundNormal={{ background_rgb }}
ForegroundInactive={{ dark_background_rgb }}
ForegroundActive={{ darker_background_rgb }}
ForegroundLink={{ darker_background_rgb }}
ForegroundVisited={{ darker_background_rgb }}
ForegroundNegative={{ darker_background_rgb }}
ForegroundNeutral={{ darker_background_rgb }}
ForegroundPositive={{ darker_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Tooltip]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ background_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Header]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ background_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Complementary]
BackgroundNormal={{ darker_background_rgb }}
BackgroundAlternate={{ dark_background_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[WM]
activeBackground={{ dark_background_rgb }}
activeForeground={{ foreground_rgb }}
inactiveBackground={{ darker_background_rgb }}
inactiveForeground={{ dark_foreground_rgb }}
