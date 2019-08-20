start_bench ::Entitas::Entity, ->do
  bench "#reactivate", ->{
    ctx = TestContext.new
    e = ctx.create_entity
  }, ->{
    e.reactivate(1)
  }, ->{}, true
end
