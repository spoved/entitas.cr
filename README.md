# entitas

A Entity Component System Framework for Crystal. Ported from: [Entitas-CSharp](https://github.com/sschmid/Entitas-CSharp)

Entitas is a super fast Entity Component System Framework (ECS). Internal caching and blazing fast component access makes it second to none. Several design decisions have been made to work optimal in a garbage collected environment and to go easy on the garbage collector. Utilizing Crystal's macro system, all code generation is done compile time. No need for a code generator!

[![Build Status](https://travis-ci.com/kalinon/entitas.cr.svg?token=Shp7EsY9qyrwFK1NgezB&branch=master)](https://travis-ci.com/kalinon/entitas.cr)

## First glimpse

```crystal
public def create_red_gem(context : GameContext, position)
  entity.is_game_board_element = true
  entity.is_movable = true
  entity = context.create_entity
  entity.add_position(position)
  entity.add_asset("RedGem")
  entity.is_interactive = true
  entity
end
```

```crystal
entities = context.get_entities(Entitas::Matcher.all_of(Position, Velocity))
entities.each do |e|
  pos = e.position
  vel = e.velocity
end
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  entitas:
    github: kalinon/entitas.cr
```

## Usage

```crystal
require "entitas"
```

Run `crystal docs` to generate API Docs and examples. You may need to include an example, as there are no default contexts and the macros need at least one for some things. `crystal docs examples/hello_world/hello_world.cr`

Examples can also be found in the `spec/fixtures` and `examples` folders. Ive replicated every test i could from the C# lib, so many examples and translations can be found there as well.

## Benchmarks

It is very important to make sure the lib is compariable to the original entitas. Here are some of the benchmarks to compare. Each benchmark was written as close as possible to the main source. As well as any aliases of the methods were tested. Most impressivly, the slowest test (EntityRemoveAddComponent) clocked in at 868.6 ms vs the crystal equivilant (#remove_component & #add_component) at 290.0 ms. Thats a 3x speed improvement.

### Enitas C#
```
Running performance tests...
ContextCreateEntity:                    98.5355 ms
ContextDestroyEntity:                   33.0015 ms
ContextDestroyAllEntities:              32.4288 ms
ContextGetGroup:                        6.2042 ms
ContextGetEntities:                     2.322 ms
ContextHasEntity:                       1.9293 ms
ContextOnEntityReplaced:                21.4785 ms

EntityAddComponent:                     496.7223 ms
EntityGetComponent:                     39.1669 ms
EntityGetComponents:                    5.9182 ms
EntityHasComponent:                     5.4402 ms
EntityRemoveAddComponent:               868.6205 ms
EntityReplaceComponent:                 164.2688 ms
```

### Entitas Cr

```
--## Entitas::Context(TEntity) ##--
-- Total execution time --

                       user     system      total        real
#get_entities      0.000000   0.000000   0.000000 (  0.001150)
#has_entity?       0.000000   0.000000   0.000000 (  0.000714)
OnEntityReplaced   0.000000   0.000000   0.000000 (  0.005321)

- Create Entity -
                             user     system      total        real
#create_entity w/o pre   0.080000   0.000000   0.080000 (  0.083808)
#create_entity w/ pre    0.020000   0.000000   0.020000 (  0.019606)

- Destroy all entities -
                                          user     system      total        real
control                               0.000000   0.000000   0.000000 (  0.000001)
#get_entities &Entity.destroy!        0.020000   0.010000   0.030000 (  0.021025)
#destroy_all_entities                 0.020000   0.000000   0.020000 (  0.020348)
#destroy_all_entities (pre-destroy)   0.020000   0.000000   0.020000 (  0.016953)

- #get_group -
                          user     system      total        real
#get_group by Int32   0.050000   0.000000   0.050000 (  0.053371)
#get_group by class   0.050000   0.000000   0.050000 (  0.047716)
#get_group by Enum    0.050000   0.000000   0.050000 (  0.047686)


--## Entitas::Entity ##--
-- Total execution time --

                         user     system      total        real
#add_component       0.370000   0.000000   0.370000 (  0.374146)
#get_components      0.000000   0.000000   0.000000 (  0.002171)
#replace_component   0.040000   0.000000   0.040000 (  0.040704)
#total_components    0.000000   0.000000   0.000000 (  0.000001)

- Get Component A -
                                                user     system      total        real
#get_component(Entitas::Component::Index)   0.040000   0.000000   0.040000 (  0.035134)
#get_component(Int32)                       0.030000   0.000000   0.030000 (  0.033637)
#get_component(A::INDEX)                    0.040000   0.000000   0.040000 (  0.036969)
#get_component(A::INDEX_VALUE)              0.030000   0.000000   0.030000 (  0.033226)
#a                                          0.040000   0.000000   0.040000 (  0.041205)

- Has Component? -
                      user     system      total        real
#has_component?   0.000000   0.000000   0.000000 (  0.000001)
#a?               0.000000   0.000000   0.000000 (  0.000001)

- Remove and Add Component -
                                         user     system      total        real
#remove_component & #add_component   0.250000   0.040000   0.290000 (  0.298851)
#del_a & #add_a                      0.250000   0.040000   0.290000 (  0.292872)
```

## Development

Dont forget to add your pre-commit hooks!

```
ln ./pre-commit .git/hooks/pre-commit
```

## Contributing

1. Fork it (<https://github.com/kalinon/entitas.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Holden Omans](https://github.com/kalinon) - creator, maintainer
