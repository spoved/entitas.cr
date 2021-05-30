require "json"

module Entitas
  abstract class Controller
    private property systems : Systems? = nil

    private getter mutex : Mutex = Mutex.new

    @[JSON::Field(ignore: true)]
    private setter contexts : Contexts? = nil

    delegate synchronize, to: @mutex

    # Will allow you to interact with the returned `Contexts` with a `Mutex` lock
    # preventing `#update` from being called in another thread
    def with_contexts
      self.synchronize do
        yield self.contexts
      end
    end

    def contexts : Contexts
      if @contexts.nil?
        raise "No contexts set for controller"
      end
      @contexts.as(Contexts)
    end

    def start
      unless systems.nil?
        raise "Called start more than once! systems already initialized!"
      end

      self.contexts = Contexts.shared_instance if @contexts.nil?
      with_contexts do |ctxs|
        self.systems = create_systems(ctxs)
        self.systems.as(Systems).init
      end
    end

    def update
      if systems.nil?
        raise "Called update before start! no systems initialized!"
      end

      self.synchronize do
        systems.as(Systems).execute
        systems.as(Systems).cleanup
      end
    end

    def reset
      if systems.nil?
        raise "Called reset before start! no systems initialized!"
      end

      with_contexts do |ctxs|
        systems.as(Systems).clear_reactive_systems
        ctxs.reset
      end
    end

    abstract def create_systems(contexts : Contexts)

    def stats
      contexts.as(Contexts).all_contexts
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field("name", self.class.to_s)
        json.field("systems", self.systems)
      end
    end
  end
end
