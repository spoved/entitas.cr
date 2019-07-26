require "./entity"

module Entitas
  # A Collector can observe one or more groups from the same context
  # and collects changed entities based on the specified groupEvent.
  class Collector
    class Error < Exception; end

    spoved_logger

    include Enumerable(Entitas::Entity)
    getter entities : Array(Entitas::Entity) = Array(Entitas::Entity).new

    protected property groups : Array(Group) = Array(Group).new
    protected property group_events : Array(Events::GroupEvent) = Array(Events::GroupEvent).new

    protected property to_string_cache : String?

    protected property add_entity_on_added_cache : Proc(Events::OnEntityAdded, Nil)
    protected property add_entity_on_removed_cache : Proc(Events::OnEntityRemoved, Nil)
    protected property add_entity_on_updated_cache : Proc(Events::OnEntityUpdated, Nil)

    # Creates a Collector and will collect changed entities
    # based on the specified *group_event*.
    def initialize(group : Group, group_event : Events::GroupEvent)
      @groups << group
      @group_events << group_event
      @add_entity_on_added_cache = ->add_entity(Events::OnEntityAdded)
      @add_entity_on_removed_cache = ->add_entity(Events::OnEntityRemoved)
      @add_entity_on_updated_cache = ->add_entity(Events::OnEntityUpdated)
      activate
    end

    # Creates a Collector and will collect changed entities
    # based on the specified *group_events*.
    def self.new(groups : Array(Group), group_events : Array(Events::GroupEvent))
      if groups.size != group_events.size
        raise Error.new "Unbalanced count with groups (#{groups.size})" \
                        " and group events (#{group_events.size}). " \
                        "Group and group events count must be equal."
      end

      instance = Collector.allocate
      instance.groups = groups
      instance.group_events = group_events

      instance.add_entity_on_added_cache = ->instance.add_entity(Events::OnEntityAdded)
      instance.add_entity_on_removed_cache = ->instance.add_entity(Events::OnEntityRemoved)
      instance.add_entity_on_updated_cache = ->instance.add_entity(Events::OnEntityUpdated)

      instance.activate
      instance
    end

    # Activates the Collector and will start collecting
    # changed entities. Collectors are activated by default.
    def activate
      logger.info "activating collector", self.to_s

      groups.each_with_index do |group, i|
        case group_events[i]
        when Events::OnEntityAdded.class
          group.on_entity_added &add_entity_on_added_cache.as(Proc(Events::OnEntityAdded, Nil))
        when Events::OnEntityRemoved.class
          group.on_entity_removed &add_entity_on_removed_cache.as(Proc(Events::OnEntityRemoved, Nil))
        when Events::OnEntityUpdated.class
          group.on_entity_added &add_entity_on_added_cache.as(Proc(Events::OnEntityAdded, Nil))
          group.on_entity_updated &add_entity_on_updated_cache.as(Proc(Events::OnEntityUpdated, Nil))
        else
          raise Error.new "Unknown group event : #{group_events[i]}"
        end
      end
    end

    def deactivate
      logger.info "deactivating collector", self.to_s
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

    ############################
    # Entity funcs
    ############################

    def add_entity(event : Entitas::Events::OnEntityAdded)
      logger.debug("Processing OnEntityAdded : #{event.entity}", self.to_s)
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    def add_entity(event : Entitas::Events::OnEntityRemoved)
      logger.debug("Processing OnEntityRemoved : #{event.entity}", self.to_s)
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    def add_entity(event : Entitas::Events::OnEntityUpdated)
      logger.debug("Processing OnEntityUpdated : #{event.entity}", self.to_s)
      return if self.entities.includes?(event.entity)

      entities << event.entity
      event.entity.retain(self)
    end

    ############################
    # Misc funcs
    ############################

    def to_s(io)
      io << self.to_s
    end

    def to_s
      if to_string_cache.nil?
        self.to_string_cache = "Collector(#{groups.join(", ")})"
      end
      to_string_cache
    end
  end
end
