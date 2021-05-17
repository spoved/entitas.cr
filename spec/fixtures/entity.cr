require "../../src/entitas"

module MyEntity
  include Entitas::IEntity
  # include NameAge::Helper
end

class TestEntity < Entitas::Entity
  include MyEntity
end

class Test2Entity < Entitas::Entity
  include MyEntity
end
