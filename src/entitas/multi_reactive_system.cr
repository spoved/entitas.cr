require "../entitas"
require "./systems/reactive"

module Entitas
  # A `Entitas::ReactiveSystem` calls Execute(entities) if there were changes based on
  # the specified `Entitas::Collector` and will only pass in changed entities.
  # A common use-case is to react to changes, e.g. a change of the position
  # of an entity to update the gameObject.transform.position
  # of the related gameObject.
  abstract class MultiReactiveSystem
    include Entitas::Systems::ReactiveSystem

    private getter collectors : Array(Entitas::Collector)
    private property collected_buffer : Array(Entitas::Entity) = Array(Entitas::Entity).new
    private property buffer : Array(Entitas::Entity) = Array(Entitas::Entity).new
    private property to_string_cache : String? = nil

    def initialize(@collectors : Array(Entitas::Collector)); end

    macro extended
      def self.new(contexts : Array(Entitas::Context)) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.collectors = instance.get_trigger(context)
        instance
      end
    end

    # Specify the collector that will trigger the ReactiveSystem.
    protected abstract def get_trigger(contexts : Array(Entitas::Context)) : Array(Entitas::Collector)

    # This will exclude all entities which don't pass the filter.
    protected abstract def filter(entity : Entitas::Entity) : Bool

    protected abstract def execute(entities : Array(Entitas::Entity))

    # Activates the `ReactiveSystem` and starts observing changes
    # based on the specified `Collector`.
    # `ReactiveSystem` are activated by default.
    def activate
      self.collectors.each &.activate
    end

    # Deactivates the `ReactiveSystem`.
    # No changes will be tracked while deactivated.
    # This will also clear the `ReactiveSystem`.
    # `ReactiveSystem` are activated by default.
    def deactivate
      self.collectors.each &.deactivate
    end

    # Clears all accumulated changes.
    def clear
      self.collectors.each &.clear
    end

    def execute
      self.collectors.each do |collector|
        unless collector.empty?
          self.collected_buffer += collector.entities
          collector.clear
        end
      end

      collected_buffer.each do |e|
        if self.filter(e)
          e.retain(self)
          self.buffer << e unless buffer.includes?(e)
        end
      end

      unless self.buffer.empty?
        begin
          self.execute(self.buffer)
        ensure
          self.buffer.each { |e| e.release(self) }

          self.collected_buffer.clear
          self.buffer.clear
        end
      end
    end

    def to_s(io)
      io << to_string_cache
    end

    def to_s
      if to_string_cache.nil?
        self.to_string_cache = "MultiReactiveSystem(#{self.class})"
      end
      to_string_cache
    end
  end
end
