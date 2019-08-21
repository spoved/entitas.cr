class DumbKlass
end

start_bench ::Entitas::Context, ->do
  group "inititalize", ->do
    bench "control", ->{}, ->{
      DumbKlass.new
    }, ->{}, true

    bench "#new", ->{}, ->{
      TestContext.new
    }, ->{}, true

    bench "#create_entity", ->{
      ctx = TestContext.new
    }, ->{
      ctx.create_entity
    }, ->{}, true
  end

  group "Event triggers", ->do
    bench "#on_destroy_entity", ->{
      ctx = TestContext.new
    }, ->{
      entity = ctx.create_entity
      event = Entitas::Events::OnDestroyEntity.new(entity)
      ctx.on_destroy_entity(event)
    }, ->{}, true
  end
end
