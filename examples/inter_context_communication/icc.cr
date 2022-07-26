require "../../src/entitas"

# This is a simple example of how to use the entitas to have inter context communication.
# Based on: https://github.com/sschmid/Entitas-CSharp/wiki/Inter-context-communication-in-Entitas-0.39.0

# Component that handles a click action on a button.
@[Context(Input)]
class Click < Entitas::Component
  prop :state, Bool, default: false
end

# As we want to only access a single entity on each player, we have an indexed Input id and Game name:
@[Context(Input)]
class InputId < Entitas::Component
  prop :value, String, index: true
end

@[Context(Game)]
class Name < Entitas::Component
  prop :value, String, index: true
end

# Also we need some entites that are the buttons in Entitas:
@[Context(Game)]
class ButtonState < Entitas::Component
  prop :value, Bool
end

# System that reacts to input entities that have click components.
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

# This system is to tidy up any inputs after they have been issued
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

# Controller to setup the systems.
class ICCExample
  getter systems : Entitas::Systems = Entitas::Systems.new
  getter contexts : Contexts = Contexts.shared_instance

  def start
    # get a reference to the contexts
    @contexts = Contexts.shared_instance

    # create the systems by creating individual features
    @systems = Entitas::Feature.new("systems")
      .add(AddClickSystem.new(contexts))
      .add(RemoveClickSystem.new(contexts))
      .add(ButtonSystem.new(contexts))

    # Start our update loop
    spawn { loop { self.update } }
  end

  def update
    # call execute on all the ExecuteSystems and
    # ReactiveSystems that were triggered last frame
    systems.execute

    # call cleanup on all the CleanupSystems
    systems.cleanup
    Fiber.yield
  end
end

controller = ICCExample.new
controller.start
controller.contexts.game.create_entity.add_name("button1")

puts "Send 'exit' to quit"
puts "Send 'click' to simulate a click"
loop do
  Fiber.yield
  puts "Enter a command:"
  input = gets

  if input == "exit"
    break
  end

  if input == "click"
    controller.contexts.input.create_entity
      .add_input_id("button1")
      .add_click(state: true)
  end
end

exit
