float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1.0 - smoothstep(0.0, normalize(vec2(2.0, 2.0), 0.0).x, distance);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.0), rectangle.y - (rectangle.w / 2.0));
}

vec2 getRectangleHalfSize(vec4 rectangle) {
    return rectangle.zw * 0.5;
}

float ease(float x) {
    return pow(1.0 - x, 3.0);
}

float getBoltCenterOffset(float t, float phase, float amplitude, float frequencyScale) {
    float seed0 = sin(phase * 0.47 + 0.3);
    float seed1 = sin(phase * 1.19 + 1.7);
    float seed2 = sin(phase * 2.63 - 0.9);
    float seed3 = sin(phase * 4.11 + 2.4);

    float warp = t;
    warp += 0.032 * sin(phase * 0.73 + t * ((20.0 + 3.0 * seed0) * frequencyScale));
    warp += 0.017 * sin(phase * 1.87 - t * ((41.0 + 5.2 * seed1) * frequencyScale));
    warp += 0.008 * sin(phase * 3.91 + t * ((81.0 + 8.0 * seed2) * frequencyScale));
    warp = clamp(warp, 0.0, 1.0);

    float envelope = pow(sin(warp * 3.14159265), 0.88);

    float primary = 0.16 * sin(phase * 0.89 + warp * ((31.0 + 2.3 * seed1) * frequencyScale));
    float secondary = 0.13 * sin(phase * 1.97 - warp * ((51.0 + 4.8 * seed2) * frequencyScale));
    float tertiary = 0.08 * sin(phase * 3.77 + warp * ((83.0 + 7.0 * seed3) * frequencyScale));
    float micro = 0.04 * sin(phase * 6.41 - warp * ((119.0 + 11.0 * seed0) * frequencyScale));

    float bendWave = sin((warp + 0.04 * seed2) * (31.4159265 * frequencyScale) + phase * 0.31);
    float pointy = sign(bendWave) * pow(abs(bendWave), 0.42);
    float kink = 0.07 * pointy * (0.45 + 0.55 * abs(seed3));

    return (primary + secondary + tertiary + micro + kink) * envelope * amplitude;
}

float getRectExtentInDirection(vec2 halfSize, vec2 dir) {
    vec2 absDir = abs(dir);
    float denom = max(max(absDir.x / max(halfSize.x, 1e-5), absDir.y / max(halfSize.y, 1e-5)), 1e-5);
    return 1.0 / denom;
}

