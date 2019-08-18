start_bench ::Entitas::Entity, ->do
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

  group "Get Component A", ->do
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

  bench_n_times "#get_components", 1_000_000,
    ->{
      ctx = TestContext.new
      e = ctx.create_entity.add_a.add_b.add_c
    },
    ->{
      e.get_components
    },
    ->{}

  group "Has Component?", ->do
    bench_n_times "#has_component?", 1_000_000,
      ->{
        ctx = TestContext.new
        e = ctx.create_entity.add_a.add_b.add_c
      },
      ->{
        e.has_component? Entitas::Component::Index::A
      },
      ->{}

    bench_n_times "#a?", 10_000_000,
      ->{
        ctx = TestContext.new
        e = ctx.create_entity.add_a.add_b.add_c
      },
      ->{
        e.a?
      },
      ->{}
  end

  group "Remove and Add Component", ->do
    bench_n_times "#remove_component & #add_component", 10_000_000,
      ->{
        ctx = TestContext.new
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::B))
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::C))
        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::B
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::C
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::B,
          Entitas::Component::Index::C
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::B,
          Entitas::Component::Index::C
        ))

        comp_a = A.new
        e = ctx.create_entity
        e.add_component(comp_a)
      },
      ->{
        e.remove_component(Entitas::Component::Index::A)
        e.add_component(Entitas::Component::Index::A, e.create_component(Entitas::Component::Index::A))
      },
      ->{}

    bench_n_times "#del_a & #add_a", 10_000_000,
      ->{
        ctx = TestContext.new
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::B))
        ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::C))
        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::B
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::C
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::B,
          Entitas::Component::Index::C
        ))

        ctx.get_group(Entitas::Matcher.all_of(
          Entitas::Component::Index::A,
          Entitas::Component::Index::B,
          Entitas::Component::Index::C
        ))

        comp_a = A.new
        e = ctx.create_entity
        e.add_component(comp_a)
      },
      ->{
        e.del_a
        e.add_a
      },
      ->{}
  end

  bench_n_times "#replace_component", 10_000_000,
    ->{
      ctx = TestContext.new
      ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::A))
      ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::B))
      ctx.get_group(Entitas::Matcher.all_of(Entitas::Component::Index::C))
      ctx.get_group(Entitas::Matcher.all_of(
        Entitas::Component::Index::A,
        Entitas::Component::Index::B
      ))

      ctx.get_group(Entitas::Matcher.all_of(
        Entitas::Component::Index::A,
        Entitas::Component::Index::C
      ))

      ctx.get_group(Entitas::Matcher.all_of(
        Entitas::Component::Index::B,
        Entitas::Component::Index::C
      ))

      ctx.get_group(Entitas::Matcher.all_of(
        Entitas::Component::Index::A,
        Entitas::Component::Index::B,
        Entitas::Component::Index::C
      ))

      comp_a = A.new
      e = ctx.create_entity
      e.add_component(comp_a)
    },
    ->{
      e.replace_component(Entitas::Component::Index::A, A.new)
    },
    ->{}

  bench_n_times "#total_components", 10_000_000,
    ->{
      ctx = TestContext.new
    },
    ->{
      ctx.total_components
    },
    ->{}
end
