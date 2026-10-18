// A loaded model owns its geometries, materials, skeletons and image bitmaps.
// Deduplicate shared resources before releasing them on replacement/stale loads.
export function disposeObject(object) {
  const textures = new Set(),
    materials = new Set(),
    geometries = new Set();
  const skeletons = new Set(),
    bitmaps = new Set();
  object.traverse((node) => {
    if (node.geometry) geometries.add(node.geometry);
    if (node.skeleton) skeletons.add(node.skeleton);
    for (const material of (Array.isArray(node.material)
      ? node.material
      : [node.material]
    ).filter(Boolean)) {
      materials.add(material);
      for (const value of Object.values(material))
        if (value?.isTexture) textures.add(value);
    }
  });
  textures.forEach((texture) => {
    const images = texture.source?.data ?? texture.image;
    for (const image of Array.isArray(images) ? images : [images]) {
      if (image && typeof image.close === "function") bitmaps.add(image);
    }
    texture.dispose();
  });
  skeletons.forEach((skeleton) => skeleton.dispose());
  materials.forEach((material) => material.dispose());
  geometries.forEach((geometry) => geometry.dispose());
  bitmaps.forEach((bitmap) => bitmap.close());
}
