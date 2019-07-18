require "spoved/logger"
require "./entitas/*"

# TODO: Write documentation for `Entitas`
module Entitas
  spoved_logger
end

@[Component::Unique]
class UniqueComp < Entitas::Component
  prop :size, Int32
  prop :default, String, default: "foo"
end
