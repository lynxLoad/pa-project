components {
  id: "pawn"
  component: "/game/pawn/pawn.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"1down\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/res/character.tilesource\"\n"
  "}\n"
  ""
  position {
    y: 5.0
  }
}
