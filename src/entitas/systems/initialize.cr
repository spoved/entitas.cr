require "../system"

module Entitas::Systems::InitializeSystem
  include Entitas::System

  abstract def init
end
