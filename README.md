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

Run `crystal docs` to generate API Docs and examples.

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
