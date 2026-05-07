const float PI = 3.14159265359f;
const float TAU = 6.28318530718f;
const float RAD_TO_DEG = 57.2957795131f;

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show menu toggle"]
bool S_ShowMenuToggle = true;

[Setting category="Detection" name="Minimum air height" min=0.0 max=5.0]
float S_MinAirHeight = 0.03f;

[Setting category="Detection" name="Yaw threshold (deg/s)" min=1.0 max=180.0]
float S_YawThresholdDeg = 4.0f;

[Setting category="Detection" name="Strong yaw (deg/s)" min=5.0 max=360.0]
float S_StrongYawDeg = 55.0f;

[Setting category="Detection" name="Duplicate sample timeout (ms)" min=20 max=250]
uint S_DuplicateSampleTimeoutMs = 90;

[Setting category="Detection" name="Smoothing" min=0.0 max=0.95]
float S_Smoothing = 0.2f;

[Setting category="Detection" name="Invert detected direction"]
bool S_InvertDetectedDirection = false;

[Setting category="Display" name="Show when stable"]
bool S_ShowWhenStable = true;

[Setting category="Display" name="Show debug values"]
bool S_ShowDebugValues = false;

[Setting category="Display" name="Text yaw tolerance (deg/s)" min=0.0 max=5.0]
float S_TextYawToleranceDeg = 0.05f;

[Setting category="Display" name="Overlay X" min=0.0 max=1.0]
float S_OverlayX = 0.5f;

[Setting category="Display" name="Overlay Y" min=0.0 max=1.0]
float S_OverlayY = 0.72f;

[Setting category="Display" name="Overlay width" min=0.12 max=0.8]
float S_OverlayWidth = 0.28f;

[Setting category="Display" name="Opacity" min=0.1 max=1.0]
float S_Opacity = 0.78f;

bool g_HasYawSample = false;
bool g_IsPlaying = false;
bool g_IsAirborne = false;
bool g_VisAvailable = false;
uint g_LastSampleTime = 0;
uint g_LastChangedSampleTime = 0;
vec3 g_LastDir = vec3();
vec3 g_LastLeft = vec3();
vec3 g_LastPosition = vec3();
float g_YawRateDeg = 0.0f;
float g_RawYawRateDeg = 0.0f;
float g_LastYawDeltaDeg = 0.0f;
float g_InputSteer = 0.0f;
float g_GroundDist = 0.0f;
float g_SpeedKmh = 0.0f;
float g_HorizontalSpeedKmh = 0.0f;
int g_RecommendedSteer = 0;
int g_DisplayBarDirection = 0;
bool g_HasAirborneDirectionLock = false;

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

    if (!g_IsAirborne || (GetTextBarDirection() == 0 && !S_ShowWhenStable)) {
        return;
    }

    DrawCountersteerOverlay();
}

void UpdateCountersteerState()
{
    auto vis = GetControlledVehicleState();
    g_VisAvailable = vis !is null;
    g_IsPlaying = g_VisAvailable;

    if (!g_VisAvailable) {
        ResetTracking();
        return;
    }

    g_InputSteer = vis.InputSteer;
    g_GroundDist = vis.GroundDist;
    g_SpeedKmh = vis.WorldVel.Length() * 3.6f;
    g_HorizontalSpeedKmh = ProjectOntoPlane(vis.WorldVel, WorldUp()).Length() * 3.6f;

    if (!IsUsableYawState(vis)) {
        ResetYawTracking();
        ResetDisplayDirection();
        g_IsAirborne = false;
        g_RecommendedSteer = 0;
        return;
    }

    uint now = Time::Now;
    UpdateYawEstimate(vis, now);

    g_IsAirborne = !vis.IsGroundContact && vis.GroundDist >= S_MinAirHeight;
    if (!g_IsAirborne) {
        g_RecommendedSteer = 0;
        ResetDisplayDirection();
        return;
    }

    UpdateAirborneDirectionLock();
}

