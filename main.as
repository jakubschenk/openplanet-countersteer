void Main()
{
    while (true) {
        yield();
        UpdateCountersteerState();
    }
}

void RenderMenu()
{
    if (!S_ShowMenuToggle) {
        return;
    }

    if (UI::MenuItem("Countersteer Advisor", "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void Render()
{
    if (!S_Enabled || !g_IsPlaying || !g_VisAvailable) {
        return;
    }

    if (!g_IsAirborne || (g_RecommendedSteer == 0 && !S_ShowWhenStable)) {
        return;
    }

    DrawCountersteerOverlay();
}
