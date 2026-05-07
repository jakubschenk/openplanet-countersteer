class YawSampleState
{
    bool hasSample = false;
    uint lastSampleTimeMs = 0;
    uint lastDiscontinuityCount = 0;
    vec3 lastDirection = vec3();
    vec3 lastLeft = vec3();
    vec3 lastUp = vec3();
    vec3 lastPosition = vec3();

    void Reset()
    {
        hasSample = false;
        lastSampleTimeMs = 0;
        lastDiscontinuityCount = 0;
        lastDirection = vec3();
        lastLeft = vec3();
        lastUp = vec3();
        lastPosition = vec3();
    }
}

class YawRateState
{
    float filteredDegPerSecond = 0.0f;
    float rawDegPerSecond = 0.0f;
    float lastYawDeltaDeg = 0.0f;

    void Clear()
    {
        filteredDegPerSecond = 0.0f;
        rawDegPerSecond = 0.0f;
        lastYawDeltaDeg = 0.0f;
    }
}

class AirborneDirectionLockState
{
    int direction = 0;
    bool isLocked = false;

    void Reset()
    {
        direction = 0;
        isLocked = false;
    }
}

class VehicleRuntimeState
{
    bool isPlaying = false;
    bool isAirborne = false;
    bool visAvailable = false;
    float inputSteer = 0.0f;
    float groundDist = 0.0f;
    float speedKmh = 0.0f;
    float horizontalSpeedKmh = 0.0f;
    int recommendedSteer = 0;
}

class CountersteerTrackingState
{
    VehicleRuntimeState vehicle;
    YawSampleState yawSample;
    YawRateState yawRates;
    AirborneDirectionLockState airborneLock;

    void ResetTracking()
    {
        vehicle.isPlaying = false;
        vehicle.visAvailable = false;
        vehicle.isAirborne = false;
        vehicle.recommendedSteer = 0;
        vehicle.inputSteer = 0.0f;
        vehicle.groundDist = 0.0f;
        vehicle.speedKmh = 0.0f;
        vehicle.horizontalSpeedKmh = 0.0f;
        ResetAirborneDirectionLock();
        ResetYawTracking();
    }

    void ResetYawTracking()
    {
        yawSample.Reset();
        yawRates.Clear();
        vehicle.recommendedSteer = 0;
    }

    void ResetAirborneDirectionLock()
    {
        airborneLock.Reset();
    }
}

CountersteerTrackingState g_CountersteerState;

// Legacy globals are preserved for overlay/render compatibility.
bool g_HasYawSample = false;
bool g_IsPlaying = false;
bool g_IsAirborne = false;
bool g_VisAvailable = false;
uint g_LastSampleTime = 0;
uint g_LastDiscontinuityCount = 0;
vec3 g_LastDir = vec3();
vec3 g_LastLeft = vec3();
vec3 g_LastUp = vec3();
vec3 g_LastPosition = vec3();
float g_YawRateDeg = 0.0f;
float g_RawYawRateDeg = 0.0f;
float g_LastYawDeltaDeg = 0.0f;
float g_InputSteer = 0.0f;
float g_GroundDist = 0.0f;
float g_SpeedKmh = 0.0f;
float g_HorizontalSpeedKmh = 0.0f;
int g_RecommendedSteer = 0;
int g_AirborneSteerDirection = 0;
bool g_HasAirborneSteerDirection = false;

void SyncLegacyState()
{
    g_HasYawSample = g_CountersteerState.yawSample.hasSample;
    g_IsPlaying = g_CountersteerState.vehicle.isPlaying;
    g_IsAirborne = g_CountersteerState.vehicle.isAirborne;
    g_VisAvailable = g_CountersteerState.vehicle.visAvailable;
    g_LastSampleTime = g_CountersteerState.yawSample.lastSampleTimeMs;
    g_LastDiscontinuityCount = g_CountersteerState.yawSample.lastDiscontinuityCount;
    g_LastDir = g_CountersteerState.yawSample.lastDirection;
    g_LastLeft = g_CountersteerState.yawSample.lastLeft;
    g_LastUp = g_CountersteerState.yawSample.lastUp;
    g_LastPosition = g_CountersteerState.yawSample.lastPosition;
    g_YawRateDeg = g_CountersteerState.yawRates.filteredDegPerSecond;
    g_RawYawRateDeg = g_CountersteerState.yawRates.rawDegPerSecond;
    g_LastYawDeltaDeg = g_CountersteerState.yawRates.lastYawDeltaDeg;
    g_InputSteer = g_CountersteerState.vehicle.inputSteer;
    g_GroundDist = g_CountersteerState.vehicle.groundDist;
    g_SpeedKmh = g_CountersteerState.vehicle.speedKmh;
    g_HorizontalSpeedKmh = g_CountersteerState.vehicle.horizontalSpeedKmh;
    g_RecommendedSteer = g_CountersteerState.vehicle.recommendedSteer;
    g_AirborneSteerDirection = g_CountersteerState.airborneLock.direction;
    g_HasAirborneSteerDirection = g_CountersteerState.airborneLock.isLocked;
}

void ResetTracking()
{
    g_CountersteerState.ResetTracking();
    SyncLegacyState();
}

void ResetYawTracking()
{
    g_CountersteerState.ResetYawTracking();
    SyncLegacyState();
}

void ClearYawValues()
{
    g_CountersteerState.yawRates.Clear();
    SyncLegacyState();
}

void ResetAirborneSteerDirection()
{
    g_CountersteerState.ResetAirborneDirectionLock();
    SyncLegacyState();
}
