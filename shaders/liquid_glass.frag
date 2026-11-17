#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uLensCenterX;
uniform float uLensWidth;
uniform float uLensHeight;
uniform float uStretch;
uniform float uPress;
uniform float uIsLight;
uniform float uRefraction;
uniform sampler2D uTexture;

out vec4 fragColor;

float sdRoundedBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + vec2(r);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec2 calcLensNormal(vec2 p, vec2 halfSize, float radius) {
  const float eps = 1.5;
  float dx = sdRoundedBox(p + vec2(eps, 0.0), halfSize, radius) -
             sdRoundedBox(p - vec2(eps, 0.0), halfSize, radius);
  float dy = sdRoundedBox(p + vec2(0.0, eps), halfSize, radius) -
             sdRoundedBox(p - vec2(0.0, eps), halfSize, radius);
  vec2 n = vec2(dx, dy);
  float len = length(n);
  return len > 0.0001 ? n / len : vec2(0.0);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 safeSize = max(uSize, vec2(1.0));
  vec2 uv = fragCoord / safeSize;

  // Outer dock capsule SDF
  vec2 dockCenter = safeSize * 0.5;
  vec2 dockHalf = safeSize * 0.5;
  float dockRadius = dockHalf.y;
  float dockDist = sdRoundedBox(fragCoord - dockCenter, dockHalf, dockRadius);

  // Moving lens capsule SDF
  vec2 lensCenter = vec2(uLensCenterX, safeSize.y * 0.5);
  vec2 lensHalf = vec2(uLensWidth * 0.5, uLensHeight * 0.5);
  float lensRadius = min(lensHalf.x, lensHalf.y);
  vec2 pLens = fragCoord - lensCenter;
  float lensDist = sdRoundedBox(pLens, lensHalf, lensRadius);

  // Edge refraction from outer dock rim
  float dockRimMask = smoothstep(-14.0, 0.0, dockDist) * (1.0 - smoothstep(-1.0, 1.0, dockDist));
  vec2 dockNormal = calcLensNormal(fragCoord - dockCenter, dockHalf, dockRadius);

  // Edge refraction from moving liquid lens
  float lensInside = 1.0 - smoothstep(-1.5, 1.5, lensDist);
  float lensRimMask = smoothstep(-12.0, 0.0, lensDist) * lensInside;
  vec2 lensNormal = calcLensNormal(pLens, lensHalf, lensRadius);

  // Combine refraction vectors (subtle & physical)
  float pressBoost = 1.0 + uPress * 0.25 + uStretch * 0.35;
  vec2 offsetPx = (dockNormal * dockRimMask * 0.55 + lensNormal * lensRimMask * 1.15 * pressBoost) * uRefraction;
  vec2 refractedUv = clamp(uv - offsetPx / safeSize, vec2(0.001), vec2(0.999));

  // Subtle chromatic dispersion along the curved glass rim
  float disp = (lensRimMask * 0.65 + dockRimMask * 0.35) * (uRefraction * 0.14);
  vec2 dispUv = (lensNormal + dockNormal * 0.5) * (disp / safeSize);

  float r = texture(uTexture, clamp(refractedUv + dispUv, vec2(0.001), vec2(0.999))).r;
  float g = texture(uTexture, refractedUv).g;
  float b = texture(uTexture, clamp(refractedUv - dispUv, vec2(0.001), vec2(0.999))).b;
  float a = texture(uTexture, refractedUv).a;

  vec3 baseColor = vec3(r, g, b);

  // Specular rim highlight (top-left light source, restrained & crisp)
  vec2 lightDir = normalize(vec2(-0.35, -0.94));
  float dockSpec = pow(max(0.0, dot(dockNormal, lightDir)), 3.0) * dockRimMask;
  float lensSpec = pow(max(0.0, dot(lensNormal, lightDir)), 2.5) * lensRimMask;

  float specIntensity = uIsLight > 0.5 ? 0.22 : 0.14;
  vec3 highlight = vec3(1.0) * (dockSpec * 0.55 + lensSpec * 0.95) * specIntensity;

  // Subtle glass tint inside the moving lens
  float lensTintAlpha = lensInside * (uIsLight > 0.5 ? 0.08 : 0.05);
  vec3 finalColor = mix(baseColor, vec3(1.0), lensTintAlpha) + highlight;

  fragColor = vec4(finalColor, a);
}