CSceneVehicleVisState@ GetControlledVehicleState()
{
    auto app = cast<CTrackMania>(GetApp());
    if (app is null || app.GameScene is null || app.CurrentPlayground is null) {
        return null;
    }

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground is null || playground.GameTerminals.Length == 0) {
        return null;
    }

    auto terminal = playground.GameTerminals[0];
    if (terminal is null || terminal.UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) {
        return null;
    }

    auto player = cast<CSmPlayer>(terminal.ControlledPlayer);
    if (player is null) {
        return null;
    }

    CSceneVehicleVis@ vis = VehicleState::GetVis(app.GameScene, player);
    if (vis is null || vis.AsyncState is null) {
        return null;
    }

    return vis.AsyncState;
}

void UpdateYawEstimate(CSceneVehicleVisState@ vis, uint now)
{
    vec3 currentDir = NormalizeOrZero(vis.Dir);
    vec3 currentLeft = NormalizeOrZero(vis.Left);

    if (!g_HasYawSample) {
        StoreYawSample(currentDir, currentLeft, vis.Position, now);
        ClearYawValues();
        return;
    }

    float dt = float(now - g_LastSampleTime) * 0.001f;
    if (dt <= 0.0001f) {
        return;
    }

    if (dt > 0.25f || IsTeleportLikeMove(vis.Position)) {
        StoreYawSample(currentDir, currentLeft, vis.Position, now);
        ClearYawValues();
        return;
    }

    if (!OrientationChanged(currentDir, currentLeft)) {
        if (now - g_LastChangedSampleTime >= S_DuplicateSampleTimeoutMs) {
            ClearYawValues();
        }
        return;
    }

    float yawDelta = YawDeltaFromBasis(currentDir, currentLeft);
    float rawYawRate = yawDelta / dt * RAD_TO_DEG;
    if (S_InvertDetectedDirection) {
        rawYawRate *= -1.0f;
        yawDelta *= -1.0f;
    }

    float smoothing = Math::Clamp(S_Smoothing, 0.0f, 0.95f);
    g_RawYawRateDeg = rawYawRate;
    g_YawRateDeg = Math::Lerp(rawYawRate, g_YawRateDeg, smoothing);
    g_LastYawDeltaDeg = yawDelta * RAD_TO_DEG;

    StoreYawSample(currentDir, currentLeft, vis.Position, now);
    g_LastChangedSampleTime = now;
}

float YawDeltaFromBasis(const vec3 &in currentDir, const vec3 &in currentLeft)
{
    vec3 worldUp = WorldUp();
    float weightedDelta = 0.0f;
    float weightSum = 0.0f;

    float dirWeight = YawProjectionWeight(g_LastDir, currentDir, worldUp);
    if (dirWeight > 0.0f) {
        weightedDelta += ProjectedYawDelta(g_LastDir, currentDir, worldUp) * dirWeight;
        weightSum += dirWeight;
    }

    float leftWeight = YawProjectionWeight(g_LastLeft, currentLeft, worldUp);
    if (leftWeight > 0.0f) {
        weightedDelta += ProjectedYawDelta(g_LastLeft, currentLeft, worldUp) * leftWeight;
        weightSum += leftWeight;
    }

    if (weightSum <= 0.000001f) {
        return 0.0f;
    }

    return NormalizeAngle(weightedDelta / weightSum);
}

float YawProjectionWeight(const vec3 &in fromVec, const vec3 &in toVec, const vec3 &in axis)
{
    vec3 fromProjected = ProjectOntoPlane(fromVec, axis);
    vec3 toProjected = ProjectOntoPlane(toVec, axis);
    float fromLenSq = VecLenSq(fromProjected);
    float toLenSq = VecLenSq(toProjected);
    if (fromLenSq <= 0.000001f || toLenSq <= 0.000001f) {
        return 0.0f;
    }

    return Math::Sqrt(Math::Min(fromLenSq, toLenSq));
}

float ProjectedYawDelta(const vec3 &in fromVec, const vec3 &in toVec, const vec3 &in axis)
{
    return SignedAngleFromProjected(ProjectOntoPlane(fromVec, axis), ProjectOntoPlane(toVec, axis), axis);
}

