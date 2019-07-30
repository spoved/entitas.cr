require "../../src/entitas.cr"

@[Context(Game)]
class DebugMessage < Entitas::Component
  prop :message, String, default: ""

  def to_s(io)
    io << message
  end
end

class DebugMessageSystem < ::Entitas::ReactiveSystem
  # getter logger = ::Logger.new(STDOUT)
  spoved_logger

  def get_trigger(context : Entitas::Context) : Entitas::Collector
    logger.level = Logger::INFO
    context.create_collector(GameMatcher.debug_message)
  end

  def execute(entities : Array(Entitas::Entity))
    entities.each do |e|
      self.logger.error(e.debug_message, e.to_s)
    end
  end
end

class HelloWorldSystem
  include Entitas::Systems::InitializeSystem

  getter context : Entitas::Context

  def initialize(@context : Entitas::Context)
  end

  def init; end
end

# feature "tutorial", DebugMessageSystem, HelloWorldSystem
class TutorialSystems < Entitas::Feature
  def initialize(contexts : Contexts)
    @name = "Tutorial System"
    add DebugMessageSystem.new(contexts.game)
    add HelloWorldSystem.new(contexts.game)
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

game_ctx = Contexts.shared_instance.game
e = game_ctx.create_entity.add_debug_message(message: "Hello World")
e.retain(hw)

hw.update
hw.update
