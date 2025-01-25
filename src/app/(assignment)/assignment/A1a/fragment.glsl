/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision
highp float; //// set default precision of float variables to high precision

varying vec2 vUv;

uniform float uTime;
uniform vec2 uResolution;
uniform mat4 uLightRotationMat;
uniform mat4 larmTransform;
uniform mat4 rarmTransform;
uniform mat4 llegTransform;
uniform mat4 rlegTransform;
uniform mat4 headTransform;

struct Camera {
    vec3 eye;
    vec3 view_dir;
    vec3 up;
    float focal_distance;
    float fov;
};

Camera camera = Camera(vec3(5.0, 1.4, -0.5), normalize(vec3(-3.0, -1.0, -0.0)),
        normalize(vec3(0.0, 1.0, 0.0)), 0.001, 45.0);

// ------------------ SDFs ------------------
float SphereSDF(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

float BoxSDF(vec3 p, vec3 center, vec3 halfSize) {
    vec3 q = abs(p - center) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float PlaneSDF(vec3 p, float height) {
    return p.y - height;
}

float CappedCylinderSDF(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float CapsuleSDF(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// ------------------ OP ------------------
float SDFOpUnion(float sdf1, float sdf2) {
    return min(sdf1, sdf2);
}

float SDFOpIntersect(float sdf1, float sdf2) {
    return max(sdf1, sdf2);
}

float SDFOpSubtract(float sdf1, float sdf2) {
    return max(sdf1, -sdf2);
}

float SDFOpSmoothUnion(float sdf1, float sdf2, float k) {
    float h = clamp(0.5 + 0.5 * (sdf2 - sdf1) / k, 0.0, 1.0);
    return mix(sdf2, sdf1, h) - k * h * (1.0 - h);
}

float SDFOpSmoothSubtraction(float sdf1, float sdf2, float k) {
    float h = clamp(0.5 - 0.5 * (sdf2 + sdf1) / k, 0.0, 1.0);
    return mix(sdf2, -sdf1, h) + k * h * (1.0 - h);
}

float SDFOpSmoothIntersection(float sdf1, float sdf2, float k) {
    float h = clamp(0.5 - 0.5 * (sdf2 - sdf1) / k, 0.0, 1.0);
    return mix(sdf2, sdf1, h) + k * h * (1.0 - h);
}

vec2 SceneUnion(vec2 sdf1, vec2 sdf2) {
    return sdf1.x < sdf2.x ? sdf1 : sdf2;
}

// ------------------ Scene ------------------
struct Material {
    vec3 color;
    float kd;
    float ks;
};
Material materials[] = Material[](Material(vec3(1.0, 0.0, 0.8), 0.6, 2.0),
        Material(vec3(0.2, 1.0, 0.6), 1.0, 0.0),
        Material(vec3(0.9, 0.9, 0.8), 1.0, 0.0),
        Material(vec3(0.2, 0.4, 0.8), 1.0, 3.0),
        Material(vec3(0.5, 0.5, 0.5), 1.0, 0.5));

struct Light {
    vec3 pos;
    vec3 intensity;
};
Light lights[] = Light[](Light(vec3(6.0, 12.0, 6.0), vec3(60)),
        Light(vec3(1.0, 9.0, -10.0), vec3(40)),
        Light(vec3(1.0, 19.0, 10.0), vec3(150, 150, 60)));

vec2 Sphere0(vec3 p) {
    float sphere1 = SphereSDF(p, vec3(0.0, 1.5, 1.5), 0.3);
    return vec2(sphere1, 0.0);
}

vec2 Box0(vec3 p) {
    float box1 = BoxSDF(p, vec3(0.0, 0.0, 1.5), vec3(0.5, 0.3, 0.3));
    return vec2(box1, 1.0);
}

vec2 Ground(vec3 p) {
    float ground = PlaneSDF(p, -1.0);
    return vec2(ground, 2.0);
}

vec2 Shape0(vec3 p) {
    float box = BoxSDF(p, vec3(0.0, 0.8, 1.5), vec3(0.3, 0.3, 0.3));
    float sphere = SphereSDF(p, vec3(0.0, 0.8, 1.5), 0.4);
    float shape = SDFOpSubtract(box, sphere);
    return vec2(shape, 3.0);
}

vec2 Shape1(vec3 p) {
    float body = CapsuleSDF(p, vec3(0.0, 0.3, -0.5), vec3(0.0, 0.9, -0.5), 0.3);
    vec3 larmScale = vec3(1.0, 2.0, 1.0);
    float larm = CappedCylinderSDF((larmTransform * vec4(p, 1.0)).xyz, 0.2, 0.1);
    float rarm = CappedCylinderSDF((rarmTransform * vec4(p, 1.0)).xyz, 0.2, 0.1);
    float lleg = CappedCylinderSDF((llegTransform * vec4(p, 1.0)).xyz, 0.2, 0.1);
    float rleg = CappedCylinderSDF((rlegTransform * vec4(p, 1.0)).xyz, 0.2, 0.1);
    float head =
        SphereSDF((headTransform * vec4(p, 1.0)).xyz, vec3(0.0, 1.4, -0.5), 0.2);

    float guy = SDFOpSmoothUnion(body, larm, 0.1);
    guy = SDFOpSmoothUnion(guy, rarm, 0.1);
    guy = SDFOpSmoothUnion(guy, lleg, 0.1);
    guy = SDFOpSmoothUnion(guy, rleg, 0.1);
    guy = SDFOpSmoothUnion(guy, head, 0.15);
    return vec2(guy, 4.0);
}

vec2 Scene(vec3 p) {
    vec2 res = SceneUnion(Shape0(p), Ground(p));
    res = SceneUnion(res, Box0(p));
    res = SceneUnion(res, Sphere0(p));
    res = SceneUnion(res, Shape1(p));
    return res;
}

// ------------------ Render ------------------

float gamma = 2.2;
vec3 linearToSrgb(vec3 v) {
    return pow(v, vec3(1.0 / gamma));
}

vec3 srgbToLinear(vec3 v) {
    return pow(v, vec3(gamma));
}

vec3 getNormal(vec3 p) {
    float dx = 0.001;
    vec3 diff = vec3(dx, 0.0, 0.0);
    vec3 n = normalize(vec3(Scene(p + diff.xyz).x - Scene(p - diff.xyz).x,
                Scene(p + diff.yxz).x - Scene(p - diff.yxz).x,
                Scene(p + diff.yzx).x - Scene(p - diff.yzx).x));
    return n;
}

// uv: [0, 1]
vec3 getCameraRay(vec2 uv, vec2 samplePos) {
    vec3 focal = camera.eye + camera.focal_distance * normalize(camera.view_dir);
    float height = 2.0 * tan(radians(camera.fov / 2.0)) * camera.focal_distance;
    float width = uResolution.x / uResolution.y * height;
    vec3 right = normalize(cross(camera.view_dir, camera.up));
    vec3 focal_up = -normalize(cross(camera.view_dir, right));
    samplePos = (samplePos - 0.5) * height / uResolution.y;
    vec3 point = focal + (uv.x - 0.5) * width * right +
            (uv.y - 0.5) * height * focal_up + samplePos.x * right +
            samplePos.y * focal_up;
    vec3 ray = normalize(point - camera.eye);
    return ray;
}

vec2 findIntersection(vec3 ray, vec3 eye) {
    int max_iter = 1000;
    float dt = 0.01;

    int iter = 0;
    float t = 0.0;
    while (iter < max_iter) {
        vec3 p = eye + t * ray;
        vec2 s = Scene(p);
        if (abs(s.x) < 0.00001) {
            return vec2(t, s.y);
        }
        t += s.x;
        iter++;
    }
    return vec2(-1.0);
}

float shadowFactor(vec3 p, Light light) {
    vec3 light_dir = (uLightRotationMat * vec4(light.pos, 1.0)).xyz - p;
    float dist = length(light_dir);
    vec3 ray = normalize(light_dir);
    vec2 res = findIntersection(ray, p);
    if (res.x < 0.0 || res.x > dist) {
        return 1.0;
    }
    return 0.0;
}

vec3 shading(vec3 ray, float t, int index, Light light) {
    vec3 p = camera.eye + t * ray;
    vec3 n = getNormal(p);
    ray = -ray;
    vec3 light_dir = (uLightRotationMat * vec4(light.pos, 1.0)).xyz - p;
    vec3 h = normalize(light_dir + ray);
    vec3 intensity = light.intensity / (length(light_dir) * length(light_dir));
    light_dir = normalize(light_dir);

    vec3 color = srgbToLinear(materials[index].color);
    vec3 res = vec3(0.04) * srgbToLinear(vec3(0.5, 0.7, 1.0));
    res += materials[index].kd * intensity * max(0.0, dot(n, light_dir));
    res += materials[index].ks * intensity * pow(max(0.0, dot(n, h)), 16.0);
    return shadowFactor(p + 0.0005 * ray, light) * color * res;
}

float random(float x) {
    float y = fract(sin(x) * 100000.0);
    return y;
}

vec3 toneRemap(vec3 color) {
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    color = (color * (a * color + b)) / (color * (c * color + d) + e);

    return color;
}

void main() {
    vec3 bgColor = srgbToLinear(vec3(0.5, 0.7, 1.0));

    int sampleCnt = 1;
    vec2 samplePos = vec2(random(vUv.x), random(vUv.y));
    vec3 color = vec3(0.0);
    for (int i = 0; i < sampleCnt; i++) {
        vec3 ray = getCameraRay(vUv, samplePos);
        samplePos = vec2(random(10.0 * samplePos.x), random(5.0 * samplePos.y));
        vec2 res = findIntersection(ray, camera.eye);
        if (res.x < 0.0) {
            color += bgColor;
            continue;
        }
        for (int j = 0; j < 3; j++) {
            color += shading(ray, res.x, int(res.y), lights[j]);
        }
    }
    gl_FragColor = vec4(
            clamp(linearToSrgb(toneRemap(color / float(sampleCnt))), 0.0, 1.0), 1.0);
}
