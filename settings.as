const float RAD_TO_DEG = 57.2957795131f;
const float MIN_RATE_DT = 0.01f;
const float TEXT_YAW_TOLERANCE_DEG = 0.0001f;

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show menu toggle"]
bool S_ShowMenuToggle = true;

[Setting category="Detection" name="Minimum air height" min=0.0 max=5.0]
float S_MinAirHeight = 0.03f;

[Setting category="Detection" name="Yaw threshold (deg/s)" min=0.0 max=180.0]
float S_YawThresholdDeg = 4.0f;

[Setting category="Detection" name="Strong yaw (deg/s)" min=5.0 max=360.0]
float S_StrongYawDeg = 55.0f;

[Setting category="Detection" name="Smoothing" min=0.0 max=0.95]
float S_Smoothing = 0.2f;

[Setting category="Detection" name="Invert detected direction"]
bool S_InvertDetectedDirection = false;

[Setting category="Display" name="Show when stable"]
bool S_ShowWhenStable = true;

[Setting category="Display" name="Show debug values"]
bool S_ShowDebugValues = false;

[Setting category="Display" name="Overlay X" min=0.0 max=1.0]
float S_OverlayX = 0.5f;

[Setting category="Display" name="Overlay Y" min=0.0 max=1.0]
float S_OverlayY = 0.72f;

[Setting category="Display" name="Overlay width" min=0.12 max=0.8]
float S_OverlayWidth = 0.28f;

[Setting category="Display" name="Opacity" min=0.1 max=1.0]
float S_Opacity = 0.78f;
