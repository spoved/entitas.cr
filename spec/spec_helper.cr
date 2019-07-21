require "spec"
require "../src/entitas"
require "./fixtures/*"

Spoved.logger.level = Logger::UNKNOWN

# Spoved.logger.level = Logger::DEBUG

def component_pools
  Array(Entitas::ComponentPool).new(::Entitas::Component::TOTAL_COMPONENTS) do
    Entitas::ComponentPool.new
  end
end

def new_entity
  TestEntity.new(1, ::Entitas::Component::TOTAL_COMPONENTS, component_pools)
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

def new_context_info
  Entitas::Context::Info.new("TestContext")
end

def new_context
  TestContext.new
end

def context_with_entity
  ctx = new_context
  e = ctx.create_entity
  e.add_a

  {ctx, e}
end
