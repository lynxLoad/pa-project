components {
  id: "bridge"
  component: "/bridge/bridge.script"
}
embedded_components {
  id: "camerafactory"
  type: "factory"
  data: "prototype: \"/game/base/camera.go\"\n"
  "load_dynamically: true\n"
  ""
}
embedded_components {
  id: "spritefactory"
  type: "factory"
  data: "prototype: \"/game/base/sprite.go\"\n"
  "load_dynamically: true\n"
  ""
}
embedded_components {
  id: "labelfactory"
  type: "factory"
  data: "prototype: \"/game/base/label.go\"\n"
  "load_dynamically: true\n"
  ""
}
embedded_components {
  id: "soundfactory"
  type: "factory"
  data: "prototype: \"/game/base/sound.go\"\n"
  "load_dynamically: true\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"pawn\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/sprites/atlas.atlas\"\n"
  "}\n"
  ""
}
