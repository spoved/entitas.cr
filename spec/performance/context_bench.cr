start_bench Context, ->do
  bench_n_times "#create_entity",
    ->{ ctx = TestContext.new },
    ->{
      ctx.create_entity
    },
    ->{ ctx.clear_component_pools }

  bench "#get_entities &Entity.destroy!",
    ->{
      ctx = TestContext.new
      n.times { ctx.create_entity }
    },
    ->{ ctx.get_entities.each &.destroy! },
    ->{ ctx.clear_component_pools }

  bench "#destroy_all_entities",
    ->{
      ctx = TestContext.new
      n.times { ctx.create_entity }
    },
    ->{ ctx.destroy_all_entities },
    ->{ ctx.clear_component_pools }

  bench_n_times "#get_group by Int32",
    ->{ ctx = TestContext.new },
    ->{
      ctx.get_group(Entitas::Matcher.all_of(0))
    },
    ->{}

  bench_n_times "#get_group by class",
    ->{ ctx = TestContext.new },
    ->{
      ctx.get_group(Entitas::Matcher.all_of(A))
    },
    ->{}

  bench_n_times "#get_group by Enum",
    ->{ ctx = TestContext.new },
    ->{
      ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
    },
    ->{}

  bench "#get_entities",
    ->{
      ctx = TestContext.new
      n.times { ctx.create_entity }
    },
    ->{ ctx.get_entities },
    ->{ ctx.clear_component_pools }

  bench_n_times "#has_entity?",
    ->{
      ctx = TestContext.new
      n.times { ctx.create_entity }
      e = ctx.create_entity
    },
    ->{
      ctx.has_entity?(e)
    },
    ->{ ctx.clear_component_pools }

  bench_n_times "OnEntityReplaced",
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