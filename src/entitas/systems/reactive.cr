require "./execute"

module Entitas::Systems::ReactiveSystem
  include Entitas::System
  include Entitas::Systems::ExecuteSystem

  abstract def activate : Nil
  abstract def deactivate : Nil
  abstract def clear : Nil
end
