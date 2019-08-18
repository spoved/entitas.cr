start_bench ::Entitas::Context, ->do
  group "Create Entity", ->do
    bench_n_times "#create_entity w/o pre", 100_000,
      ->{ ctx = TestContext.new },
      ->{
        ctx.create_entity
      },
      ->{ ctx.clear_component_pools }

    bench_n_times "#create_entity w/ pre", 100_000,
      ->{
        ctx = TestContext.new
        100_000.times { ctx.create_entity }
        ctx.destroy_all_entities
      },
      ->{
        ctx.create_entity
      },
      ->{ ctx.clear_component_pools }
  end

  group "Destroy all entities", ->do
    bench "#get_entities &Entity.destroy!",
      ->{
        ctx = TestContext.new
        100_000.times { ctx.create_entity }
      },
      ->{ ctx.get_entities.each &.destroy! },
      ->{ ctx.clear_component_pools }

    bench "#destroy_all_entities",
      ->{
        ctx = TestContext.new
        100_000.times { ctx.create_entity }
      },
      ->{ ctx.destroy_all_entities },
      ->{ ctx.clear_component_pools }
  end

  group "#get_group", ->do
    bench_n_times "#get_group by Int32", 100_000,
      ->{ ctx = TestContext.new },
      ->{
        ctx.get_group(Entitas::Matcher.all_of(0))
      },
      ->{}

    bench_n_times "#get_group by class", 100_000,
      ->{ ctx = TestContext.new },
      ->{
        ctx.get_group(Entitas::Matcher.all_of(A))
      },
      ->{}

    bench_n_times "#get_group by Enum ", 100_000,
      ->{ ctx = TestContext.new },
      ->{
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
      },
      ->{}
  end

  bench "#get_entities",
    ->{
      ctx = TestContext.new
      100_000.times { ctx.create_entity }
    },
    ->{ ctx.get_entities },
    ->{ ctx.clear_component_pools }

  bench_n_times "#has_entity?", 100_000,
    ->{
      ctx = TestContext.new
      100_000.times { ctx.create_entity }
      e = ctx.create_entity
    },
    ->{
      ctx.has_entity?(e)
    },
    ->{ ctx.clear_component_pools }

  bench_n_times "OnEntityReplaced", 100_000,
    ->{
      ctx = TestContext.new
      ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
      e = ctx.create_entity.add_a
    },
    ->{
      e.replace_a(A.new)
    },
    ->{}
end
