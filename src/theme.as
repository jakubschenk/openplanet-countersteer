class OverlayTheme
{
    vec4 Accent;
    vec4 Background;
    vec4 Border;
    vec4 BarTrack;
    vec4 CenterMarker;
    vec4 DebugText;
}

OverlayTheme@ GetOverlayTheme()
{
    OverlayTheme@ theme = OverlayTheme();
    bool hasDirection = g_IsAirborne && GetTextBarDirection() != 0;
    theme.Accent = WithAlpha(hasDirection ? S_ThemeActiveAccent : S_ThemeNeutralAccent, 1.0f);
    theme.Background = WithAlpha(S_ThemePanelBg, S_Opacity);
    theme.Border = WithAlpha(theme.Accent, Math::Min(1.0f, S_Opacity + 0.15f));
    theme.BarTrack = WithAlpha(S_ThemeBarTrack, S_ThemeBarTrack.w * S_Opacity);
    theme.CenterMarker = WithAlpha(S_ThemeCenterMarker, S_ThemeCenterMarker.w * S_Opacity);
    theme.DebugText = WithAlpha(S_ThemeDebugText, S_ThemeDebugText.w * S_Opacity);
    return theme;
}

vec4 WithAlpha(const vec4 &in color, float alpha)
{
    return vec4(color.x, color.y, color.z, Math::Clamp(alpha, 0.0f, 1.0f));
}
