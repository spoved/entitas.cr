require "spec"
require "../src/entitas"
require "./fixtures/*"

Spoved.logger.level = Logger::DEBUG

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

def new_context_info
  Entitas::Context::Info.new("TestContext")
end

def new_context
  TestContext.new(context_info: new_context_info,
    aerc_factory: Entitas::AERCFactory.new { |entity| Entitas::SafeAERC.new(entity) },
    entity_factory: Entitas::EntityFactory.new { TestEntity.new },
  )
end

def context_with_entity
  ctx = new_context
  e = ctx.create_entity
  e.add_a

  {ctx, e}
end
