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
        ResetAirborneSteerDirection();
        g_IsAirborne = false;
        g_RecommendedSteer = 0;
        return;
    }

    g_IsAirborne = !vis.IsGroundContact && vis.GroundDist >= S_MinAirHeight;
    if (!g_IsAirborne) {
        g_RecommendedSteer = 0;
        ResetAirborneSteerDirection();
        ResetYawTracking();
        return;
    }

    uint now = Time::Now;
    UpdateYawEstimate(vis, now);
    UpdateAirborneSteerDirection();
}

void UpdateYawEstimate(CSceneVehicleVisState@ vis, uint now)
{
    vec3 currentDir = NormalizeOrZero(vis.Dir);
    vec3 currentLeft = NormalizeOrZero(vis.Left);
    vec3 currentUp = NormalizeOrZero(vis.Up);
    vec3 yawAxis = NormalizeOrZero(vis.WorldCarUp);
    if (VecLenSq(yawAxis) <= 0.000001f) {
        yawAxis = currentUp;
    }

    uint discontinuityCount = uint(vis.DiscontinuityCount);
    if (!g_HasYawSample) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        return;
    }

    if (discontinuityCount != g_LastDiscontinuityCount) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        return;
    }

    float dt = float(now - g_LastSampleTime) * 0.001f;
    if (dt <= 0.0001f) {
        return;
    }

    if (dt > 0.25f || IsTeleportLikeMove(vis.Position)) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        return;
    }

    float yawDelta = YawDeltaFromBodyRotation(currentDir, currentLeft, currentUp, yawAxis);
    float rawYawRate = yawDelta / Math::Max(dt, MIN_RATE_DT) * RAD_TO_DEG;
    if (S_InvertDetectedDirection) {
        rawYawRate *= -1.0f;
        yawDelta *= -1.0f;
    }

    float smoothing = Math::Clamp(S_Smoothing, 0.0f, 0.95f);
    g_RawYawRateDeg = rawYawRate;
    g_YawRateDeg = Math::Lerp(rawYawRate, g_YawRateDeg, smoothing);
    g_LastYawDeltaDeg = yawDelta * RAD_TO_DEG;

    StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
}

float YawDeltaFromBodyRotation(const vec3 &in currentDir, const vec3 &in currentLeft, const vec3 &in currentUp, const vec3 &in yawAxis)
{
    if (VecLenSq(yawAxis) <= 0.000001f) {
        return 0.0f;
    }

    vec3 angularDelta =
        (Math::Cross(g_LastDir, currentDir)
        + Math::Cross(g_LastLeft, currentLeft)
        + Math::Cross(g_LastUp, currentUp)) * 0.5f;
    return Math::Dot(angularDelta, yawAxis);
}

bool IsUsableYawState(CSceneVehicleVisState@ vis)
{
    if (VecLenSq(vis.Dir) <= 0.000001f
        || VecLenSq(vis.Left) <= 0.000001f
        || VecLenSq(vis.Up) <= 0.000001f) {
        return false;
    }

    return VecLenSq(vis.WorldCarUp) > 0.000001f || VecLenSq(vis.Up) > 0.000001f;
}

bool IsTeleportLikeMove(const vec3 &in currentPosition)
{
    return VecLenSq(currentPosition - g_LastPosition) > 2500.0f;
}

void StoreYawSample(const vec3 &in currentDir, const vec3 &in currentLeft, const vec3 &in currentUp, const vec3 &in currentPosition, uint discontinuityCount, uint now)
{
    g_HasYawSample = true;
    g_LastDiscontinuityCount = discontinuityCount;
    g_LastDir = currentDir;
    g_LastLeft = currentLeft;
    g_LastUp = currentUp;
    g_LastPosition = currentPosition;
    g_LastSampleTime = now;
}

void UpdateAirborneSteerDirection()
{
    if (!g_HasAirborneSteerDirection) {
        int candidate = BarDirectionFromYawSignal(g_RawYawRateDeg);
        if (candidate == 0) {
            g_RecommendedSteer = 0;
            return;
        }

        g_AirborneSteerDirection = candidate;
        g_HasAirborneSteerDirection = true;
    }

    g_RecommendedSteer = g_AirborneSteerDirection;
}

int BarDirectionFromYawSignal(float yawSignal)
{
    return DirectionFromYawSignal(yawSignal, Math::Max(S_YawThresholdDeg, 0.0f));
}

int DirectionFromYawSignal(float yawSignal, float tolerance)
{
    if (yawSignal == 0.0f || Math::Abs(yawSignal) < tolerance) {
        return 0;
    }

    return yawSignal > 0.0f ? -1 : 1;
}
