start_bench ::Entitas::Entity, ->do
  bench "#reactivate", ->{
    ctx = TestContext.new
    e = ctx.create_entity
  }, ->{
    e.reactivate(1)
  }, ->{}, true

  bench "#destroy!", ->{
    ctx = TestContext.new
  }, ->{
    ctx.create_entity.destroy!
  }, ->{}, true

  group "Create Entity", ->do
    bench "control", ->{
      pool = Array(Entitas::ComponentPool).new
    }, ->{
      TestEntity.new(1, 5, pool)
    }, ->{}, true

    bench "#create_entity", ->{
      ctx = TestContext.new
    }, ->{
      ctx.create_entity
    }, ->{}, true
  end

  group "Add Component", ->do
    bench "#add_component", ->{
      ctx = TestContext.new
    }, ->{
      ctx.create_entity.add_component(Entitas::Component::Index::A, A.new)
    }, ->{}, true
    bench "#add_a", ->{
      ctx = TestContext.new
    }, ->{
      ctx.create_entity.add_a
    }, ->{}, true
  end

  bench "#replace_component", ->{
    ctx = TestContext.new
    e = ctx.create_entity.add_a
  }, ->{
    e.replace_component(Entitas::Component::Index::A, e.create_component(Entitas::Component::Index::A))
  }, ->{}, true

  group "Event triggers", ->do
    bench "#on_component_replaced_event_hooks.each", ->{
      ctx = TestContext.new
      entity = ctx.create_entity.add_a
      entity.on_component_replaced do
        nil
      end
      event = Entitas::Events::OnComponentReplaced.new(entity, 1, entity.a, A.new)
    }, ->{
      entity.on_component_replaced_event_hooks.each &.call(event)
    }, ->{}, true

    bench "#on_component_replaced_event_hooks.reverse.each", ->{
      ctx = TestContext.new
      entity = ctx.create_entity.add_a
      entity.on_component_replaced do
        nil
      end
      event = Entitas::Events::OnComponentReplaced.new(entity, 1, entity.a, A.new)
    }, ->{
      entity.on_component_replaced_event_hooks.reverse.each &.call(event)
    }, ->{}, true

    bench "#receive_on_component_replaced_event", ->{
      ctx = TestContext.new
      entity = ctx.create_entity.add_a
      entity.on_component_replaced do
        nil
      end
      event = Entitas::Events::OnComponentReplaced.new(entity, 1, entity.a, A.new)
    }, ->{
      entity.receive_on_component_replaced_event(event)
    }, ->{}, true

    bench "#receive_on_component_added_event", ->{
      ctx = TestContext.new
      entity = ctx.create_entity.add_a
      entity.on_component_added do
        nil
      end
      event = Entitas::Events::OnComponentAdded.new(entity, 1, A.new)
    }, ->{
      entity.receive_on_component_added_event(event)
    }, ->{}, true
  end
end
