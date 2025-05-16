components {
  id: "pawn"
  component: "/game/pawn/pawn.script"
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
