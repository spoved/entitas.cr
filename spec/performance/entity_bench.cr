start_bench Entity, ->do
  bench_n_times "#add_component", 10_000_000,
    ->{
      ctx = TestContext.new
      e = ctx.create_entity
      comp_a = A.new
    },
    ->{
      e.add_component(Entitas::Component::Index::A, e.create_component(Entitas::Component::Index::A))
      e.remove_component(Entitas::Component::Index::A)
    },
    ->{}

  bench_n_times "#get_component", 10_000_000,
    ->{
      ctx = TestContext.new
      e = ctx.create_entity.add_a.add_b.add_c
    },
    ->{
      e.get_component Entitas::Component::Index::A
    },
    ->{}

  bench_n_times "#a", 10_000_000,
    ->{
      ctx = TestContext.new
      e = ctx.create_entity.add_a.add_b.add_c
    },
    ->{
      e.a
    },
    ->{}
end
