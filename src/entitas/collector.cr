require "./interfaces/i_collector"
require "./error"
require "./entity"

module Entitas
  # A Collector can observe one or more groups from the same context
  # and collects changed entities based on the specified groupEvent.
  class Collector(TEntity)
    Log = ::Log.for(self)

    include ICollector

    protected property groups : Array(Group(TEntity)) = Array(Group(TEntity)).new
    protected property group_events : Array(Entitas::Events::GroupEvent) = Array(Entitas::Events::GroupEvent).new

    protected property to_string_cache : String?

    protected property add_entity_on_added_cache : Proc(Entitas::Events::OnEntityAdded, Nil)
    protected property add_entity_on_removed_cache : Proc(Entitas::Events::OnEntityRemoved, Nil)
    protected property add_entity_on_updated_cache : Proc(Entitas::Events::OnEntityUpdated, Nil)

    # Creates a Collector and will collect changed entities
    # based on the specified *group_event*.
    def initialize(group : Group(TEntity), group_event : Entitas::Events::GroupEvent)
      @groups << group
      @group_events << group_event
      @add_entity_on_added_cache = ->add_entity(Entitas::Events::OnEntityAdded)
      @add_entity_on_removed_cache = ->add_entity(Entitas::Events::OnEntityRemoved)
      @add_entity_on_updated_cache = ->add_entity(Entitas::Events::OnEntityUpdated)
      activate
    end

    # Creates a Collector and will collect changed entities
    # based on the specified *group_events*.
    def self.new(groups : Array(Group(TEntity)), group_events : Array(Entitas::Events::GroupEvent))
      if groups.size != group_events.size
        raise Error.new "Unbalanced count with groups (#{groups.size})" \
                        " and group events (#{group_events.size}). " \
                        "Group and group events count must be equal."
      end

      instance = Collector(TEntity).allocate
      instance.groups = groups.as(Array(Group(TEntity)))
      instance.group_events = group_events

      instance.add_entity_on_added_cache = ->instance.add_entity(Entitas::Events::OnEntityAdded)
      instance.add_entity_on_removed_cache = ->instance.add_entity(Entitas::Events::OnEntityRemoved)
      instance.add_entity_on_updated_cache = ->instance.add_entity(Entitas::Events::OnEntityUpdated)

      instance.activate
      instance
    end

    # Activates the Collector and will start collecting
    # changed entities. Collectors are activated by default.
    def activate
      {% if flag?(:entitas_enable_logging) %}Log.info { "activating collector with events : #{group_events}" }{% end %}

      groups.each_with_index do |group, i|
        case group_events[i]
        when Entitas::Events::GroupEvent::Added
          group.on_entity_added &add_entity_on_added_cache.as(Proc(Entitas::Events::OnEntityAdded, Nil))
        when Entitas::Events::GroupEvent::Removed
          group.on_entity_removed &add_entity_on_removed_cache.as(Proc(Entitas::Events::OnEntityRemoved, Nil))
        when Entitas::Events::GroupEvent::AddedOrRemoved
          group.on_entity_added &add_entity_on_added_cache.as(Proc(Entitas::Events::OnEntityAdded, Nil))
          group.on_entity_removed &add_entity_on_removed_cache.as(Proc(Entitas::Events::OnEntityRemoved, Nil))
        else
          raise Error.new "Unknown group event : #{group_events[i]}"
        end
      end
    end

    def deactivate
      {% if flag?(:entitas_enable_logging) %}Log.info { "deactivating collector" }{% end %}

      self.groups.each do |group|
        group.remove_on_entity_added_hook add_entity_on_added_cache
        group.remove_on_entity_removed_hook add_entity_on_removed_cache
      end

      self.clear
    end

    ############################
    # Enumerable funcs
    ############################

    # Returns the total number of `TEntity` in this `Collector`
    def size
      self.entities.size
    end

    def each(& : TEntity ->)
      self.entities.each do |entity|
        yield entity
      end
    end

    # Clears all collected entities
    def clear
      {% if flag?(:entitas_enable_logging) %}Log.info { "clearing collector" }{% end %}

      self.entities.each &.release(self)
      self.entities.clear
    end

    def empty?
      self.entities.empty?
    end

    ############################
    # Entity funcs
    ############################

    private def _add_entity(entity : TEntity)
      return if self.entities.includes?(entity)
      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "adding entity : #{entity}" }
      {% end %}
      entities << entity
      entity.retain(self)
    end

    def add_entity(event : Entitas::Events::OnEntityAdded) : Nil
      entity = event.entity.as(TEntity)

      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "Processing OnEntityAdded : #{entity}" }
      {% end %}
      _add_entity(entity)
    end

    def add_entity(event : Entitas::Events::OnEntityRemoved) : Nil
      entity = event.entity.as(TEntity)

      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "Processing OnEntityRemoved : #{entity}" }
      {% end %}

      _add_entity(entity)
    end

    def add_entity(event : Entitas::Events::OnEntityUpdated) : Nil
      entity = event.entity.as(TEntity)
      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "Processing OnEntityUpdated : #{entity}" }
      {% end %}
      _add_entity(entity)
    end

    ############################
    # Misc funcs
    ############################

    def to_s(io)
      self.to_string_cache = "#{self.class}(#{groups.join(", ")})" if self.to_string_cache.nil?
      io << self.to_string_cache
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field("name", self.to_s)
        json.field("groups", self.groups)
        json.field("group_events", self.group_events)
      end
    end
  end
end
