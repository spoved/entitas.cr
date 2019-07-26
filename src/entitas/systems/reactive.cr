require "../system"

module Entitas::Systems::ReactiveSystem
  include Entitas::System

  abstract def activate
  abstract def deactivate
  abstract def clear
end
