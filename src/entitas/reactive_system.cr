require "../entitas"
require "./systems/reactive"

module Entitas
  # A `Entitas::ReactiveSystem` calls Execute(entities) if there were changes based on
  # the specified `Entitas::Collector` and will only pass in changed entities.
  # A common use-case is to react to changes, e.g. a change of the position
  # of an entity to update the gameObject.transform.position
  # of the related gameObject.
  abstract class ReactiveSystem
    include Entitas::Systems::ReactiveSystem

    private getter collector : Entitas::Collector
    private property buffer : Array(Entitas::Entity) = Array(Entitas::Entity).new
    private property to_string_cache : String? = nil

    def initialize(@collector : Entitas::Collector); end

    macro extended
      def self.new(context : Entitas::Context) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.collector = instance.get_trigger(context)
        instance
      end
    end

    # Specify the collector that will trigger the ReactiveSystem.
    protected abstract def get_trigger(context : Entitas::Context) : Entitas::Collector

    # This will exclude all entities which don't pass the filter.
    protected abstract def filter(entity : Entitas::Entity) : Bool

    protected abstract def execute(entities : Array(Entitas::Entity))

    # Activates the `ReactiveSystem` and starts observing changes
    # based on the specified `Collector`.
    # `ReactiveSystem` are activated by default.
    def activate
      self.collector.activate
    end

    # Deactivates the `ReactiveSystem`.
    # No changes will be tracked while deactivated.
    # This will also clear the `ReactiveSystem`.
    # `ReactiveSystem` are activated by default.
    def deactivate
      self.collector.deactivate
    end

    # Clears all accumulated changes.
    def clear
      self.collector.clear
    end

    def execute
      unless self.collector.empty?
        self.collector.each do |e|
          if self.filter(e)
            e.retain(self)
            self.buffer << e unless buffer.includes?(e)
          end
        end

        self.collector.clear

        unless self.buffer.empty?
          begin
            self.execute(self.buffer)
          ensure
            self.buffer.each { |e| e.release(self) }
            self.buffer.clear
          end
        end
      end
    end

    def to_s(io)
      io << to_string_cache
    end

    def to_s
      if to_string_cache.nil?
        self.to_string_cache = "ReactiveSystem(#{self.class})"
      end
      to_string_cache
    end
  end
end
