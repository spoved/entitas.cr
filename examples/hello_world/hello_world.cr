require "../../src/entitas.cr"

CHANNEL = Channel(Char).new(1)

@[Context(Game)]
class DebugMessage < Entitas::Component
  prop :message, String, default: ""

  def to_s(io)
    io << message
  end
end

class DebugMessageSystem < Entitas::ReactiveSystem
  # getter logger = ::Logger.new(STDOUT)
  spoved_logger

  def get_trigger(context : Entitas::Context) : Entitas::Collector(GameEntity)
    logger.level = Logger::INFO
    context.create_collector(GameMatcher.debug_message)
  end

  def execute(entities : Array(Entitas::IEntity))
    entities.each do |e|
      self.logger.error { e.debug_message }
    end
  end
end

class HelloWorldSystem
  include Entitas::Systems::InitializeSystem

  getter context : GameContext

  def initialize(@context : GameContext); end

  def init; end
end

class InputSystem
  spoved_logger

  include Entitas::Systems::ExecuteSystem

  getter context : GameContext

  def initialize(@context : GameContext); end

  def execute
    logger.warn "execute"

    char = CHANNEL.receive
    case char
    when '\u{4}', '\u{3}', '\e'
      logger.warn "Exiting app : #{char.inspect}"
      exit
    else
      # logger.unknown context.component_pools.inspect
      logger.unknown context.entities.size
      context.create_entity.add_debug_message(message: char.inspect)
      logger.unknown context.entities.size
    end
  end
end

class CleanupSystem
  spoved_logger

  include Entitas::Systems::CleanupSystem

  getter context : GameContext
  getter debug_group : Entitas::Group(GameEntity)

  def initialize(@context : GameContext)
    @debug_group = context.get_group(GameMatcher.debug_message)
  end

  def cleanup
    logger.warn "cleanup"
    debug_group.get_entities.each do |e|
      e.destroy!
    end
  end
end

# feature "tutorial", DebugMessageSystem, HelloWorldSystem
class TutorialSystems < Entitas::Feature
  def initialize(contexts : Contexts)
    @name = "Tutorial System"
    ctx = contexts.game
    add ::HelloWorldSystem.new(ctx)
    add ::InputSystem.new(ctx)
    add ::DebugMessageSystem.new(ctx)
    add ::CleanupSystem.new(ctx)
  end
end

class HelloWorld
  getter systems : Entitas::Systems = Entitas::Systems.new

  def start
    # get a reference to the contexts
    contexts = Contexts.shared_instance

    # create the systems by creating individual features
    @systems = Entitas::Feature.new("systems")
      .add(TutorialSystems.new(contexts))
  end

  def update
    # call execute on all the ExecuteSystems and
    # ReactiveSystems that were triggered last frame
    systems.execute

    # call cleanup on all the CleanupSystems
    systems.cleanup
  end
end

hw = HelloWorld.new
hw.start

# game_ctx = Contexts.shared_instance.game
# e = game_ctx.create_entity.add_debug_message(message: "Hello World")
STDIN.blocking = false
spawn do
  ['e', 'f', 'w', '\e'].each do |char|
    CHANNEL.send(char)
  end
end

loop do
  Fiber.yield
  hw.update
end
