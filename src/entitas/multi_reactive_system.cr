require "../entitas"
require "./systems/reactive"

module Entitas
  # A `Entitas::ReactiveSystem` calls Execute(entities) if there were changes based on
  # the specified `Entitas::Collector` and will only pass in changed entities.
  # A common use-case is to react to changes, e.g. a change of the position
  # of an entity to update the gameObject.transform.position
  # of the related gameObject.
  abstract class MultiReactiveSystem
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    include Entitas::Systems::ReactiveSystem

    private getter collectors : Array(Entitas::Collector)
    private property collected_buffer : Array(Entitas::Entity) = Array(Entitas::Entity).new
    private property buffer : Array(Entitas::Entity) = Array(Entitas::Entity).new
    private property to_string_cache : String? = nil
    protected property _filter : Proc(Entitas::Entity, Bool) = ->(entity : Entitas::Entity) { true }

    def initialize(@collectors : Array(Entitas::Collector)); end

    macro inherited
      def self.new(collectors : Array(Entitas::Collector), filter : Proc(Entitas::Entity, Bool)) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize collectors
        instance._filter = filter
        instance
      end

      def self.new(context : Entitas::Context, filter : Proc(Entitas::Entity, Bool)) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize instance.get_trigger(context)
        instance._filter = filter
        instance
      end

      def self.new(contexts : ::Contexts) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize instance.get_trigger(contexts)
        instance
      end
    end

    # Specify the collector that will trigger the ReactiveSystem.
    abstract def get_trigger(contexts : ::Contexts) : Array(Entitas::Collector)

    # This will exclude all entities which don't pass the filter.
    def filter(entity)
      self._filter.call(entity)
    end

    abstract def execute(entities : Array(Entitas::Entity))

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
          self.collected_buffer += collector.entities.to_a
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
