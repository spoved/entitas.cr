require "../entitas"
require "./systems/reactive"

module Entitas
  # A `Entitas::ReactiveSystem` calls Execute(entities) if there were changes based on
  # the specified `Entitas::Collector` and will only pass in changed entities.
  # A common use-case is to react to changes, e.g. a change of the position
  # of an entity to update the gameObject.transform.position
  # of the related gameObject.
  abstract class ReactiveSystem
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    include Entitas::Systems::ReactiveSystem

    private getter collector : ICollector
    private property buffer : Array(Entitas::IEntity) = Array(Entitas::IEntity).new
    private property to_string_cache : String? = nil
    protected property _filter : Proc(Entitas::IEntity, Bool) = ->(entity : Entitas::IEntity) { true }

    def initialize(@collector : ICollector); end

    macro inherited
      def self.new(collector : Entitas::Collector, filter : Proc(Entitas::IEntity, Bool)) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize collector
        instance._filter = filter
        instance
      end

      def self.new(context : Entitas::Context, filter : Proc(Entitas::IEntity, Bool)) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize instance.get_trigger(context)
        instance._filter = filter
        instance
      end

      def self.new(context : Entitas::Context) : {{@type.id}}
        instance = {{@type.id}}.allocate
        instance.initialize instance.get_trigger(context)
        instance
      end
    end

    # Specify the collector that will trigger the ReactiveSystem.
    abstract def get_trigger(context : Entitas::Context) : ICollector

    # This will exclude all entities which don't pass the filter.
    def filter(entity)
      self._filter.call(entity)
    end

    abstract def execute(entities : Array(Entitas::IEntity))

    # Activates the `ReactiveSystem` and starts observing changes
    # based on the specified `Collector`.
    # `ReactiveSystem` are activated by default.
    def activate
      {% if !flag?(:disable_logging) %}logger.info("activating collector : #{self.collector}", self.to_s){% end %}
      self.collector.activate
    end

    # Deactivates the `ReactiveSystem`.
    # No changes will be tracked while deactivated.
    # This will also clear the `ReactiveSystem`.
    # `ReactiveSystem` are activated by default.
    def deactivate
      {% if !flag?(:disable_logging) %}logger.info("deactivating collector : #{self.collector}", self.to_s){% end %}
      self.collector.deactivate
    end

    # Clears all accumulated changes.
    def clear
      {% if !flag?(:disable_logging) %}logger.info("clearing collector : #{self.collector}", self.to_s){% end %}
      self.collector.clear
    end

    def execute : Nil
      {% if !flag?(:disable_logging) %}logger.info("running execute on collector : #{self.collector}", self.to_s){% end %}

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
      self.to_string_cache = "ReactiveSystem(#{self.class})" if self.to_string_cache.nil?
      io << self.to_string_cache
    end
  end
end
