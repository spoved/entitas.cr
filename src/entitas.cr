require "./entitas/*"

# TODO: Write documentation for `Entitas`
module Entitas
end

@[Component::Unique]
class UniqueComp < Entitas::Component
  prop :size, Int32
  prop :default, String, default: "foo"
end
