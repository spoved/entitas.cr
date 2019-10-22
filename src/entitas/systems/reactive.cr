require "./execute"

module Entitas::Systems::ReactiveSystem
  include Entitas::System
  include Entitas::Systems::ExecuteSystem

  abstract def activate
  abstract def deactivate
  abstract def clear
end
