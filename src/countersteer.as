void UpdateCountersteerState()
{
    auto vis = GetControlledVehicleState();
    g_CountersteerState.vehicle.visAvailable = vis !is null;
    g_CountersteerState.vehicle.isPlaying = g_CountersteerState.vehicle.visAvailable;
    SyncLegacyState();

    if (!g_CountersteerState.vehicle.visAvailable) {
        ResetTracking();
        return;
    }

    g_CountersteerState.vehicle.inputSteer = vis.InputSteer;
    g_CountersteerState.vehicle.groundDist = vis.GroundDist;
    g_CountersteerState.vehicle.speedKmh = vis.WorldVel.Length() * 3.6f;
    g_CountersteerState.vehicle.horizontalSpeedKmh = ProjectOntoPlane(vis.WorldVel, WorldUp()).Length() * 3.6f;
    SyncLegacyState();

    if (!IsUsableYawState(vis)) {
        ResetYawTracking();
        ResetAirborneSteerDirection();
        g_CountersteerState.vehicle.isAirborne = false;
        g_CountersteerState.vehicle.recommendedSteer = 0;
        SyncLegacyState();
        return;
    }

    g_CountersteerState.vehicle.isAirborne = !vis.IsGroundContact && vis.GroundDist >= S_MinAirHeight;
    if (!g_CountersteerState.vehicle.isAirborne) {
        g_CountersteerState.vehicle.recommendedSteer = 0;
        ResetAirborneSteerDirection();
        ResetYawTracking();
        return;
    }

    uint now = Time::Now;
    UpdateYawEstimate(vis, now);
    UpdateAirborneSteerDirection();
    SyncLegacyState();
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
    if (!g_CountersteerState.yawSample.hasSample) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        return;
    }

    if (discontinuityCount != g_CountersteerState.yawSample.lastDiscontinuityCount) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        SyncLegacyState();
        return;
    }

    float dt = float(now - g_CountersteerState.yawSample.lastSampleTimeMs) * 0.001f;
    if (dt <= 0.0001f) {
        SyncLegacyState();
        return;
    }

    if (dt > 0.25f || IsTeleportLikeMove(vis.Position)) {
        StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
        ClearYawValues();
        SyncLegacyState();
        return;
    }

    float yawDelta = YawDeltaFromBodyRotation(currentDir, currentLeft, currentUp, yawAxis);
    float rawYawRate = yawDelta / Math::Max(dt, MIN_RATE_DT) * RAD_TO_DEG;
    if (S_InvertDetectedDirection) {
        rawYawRate *= -1.0f;
        yawDelta *= -1.0f;
    }

    float smoothing = Math::Clamp(S_Smoothing, 0.0f, 0.95f);
    g_CountersteerState.yawRates.rawDegPerSecond = rawYawRate;
    g_CountersteerState.yawRates.filteredDegPerSecond = Math::Lerp(rawYawRate, g_CountersteerState.yawRates.filteredDegPerSecond, smoothing);
    g_CountersteerState.yawRates.lastYawDeltaDeg = yawDelta * RAD_TO_DEG;

    StoreYawSample(currentDir, currentLeft, currentUp, vis.Position, discontinuityCount, now);
    SyncLegacyState();
}

float YawDeltaFromBodyRotation(const vec3 &in currentDir, const vec3 &in currentLeft, const vec3 &in currentUp, const vec3 &in yawAxis)
{
    if (VecLenSq(yawAxis) <= 0.000001f) {
        return 0.0f;
    }

    vec3 angularDelta =
        (Math::Cross(g_CountersteerState.yawSample.lastDirection, currentDir)
        + Math::Cross(g_CountersteerState.yawSample.lastLeft, currentLeft)
        + Math::Cross(g_CountersteerState.yawSample.lastUp, currentUp)) * 0.5f;
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
    return VecLenSq(currentPosition - g_CountersteerState.yawSample.lastPosition) > 2500.0f;
}

void StoreYawSample(const vec3 &in currentDir, const vec3 &in currentLeft, const vec3 &in currentUp, const vec3 &in currentPosition, uint discontinuityCount, uint now)
{
    g_CountersteerState.yawSample.hasSample = true;
    g_CountersteerState.yawSample.lastDiscontinuityCount = discontinuityCount;
    g_CountersteerState.yawSample.lastDirection = currentDir;
    g_CountersteerState.yawSample.lastLeft = currentLeft;
    g_CountersteerState.yawSample.lastUp = currentUp;
    g_CountersteerState.yawSample.lastPosition = currentPosition;
    g_CountersteerState.yawSample.lastSampleTimeMs = now;
}

void UpdateAirborneSteerDirection()
{
    if (!g_CountersteerState.airborneLock.isLocked) {
        int candidate = BarDirectionFromYawSignal(g_CountersteerState.yawRates.rawDegPerSecond);
        if (candidate == 0) {
            g_CountersteerState.vehicle.recommendedSteer = 0;
            SyncLegacyState();
            return;
        }

        g_CountersteerState.airborneLock.direction = candidate;
        g_CountersteerState.airborneLock.isLocked = true;
    }

    g_CountersteerState.vehicle.recommendedSteer = g_CountersteerState.airborneLock.direction;
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