const vec3 BOLT_COLOR = vec3(1.0);
const vec3 HALO_COLOR = vec3(0.44, 0.36, 1.00);
const float DURATION = 0.35; // 0.22
const float MIN_BOLT_DISTANCE = 2.0;
const float HALO_INTENSITY = 1.0;
const float SHORT_HALO_INTENSITY = 0.5;
const float SHORT_HALO_DURATION = 0.35;
const float BOLT_EDGE_FADE = 0.08;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    vec2 vu = normalize(fragCoord, 1.0);
    vec2 offsetFactor = vec2(-0.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.0), normalize(iCurrentCursor.zw, 0.0));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.0), normalize(iPreviousCursor.zw, 0.0));

    vec2 centerCurrent = getRectangleCenter(currentCursor);
    vec2 centerPrevious = getRectangleCenter(previousCursor);
    vec2 halfCurrent = getRectangleHalfSize(currentCursor);
    vec2 halfPrevious = getRectangleHalfSize(previousCursor);

    float sdfCurrentCursor = getSdfRectangle(
        vu,
        currentCursor.xy - (currentCursor.zw * offsetFactor),
        currentCursor.zw * 0.5
    );

    float elapsed = iTime - iTimeCursorChange;
    float progress = clamp(elapsed / DURATION, 0.0, 1.0);
    float shortProgress = clamp(elapsed / SHORT_HALO_DURATION, 0.0, 1.0);
    vec2 centerDelta = centerCurrent - centerPrevious;
    float centerDistance = length(centerDelta);
    vec2 motionDir = (centerDistance > 1e-5) ? centerDelta / centerDistance : vec2(1.0, 0.0);
    float prevExit = getRectExtentInDirection(halfPrevious, motionDir);
    float curEntry = getRectExtentInDirection(halfCurrent, -motionDir);
    vec2 boltStart = centerPrevious + motionDir * prevExit;
    vec2 boltEnd = centerCurrent - motionDir * curEntry;

    float lineLength = distance(boltEnd, boltStart);
    float travel = 1.0 - ease(progress);
    float phase = dot(centerCurrent + centerPrevious, vec2(61.7, 113.3)) + iTimeCursorChange * 5.0;

    float minTriggerDistance = length(currentCursor.zw) * MIN_BOLT_DISTANCE;
    float moveMask = step(minTriggerDistance, centerDistance);

    vec2 pathDir = (lineLength > 1e-5) ? (boltEnd - boltStart) / lineLength : motionDir;
    vec2 pathNormal = vec2(-pathDir.y, pathDir.x);
    float along = dot(vu - boltStart, pathDir);
    float alongClamped = clamp(along, 0.0, lineLength);
    float tAlong = (lineLength > 1e-5) ? alongClamped / lineLength : 0.0;
    float cursorScale = max(currentCursor.z, currentCursor.w);
    float bendDensity = clamp((lineLength - cursorScale * 1.2) / max(cursorScale * 5.0, 1e-5), 0.0, 1.0);
    float frequencyScale = mix(0.42, 1.0, bendDensity);
    float amplitude = mix(cursorScale * 0.085, max(lineLength * 0.029, cursorScale * 0.19), bendDensity);
    float centerOffset = getBoltCenterOffset(tAlong, phase, amplitude, frequencyScale);
    float dt = 0.02;
    float offsetBefore = getBoltCenterOffset(clamp(tAlong - dt, 0.0, 1.0), phase, amplitude, frequencyScale);
    float offsetAfter = getBoltCenterOffset(clamp(tAlong + dt, 0.0, 1.0), phase, amplitude, frequencyScale);
    float slope = (offsetAfter - offsetBefore) / max((2.0 * dt) * max(lineLength, 1e-5), 1e-5);
    float boltDistance = abs(dot(vu - boltStart, pathNormal) - centerOffset) / sqrt(1.0 + slope * slope);
    float revealEnd = travel * lineLength;
    float cappedAlong = clamp(along, 0.0, revealEnd);
    float cappedBoltDistance = length(vec2(along - cappedAlong, boltDistance));
    float edgeFadeWidth = max(lineLength * BOLT_EDGE_FADE, cursorScale * 0.65);
    float startFade = smoothstep(0.0, edgeFadeWidth, along);
    float endFade = 1.0 - smoothstep(max(revealEnd - edgeFadeWidth, 0.0), revealEnd, along);
    float edgeFade = startFade * endFade;
    float fadeOut = 1.0 - smoothstep(0.42, 0.78, progress);

    float boltThickness = max(min(halfCurrent.x, halfCurrent.y) * 0.4, 0.01);
    float boltHalo = 1.0 - smoothstep(boltThickness * 0.70, boltThickness * 5.50, cappedBoltDistance);
    float boltCore = 1.0 - smoothstep(boltThickness, boltThickness + 0.0035, cappedBoltDistance);
    float boltGlow = 1.0 - smoothstep(boltThickness * 0.65, boltThickness * 2.1, cappedBoltDistance);

    float boltMask = max(boltCore, boltGlow * 0.55);
    boltMask *= fadeOut * moveMask * edgeFade;
    float haloMask = boltHalo * HALO_INTENSITY * fadeOut * moveMask * edgeFade;

    float shortHaloDecay = 1.0 - smoothstep(0.0, 1.0, shortProgress);
    float shortHaloReach = mix(cursorScale * 1.1, cursorScale * 2.8, smoothstep(0.0, 0.70, shortProgress));
    float shortHaloDistance = max(sdfCurrentCursor + cursorScale * 0.10, 0.0);
    float shortOuter = 1.0 - smoothstep(0.0, shortHaloReach, shortHaloDistance);
    float shortInner = 1.0 - smoothstep(0.0, cursorScale * 0.22, shortHaloDistance);
    float shortHaloMask = max(shortOuter - shortInner * 0.35, 0.0);
    shortHaloMask *= shortHaloDecay * SHORT_HALO_INTENSITY;

    vec3 outColor = mix(fragColor.rgb, HALO_COLOR, clamp(max(haloMask, shortHaloMask), 0.0, 1.0));
    outColor = mix(outColor, BOLT_COLOR, clamp(boltMask, 0.0, 1.0));
    float cursorBlend = antialising(sdfCurrentCursor);
    outColor = mix(outColor, BOLT_COLOR, cursorBlend);

    fragColor = vec4(outColor, fragColor.a);
}
