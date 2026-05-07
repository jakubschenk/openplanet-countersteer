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
    ResetAirborneSteerDirection();
    ResetYawTracking();
}

void ResetYawTracking()
{
    g_HasYawSample = false;
    g_LastSampleTime = 0;
    g_LastDiscontinuityCount = 0;
    g_LastDir = vec3();
    g_LastLeft = vec3();
    g_LastUp = vec3();
    g_LastPosition = vec3();
    ClearYawValues();
    g_RecommendedSteer = 0;
}

void ClearYawValues()
{
    g_YawRateDeg = 0.0f;
    g_RawYawRateDeg = 0.0f;
    g_LastYawDeltaDeg = 0.0f;
}

void ResetAirborneSteerDirection()
{
    g_AirborneSteerDirection = 0;
    g_HasAirborneSteerDirection = false;
}
