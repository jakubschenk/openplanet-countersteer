vec3 WorldUp()
{
    return vec3(0.0f, 1.0f, 0.0f);
}

vec3 ProjectOntoPlane(const vec3 &in v, const vec3 &in normal)
{
    return v - normal * Math::Dot(v, normal);
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

float ClampSafe(float value, float min, float max)
{
    if (max < min) {
        return min;
    }
    return Math::Clamp(value, min, max);
}
