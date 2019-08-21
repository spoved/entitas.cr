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
end
