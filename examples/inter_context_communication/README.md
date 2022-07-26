# Inter context communication in Entitas

This is a simple example of how to use the entitas to have inter context communication.
Based on: <https://github.com/sschmid/Entitas-CSharp/wiki/Inter-context-communication-in-Entitas-0.39.0>

In this example we have two contexts:

- Game
- Input

The overall process is:

- User click a button in the local game world
- GameObject handles click event, send the event across the network that generates an entity locally
- New entity triggers reactive system behaviours via collectors
- Input is translated into game entity

## Components

Component that handles a click action on a button.

```crystal
@[Context(Input)]
class Click < Entitas::Component
  prop :state, Bool, default: false
end
```

As we want to only access a single entity on each player, we have an indexed Input id and Game name:

```crystal
@[Context(Input)]
class InputId < Entitas::Component
  prop :value, String, index: true
end

@[Context(Game)]
class Name < Entitas::Component
  prop :value, String, index: true
end
```

Also we need some entites that are the buttons in Entitas:

```crystal
@[Context(Game)]
class ButtonState < Entitas::Component
  prop :value, String
end
```

## Auto generated Contxt extensions

Because we are using `index: true` when creating the property, the code generator will automatically create the following methods:

```crystal
module Entitas::Contexts::Extensions::InputIndexes
  def get_entities_with_input_id_value(value : String) : Array(InputEntity)
  def get_entity_with_input_id_value(value : String) : InputEntity?
  def get_input_entities_with_input_id_value(context : InputContext, value : String)
end

module Entitas::Contexts::Extensions::GameIndexes
  def get_entities_with_name_value(value : String) : Array(GameEntity)
  def get_entity_with_name_value(value : String) : GameEntity?
  def get_game_entities_with_name_value(context : GameContext, value : String)
end
```

Which will be included in the corrisponding contexts.

## Triggering a "click"

Since the example is a command line application, we need to simulate a click event. We will do this by submitting 'click' as a command to the console.

```crystal
puts "Send 'exit' to quit"
puts "Send 'click' to simulate a click"
loop do
  puts "Enter a command:"
  input = gets.chomp
  if input == "exit"
    break
  end

  if input == "click"
    controller.contexts.input.create_entity
      .add_input_id("player1")
      .add_click(state: false)
  end
end
```

## Input Context Systems

Then somewhere in your features you will have a system that reacts to input entities that have click components:

```crystal
class AddClickSystem < ::Entitas::ReactiveSystem
  protected property contexts : Contexts
  protected property context : InputContext

  def initialize(@contexts)
    @context = @contexts.input.as(InputContext)
    @collector = get_trigger(context)
  end

  def get_trigger(context : Entitas::Context) : Entitas::ICollector
    context.create_collector(InputMatcher.click.added)
  end

  def filter(entity : InputEntity)
    entity.has_input_id?
  end

  def execute(entities : Array(Entitas::IEntity))
    entities.each do |entity|
      entity = entity.as(InputEntity)
      obj = contexts.game.get_entity_with_name_value(entity.input_id.value)
      if !obj.nil?
        obj.replace_button_state(entity.click.state)
      end
      entity.remove_click
    end
  end
end
```

This system is to tidy up any inputs after they have been issued:

```crystal
class RemoveClickSystem < ::Entitas::ReactiveSystem
  protected property contexts : Contexts
  protected property context : InputContext

  def initialize(@contexts)
    @context = @contexts.input
    @collector = get_trigger(context)
  end

  def get_trigger(context : Entitas::Context) : Entitas::ICollector
    context.create_collector(InputMatcher.click.removed)
  end

  def filter(entity : InputEntity)
    entity.has_input_id?
  end

  def execute(entities : Array(Entitas::IEntity))
    entities.each do |entity|
      entity = entity.as(InputEntity)
      entity.destroy
    end
  end
end
```

## Game Context Systems

Now that a entity has been changed in the game context, a system can react to the change. In this example the input is decoupled from the game state so that the local system is responsible for doing something with the change. In this example it will print out "pressed" if the state of the button is true.

```crystal
class ButtonSystem < ::Entitas::ReactiveSystem
  protected property contexts : Contexts
  protected property context : GameContext

  def initialize(@contexts)
    @context = @contexts.game
    @collector = get_trigger(context)
  end

  def get_trigger(context : Entitas::Context) : Entitas::ICollector
    context.create_collector(GameMatcher.button_state)
  end

  def filter(entity : GameEntity)
    entity.has_button_state?
  end

  def execute(entities : Array(Entitas::IEntity))
    entities.each do |entity|
      entity = entity.as(GameEntity)
      puts %<* Button #{entity.name.value} is #{entity.button_state.value ? "pressed" : "released"} *>
    end
  end
end
```
