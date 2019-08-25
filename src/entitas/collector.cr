require "./error"
require "./entity"

module Entitas
  # A Collector can observe one or more groups from the same context
  # and collects changed entities based on the specified groupEvent.
  class Collector
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    include Enumerable(Entitas::Entity)
    getter entities : Set(Entitas::Entity) = Set(Entitas::Entity).new

    protected property groups : Array(Entitas::Group) = Array(Entitas::Group).new
    protected property group_events : Array(Entitas::Events::GroupEvent) = Array(Entitas::Events::GroupEvent).new

    protected property to_string_cache : String?

    protected property add_entity_on_added_cache : Proc(Entitas::Events::OnEntityAdded, Nil)
    protected property add_entity_on_removed_cache : Proc(Entitas::Events::OnEntityRemoved, Nil)
    protected property add_entity_on_updated_cache : Proc(Entitas::Events::OnEntityUpdated, Nil)

    # Creates a Collector and will collect changed entities
    # based on the specified *group_event*.
    def initialize(group : Group, group_event : Entitas::Events::GroupEvent)
      @groups << group
      @group_events << group_event
      @add_entity_on_added_cache = ->add_entity(Entitas::Events::OnEntityAdded)
      @add_entity_on_removed_cache = ->add_entity(Entitas::Events::OnEntityRemoved)
      @add_entity_on_updated_cache = ->add_entity(Entitas::Events::OnEntityUpdated)
      activate
    end

    # Creates a Collector and will collect changed entities
    # based on the specified *group_events*.
    def self.new(groups : Array(Group), group_events : Array(Entitas::Events::GroupEvent))
      if groups.size != group_events.size
        raise Error.new "Unbalanced count with groups (#{groups.size})" \
                        " and group events (#{group_events.size}). " \
                        "Group and group events count must be equal."
      end

      instance = Collector.allocate
      instance.groups = groups
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
      {% if !flag?(:disable_logging) %}logger.info("activating collector with events : #{group_events}", self.to_s){% end %}

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
      {% if !flag?(:disable_logging) %}logger.info("deactivating collector", self.to_s){% end %}

      self.groups.each do |group|
        group.remove_on_entity_added_hook add_entity_on_added_cache
        group.remove_on_entity_removed_hook add_entity_on_removed_cache
      end

      self.clear
    end

    ############################
    # Enumerable funcs
    ############################

    # Returns the total number of `Entitas::Entity` in this `Collector`
    def size
      self.entities.size
    end

    def each
      self.entities.each do |entity|
        yield entity
      end
    end

    # Clears all collected entities
    def clear
      self.entities.each &.release(self)
      self.entities.clear
    end

    def empty?
      self.entities.empty?
    end

    ############################
    # Entity funcs
    ############################

    def add_entity(event : Entitas::Events::OnEntityAdded) : Nil
      {% if !flag?(:disable_logging) %}
        logger.debug("Processing OnEntityAdded : #{event.entity}", self.to_s)
      {% end %}
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    def add_entity(event : Entitas::Events::OnEntityRemoved) : Nil
      {% if !flag?(:disable_logging) %}
        logger.debug("Processing OnEntityRemoved : #{event.entity}", self.to_s)
      {% end %}
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    def add_entity(event : Entitas::Events::OnEntityUpdated) : Nil
      {% if !flag?(:disable_logging) %}
        logger.debug("Processing OnEntityUpdated : #{event.entity}", self.to_s)
      {% end %}
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    ############################
    # Misc funcs
    ############################

    def to_s(io)
      self.to_string_cache = "Collector(#{groups.join(", ")})" if self.to_string_cache.nil?
      io << self.to_string_cache
    end
  end
end
