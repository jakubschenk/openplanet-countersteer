void DrawCountersteerOverlay()
{
    vec2 screen = Display::GetSize();
    float maxPanelW = Math::Max(140.0f, screen.x - 24.0f);
    float minPanelW = Math::Min(220.0f, maxPanelW);
    float panelW = ClampSafe(screen.x * S_OverlayWidth, minPanelW, Math::Min(620.0f, maxPanelW));
    float panelH = panelW * (S_ShowDebugValues ? 0.38f : 0.26f);
    panelH = Math::Min(panelH, Math::Max(60.0f, screen.y - 24.0f));
    vec2 pos = vec2(
        ClampSafe(screen.x * S_OverlayX - panelW * 0.5f, 12.0f, screen.x - panelW - 12.0f),
        ClampSafe(screen.y * S_OverlayY - panelH * 0.5f, 12.0f, screen.y - panelH - 12.0f)
    );

    OverlayTheme@ theme = GetOverlayTheme();
    float radius = 8.0f;

    nvg::BeginPath();
    nvg::RoundedRect(pos.x, pos.y, panelW, panelH, radius);
    nvg::FillColor(theme.Background);
    nvg::Fill();
    nvg::StrokeWidth(2.0f);
    nvg::StrokeColor(theme.Border);
    nvg::Stroke();

    string label = GetInstructionLabel();
    float titleSize = Math::Clamp(panelW * 0.105f, 24.0f, 46.0f);
    float subSize = Math::Clamp(panelW * 0.043f, 11.0f, 18.0f);

    nvg::FontSize(titleSize);
    nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
    DrawTextShadow(pos.x, pos.y + panelH * 0.36f, panelW, label, theme.Accent);

    DrawStrengthBar(pos + vec2(panelW * 0.14f, panelH * 0.63f), vec2(panelW * 0.72f, Math::Max(8.0f, panelH * 0.08f)), theme);

    if (S_ShowDebugValues) {
        string debug = "yaw " + Text::Format("%.1f deg/s", g_YawRateDeg)
            + "   raw " + Text::Format("%.1f", g_RawYawRateDeg)
            + "   d " + Text::Format("%.2f", g_LastYawDeltaDeg)
            + "   steer " + Text::Format("%.2f", g_InputSteer)
            + "   air " + Text::Format("%.2f m", g_GroundDist)
            + "   hspd " + Text::Format("%.0f", g_HorizontalSpeedKmh);

        nvg::FontSize(subSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        DrawTextShadow(pos.x, pos.y + panelH * 0.85f, panelW, debug, theme.DebugText);
    }
}

string GetInstructionLabel()
{
    if (!g_IsAirborne) {
        return "";
    }

    int barDirection = GetTextBarDirection();
    if (barDirection == 0) {
        return "";
    }

    int steerDirection = -barDirection;
    return "STEER " + (steerDirection < 0 ? "LEFT" : "RIGHT");
}

int GetTextBarDirection()
{
    if (g_RecommendedSteer != 0) {
        return g_RecommendedSteer;
    }

    int candidate = DirectionFromYawSignal(g_RawYawRateDeg, TEXT_YAW_TOLERANCE_DEG);
    if (candidate == 0) {
        candidate = DirectionFromYawSignal(g_YawRateDeg, TEXT_YAW_TOLERANCE_DEG);
    }
    return candidate;
}

void DrawStrengthBar(const vec2 &in pos, const vec2 &in size, OverlayTheme@ theme)
{
    nvg::BeginPath();
    nvg::RoundedRect(pos.x, pos.y, size.x, size.y, size.y * 0.5f);
    nvg::FillColor(theme.BarTrack);
    nvg::Fill();

    float centerX = pos.x + size.x * 0.5f;
    nvg::BeginPath();
    nvg::Rect(centerX - 1.0f, pos.y - 3.0f, 2.0f, size.y + 6.0f);
    nvg::FillColor(theme.CenterMarker);
    nvg::Fill();

    float denom = Math::Max(S_StrongYawDeg, S_YawThresholdDeg + 1.0f);
    float amount = Math::Clamp(Math::Abs(g_YawRateDeg) / denom, 0.0f, 1.0f);
    if (!g_IsAirborne) {
        amount = 0.0f;
    }

    int direction = g_RecommendedSteer;
    if (direction == 0 && g_IsAirborne && Math::Abs(g_YawRateDeg) > 0.1f) {
        direction = g_YawRateDeg > 0.0f ? -1 : 1;
    }

    float fillW = size.x * 0.5f * amount;
    float fillX = direction < 0 ? centerX - fillW : centerX;
    if (fillW > 0.5f) {
        nvg::BeginPath();
        nvg::RoundedRect(fillX, pos.y, fillW, size.y, size.y * 0.5f);
        nvg::FillColor(WithAlpha(theme.Accent, 0.9f * S_Opacity));
        nvg::Fill();
    }
}

void DrawTextShadow(float x, float y, float w, const string &in text, const vec4 &in color)
{
    nvg::FillColor(vec4(0.0f, 0.0f, 0.0f, Math::Min(1.0f, color.w) * 0.75f));
    nvg::TextBox(x + 2.0f, y + 2.0f, w, text);
    nvg::FillColor(color);
    nvg::TextBox(x, y, w, text);
}
