require "json"

module Entitas
  abstract class Controller
    private property systems : Systems? = nil

    @[JSON::Field(ignore: true)]
    private setter contexts : Contexts? = nil

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
      self.systems = create_systems(self.contexts.as(Contexts))
      self.systems.as(Systems).init
    end

    def update
      if systems.nil?
        raise "Called update before start! no systems initialized!"
      end
      systems.as(Systems).execute
      systems.as(Systems).cleanup
    end

    def reset
      if systems.nil?
        raise "Called reset before start! no systems initialized!"
      end
      systems.as(Systems).clear_reactive_systems
      contexts.as(Contexts).reset
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