float SignedAngleFromProjected(const vec3 &in fromProjected, const vec3 &in toProjected, const vec3 &in axis)
{
    vec3 fromNorm = NormalizeOrZero(fromProjected);
    vec3 toNorm = NormalizeOrZero(toProjected);
    float sinAngle = Math::Dot(axis, Math::Cross(fromNorm, toNorm));
    float cosAngle = Math::Clamp(Math::Dot(fromNorm, toNorm), -1.0f, 1.0f);
    return Math::Atan2(sinAngle, cosAngle);
}

bool IsUsableYawState(CSceneVehicleVisState@ vis)
{
    if (VecLenSq(vis.Dir) <= 0.000001f || VecLenSq(vis.Left) <= 0.000001f) {
        return false;
    }

    vec3 worldUp = WorldUp();
    return VecLenSq(ProjectOntoPlane(vis.Dir, worldUp)) > 0.000001f
        || VecLenSq(ProjectOntoPlane(vis.Left, worldUp)) > 0.000001f;
}

bool OrientationChanged(const vec3 &in currentDir, const vec3 &in currentLeft)
{
    float basisDelta = VecLenSq(currentDir - g_LastDir) + VecLenSq(currentLeft - g_LastLeft);
    return basisDelta > 0.0000000001f;
}

bool IsTeleportLikeMove(const vec3 &in currentPosition)
{
    return VecLenSq(currentPosition - g_LastPosition) > 2500.0f;
}

void StoreYawSample(const vec3 &in currentDir, const vec3 &in currentLeft, const vec3 &in currentPosition, uint now)
{
    g_HasYawSample = true;
    g_LastDir = currentDir;
    g_LastLeft = currentLeft;
    g_LastPosition = currentPosition;
    g_LastSampleTime = now;
    if (g_LastChangedSampleTime == 0) {
        g_LastChangedSampleTime = now;
    }
}

void ResetTracking()
{
    g_IsPlaying = false;
    g_VisAvailable = false;
    g_IsAirborne = false;
    g_RecommendedSteer = 0;
    g_InputSteer = 0.0f;
    g_GroundDist = 0.0f;
    g_SpeedKmh = 0.0f;
    g_HorizontalSpeedKmh = 0.0f;
    ResetDisplayDirection();
    ResetYawTracking();
}

void ResetYawTracking()
{
    g_HasYawSample = false;
    g_LastSampleTime = 0;
    g_LastChangedSampleTime = 0;
    g_LastDir = vec3();
    g_LastLeft = vec3();
    g_LastPosition = vec3();
    ClearYawValues();
}

void ClearYawValues()
{
    g_YawRateDeg = 0.0f;
    g_RawYawRateDeg = 0.0f;
    g_LastYawDeltaDeg = 0.0f;
}

void ResetDisplayDirection()
{
    g_DisplayBarDirection = 0;
    g_HasAirborneDirectionLock = false;
    g_RecommendedSteer = 0;
}

void UpdateAirborneDirectionLock()
{
    if (!g_HasAirborneDirectionLock) {
        int candidate = CandidateTextBarDirection();
        if (candidate == 0) {
            g_RecommendedSteer = 0;
            return;
        }
        g_DisplayBarDirection = candidate;
        g_HasAirborneDirectionLock = true;
    }

    g_RecommendedSteer = g_DisplayBarDirection;
}

vec3 WorldUp()
{
    return vec3(0.0f, 1.0f, 0.0f);
}

vec3 ProjectOntoPlane(const vec3 &in v, const vec3 &in normal)
{
    return v - normal * Math::Dot(v, normal);
}

float NormalizeAngle(float angle)
{
    while (angle > PI) {
        angle -= TAU;
    }
    while (angle < -PI) {
        angle += TAU;
    }
    return angle;
}

vec3 NormalizeOrZero(const vec3 &in v)
{
    float lenSq = VecLenSq(v);
    if (lenSq <= 0.000001f) {
        return vec3();
    }
    float invLen = 1.0f / Math::Sqrt(lenSq);
    return vec3(v.x * invLen, v.y * invLen, v.z * invLen);
}

