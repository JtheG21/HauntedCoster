export const VERSION = 1;
export const defaults = () => ({
  version: VERSION,
  model: null,
  camera: null,
  target: null,
  lighting: "studio",
  background: "#111923",
  exposure: 1,
  grid: true,
  wireframe: false,
  turntable: false,
  effect: "none",
  effectColor: "#67e8ce",
  effectIntensity: 1,
  mappings: { Idle: "", Move: "", Ability: "" },
  clip: "",
  time: 0,
  speed: 1,
  loop: true,
});
const fail = (message) => {
  throw new Error(`Invalid scene: ${message}`);
};
const number = (v, min, max) =>
  typeof v === "number" && Number.isFinite(v) && v >= min && v <= max;
export function safeModelPath(value) {
  return (
    typeof value === "string" &&
    /^library\/[a-zA-Z0-9_-]+\/model\.glb$/.test(value)
  );
}
export function validateScene(input) {
  if (
    !input ||
    typeof input !== "object" ||
    Array.isArray(input) ||
    input.version !== VERSION
  )
    fail("unsupported version");
  const result = defaults();
  for (const key of Object.keys(input))
    if (!Object.hasOwn(result, key)) fail(`unknown field ${key}`);
  for (const [key, value] of Object.entries(input)) {
    switch (key) {
      case "version":
        break;
      case "model":
        if (value !== null && !safeModelPath(value))
          fail("model path must be library/<id>/model.glb");
        break;
      case "camera":
      case "target":
        if (
          value !== null &&
          !(
            Array.isArray(value) &&
            value.length === 3 &&
            value.every((n) => number(n, -1e9, 1e9))
          )
        )
          fail(`${key} must be three finite coordinates`);
        break;
      case "lighting":
        if (!["studio", "bright", "night"].includes(value)) fail("lighting");
        break;
      case "effect":
        if (!["none", "aura", "sparks", "rings"].includes(value))
          fail("effect");
        break;
      case "background":
      case "effectColor":
        if (typeof value !== "string" || !/^#[0-9a-f]{6}$/i.test(value))
          fail(key);
        break;
      case "exposure":
        if (!number(value, 0.1, 3)) fail(key);
        break;
      case "effectIntensity":
        if (!number(value, 0, 3)) fail(key);
        break;
      case "time":
        if (!number(value, 0, 86400)) fail(key);
        break;
      case "speed":
        if (!number(value, 0.1, 3)) fail(key);
        break;
      case "grid":
      case "wireframe":
      case "turntable":
      case "loop":
        if (typeof value !== "boolean") fail(key);
        break;
      case "clip":
        if (typeof value !== "string" || value.length > 512) fail(key);
        break;
      case "mappings":
        if (
          !value ||
          typeof value !== "object" ||
          Array.isArray(value) ||
          Object.keys(value).sort().join(",") !== "Ability,Idle,Move" ||
          Object.values(value).some(
            (v) => typeof v !== "string" || v.length > 512,
          )
        )
          fail(key);
        break;
    }
    result[key] = structuredClone(value);
  }
  return result;
}
export function clipTime(time, duration, loop) {
  if (!Number.isFinite(time) || !Number.isFinite(duration) || duration <= 0)
    return 0;
  return loop
    ? ((time % duration) + duration) % duration
    : Math.max(0, Math.min(time, duration));
}
export function resolveCompanion(url, files) {
  if (url.startsWith("data:")) return url;
  let decoded;
  try {
    decoded = decodeURIComponent(url).replace(/^\.\//, "");
  } catch {
    throw new Error("Invalid companion filename");
  }
  if (
    /^(?:[a-z]+:|\/|\\)/i.test(decoded) ||
    decoded.split(/[\\/]/).includes("..")
  )
    throw new Error(
      "External or parent asset references are not supported; use an embedded GLB",
    );
  const exact = files.filter(
    (f) => (f.webkitRelativePath || f.name) === decoded,
  );
  const candidates = files.filter((f) => f.name === decoded.split("/").pop());
  const file =
    exact.length === 1
      ? exact[0]
      : exact.length === 0 && candidates.length === 1
        ? candidates[0]
        : null;
  if (!file)
    throw new Error(
      `Missing or ambiguous companion file: ${decoded}. Select the glTF and all its textures/buffers together.`,
    );
  return file;
}
