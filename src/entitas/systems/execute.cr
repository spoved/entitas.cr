require "../system"

module Entitas::Systems::ExecuteSystem
  include Entitas::System

  abstract def execute
end
