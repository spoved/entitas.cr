module Entitas::Systems::InitializeSystem
  include Entitas::System

  abstract def init : Nil
end
