start_bench "Array vs Hash", ->do
  group "get", ->do
    bench "Array[]",
      ->{
        data = Array(Entitas::Entity).new
        ctx = TestContext.new
        10.times do
          data.push ctx.create_entity
        end
      },
      ->{
        10.times do |i|
          data[i]
        end
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Set[]",
      ->{
        data = Set(Entitas::Entity).new
        ctx = TestContext.new
        10.times do
          data.push ctx.create_entity
        end
      },
      ->{
        10.times do |_|
          data.first
        end
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Hash[]",
      ->{
        data = Hash(Int32, Entitas::Entity).new
        ctx = TestContext.new
        10.times do |i|
          data[i] = ctx.create_entity
        end
      },
      ->{
        10.times do |i|
          data[i]
        end
      },
      ->{ ctx.clear_component_pools },
      true
  end

  group "push", ->do
    bench "Array[]",
      ->{
        data = Array(Entitas::Entity).new
        ctx = TestContext.new
      },
      ->{
        data.push ctx.create_entity
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Set[]",
      ->{
        data = Set(Entitas::Entity).new
        ctx = TestContext.new
      },
      ->{
        data.add ctx.create_entity
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Hash[]",
      ->{
        data = Hash(Int32, Entitas::Entity).new
        ctx = TestContext.new
      },
      ->{
        data[data.size + 1] = ctx.create_entity
      },
      ->{ ctx.clear_component_pools },
      true
  end

  group "clear", ->do
    bench "Array[]",
      ->{
        data = Array(Entitas::Entity).new
        ctx = TestContext.new
        10.times do
          data.push ctx.create_entity
        end
      },
      ->{
        data.clear
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Set[]",
      ->{
        data = Set(Entitas::Entity).new
        ctx = TestContext.new
        10.times do
          data.add ctx.create_entity
        end
      },
      ->{
        data.clear
      },
      ->{ ctx.clear_component_pools },
      true

    bench "Hash[]",
      ->{
        data = Hash(Int32, Entitas::Entity).new
        ctx = TestContext.new
        10.times do |i|
          data[i] = ctx.create_entity
        end
      },
      ->{
        data.clear
      },
      ->{ ctx.clear_component_pools },
      true
  end
end
