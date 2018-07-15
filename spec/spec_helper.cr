require "spec"
require "../src/entitas"

class TestComponent < Entitas::Component
  is_unique
  prop :size, Int32
  prop :default, String, default: "hello"
end

class TestEntity < Entitas::Entity
  contexts Game, Input
  component Test
end

class TestTwoEntity < Entitas::Entity
  context Game
  components Test
end
