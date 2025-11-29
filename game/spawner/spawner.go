components {
  id: "spawner"
  component: "/game/spawner/spawner.script"
}
embedded_components {
  id: "tilemapfactory"
  type: "factory"
  data: "prototype: \"/game/tilemap/tilemap.go\"\n"
  ""
}
embedded_components {
  id: "camerafactory"
  type: "factory"
  data: "prototype: \"/game/camera/camera.go\"\n"
  ""
}
embedded_components {
  id: "pawnfactory"
  type: "collectionfactory"
  data: "prototype: \"/game/pawn/pawn.collection\"\n"
  ""
}
