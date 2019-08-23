module Entitas::Systems::TearDownSystem
  include Entitas::System

  abstract def tear_down : Nil
end
