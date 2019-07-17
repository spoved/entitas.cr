require "spec"
require "../src/entitas"
require "./fixtures/*"

def clear_pools
  ::Entitas::Component::POOLS.each { |p| p.clear }
end

def component_pools
  Array(Entitas::ComponentPool).new(::Entitas::Component::TOTAL_COMPONENTS)
end

def new_entity
  Entitas::Entity.new(1)
end

def new_entity_with_a
  entity = new_entity
  entity.add_a
  entity
end

def new_entity_with_ab
  entity = new_entity_with_a
  entity.add_b
  entity
end