float VecLenSq(const vec3 &in v)
{
    return v.x * v.x + v.y * v.y + v.z * v.z;
}

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

    vec4 accent = GetAccentColor();
    vec4 bg = vec4(0.02f, 0.025f, 0.03f, S_Opacity);
    vec4 border = vec4(accent.x, accent.y, accent.z, Math::Min(1.0f, S_Opacity + 0.15f));
    float radius = 8.0f;

    nvg::BeginPath();
    nvg::RoundedRect(pos.x, pos.y, panelW, panelH, radius);
    nvg::FillColor(bg);
    nvg::Fill();
    nvg::StrokeWidth(2.0f);
    nvg::StrokeColor(border);
    nvg::Stroke();

    string label = GetInstructionLabel();
    float titleSize = Math::Clamp(panelW * 0.105f, 24.0f, 46.0f);
    float subSize = Math::Clamp(panelW * 0.043f, 11.0f, 18.0f);

    nvg::FontSize(titleSize);
    nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
    DrawTextShadow(pos.x, pos.y + panelH * 0.36f, panelW, label, accent);

    DrawStrengthBar(pos + vec2(panelW * 0.14f, panelH * 0.63f), vec2(panelW * 0.72f, Math::Max(8.0f, panelH * 0.08f)), accent);

    if (S_ShowDebugValues) {
        string debug = "yaw " + Text::Format("%.1f deg/s", g_YawRateDeg)
            + "   raw " + Text::Format("%.1f", g_RawYawRateDeg)
            + "   d " + Text::Format("%.2f", g_LastYawDeltaDeg)
            + "   steer " + Text::Format("%.2f", g_InputSteer)
            + "   air " + Text::Format("%.2f m", g_GroundDist)
            + "   hspd " + Text::Format("%.0f", g_HorizontalSpeedKmh);

        nvg::FontSize(subSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        DrawTextShadow(pos.x, pos.y + panelH * 0.85f, panelW, debug, vec4(0.86f, 0.88f, 0.9f, S_Opacity));
    }
}

vec4 GetAccentColor()
{
    if (!g_IsAirborne || GetTextBarDirection() == 0) {
        return vec4(0.55f, 0.6f, 0.65f, 1.0f);
    }

    return vec4(0.25f, 0.72f, 1.0f, 1.0f);
}

string GetInstructionLabel()
{
    if (!g_IsAirborne) {
        return "CENTER";
    }

    int barDirection = GetTextBarDirection();
    if (barDirection == 0) {
        return "CENTER";
    }

    int steerDirection = -barDirection;
    return "STEER " + (steerDirection < 0 ? "LEFT" : "RIGHT");
}

int GetTextBarDirection()
{
    return g_DisplayBarDirection;
}

int CandidateTextBarDirection()
{
    float tolerance = Math::Max(S_TextYawToleranceDeg, 0.0f);
    if (Math::Abs(g_YawRateDeg) > tolerance) {
        return g_YawRateDeg > 0.0f ? -1 : 1;
    }

    if (Math::Abs(g_RawYawRateDeg) > tolerance) {
        return g_RawYawRateDeg > 0.0f ? -1 : 1;
    }

    return 0;
}

void DrawStrengthBar(const vec2 &in pos, const vec2 &in size, const vec4 &in accent)
{
    nvg::BeginPath();
    nvg::RoundedRect(pos.x, pos.y, size.x, size.y, size.y * 0.5f);
    nvg::FillColor(vec4(1.0f, 1.0f, 1.0f, 0.12f * S_Opacity));
    nvg::Fill();

    float centerX = pos.x + size.x * 0.5f;
    nvg::BeginPath();
    nvg::Rect(centerX - 1.0f, pos.y - 3.0f, 2.0f, size.y + 6.0f);
    nvg::FillColor(vec4(1.0f, 1.0f, 1.0f, 0.28f * S_Opacity));
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
        nvg::FillColor(vec4(accent.x, accent.y, accent.z, 0.9f * S_Opacity));
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

float ClampSafe(float value, float min, float max)
{
    if (max < min) {
        return min;
    }
    return Math::Clamp(value, min, max);
}
