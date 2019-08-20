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
end
