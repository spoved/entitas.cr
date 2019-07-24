require "spoved/logger"
require "./events"
require "./group/*"

module Entitas
  abstract class Group
    spoved_logger

    accept_events OnEntityAdded, OnEntityRemoved, OnEntityUpdated

    include Enumerable(Entitas::Entity)

    getter entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    protected property entities_cache : Array(Entitas::Entity) = Array(Entitas::Entity).new
    protected property single_entitie_cache : Entitas::Entity?
    protected property to_string_cache : String?

    protected getter matcher : Entitas::Matcher(T)

    def contains_entity?(entity : Entitas::Entity) : Bool
      self.entities.includes?(entity)
    end

    def initialize(@matcher : Entitas::Matcher(T))
    end

    # This is used by the context to manage the group.
    def handle_entity_silently(entity : Entity)
      if self.matcher.matches?(entity)
        add_entity_silently(entity)
      else
        remove_entity_silently(entity)
      end
    end

    # This is used by the context to manage the group.
    def handle_entity(entity : Entity, index : Int32, component : Entitas::Component)
      if self.matcher.matches?(entity)
        add_entity(entity, index, component)
      else
        remove_entity(entity, index, component)
      end
    end

    # This is used by the context to manage the group.
    def update_entity(entity : Entity, index : Int32, prev_component : Entitas::Component, new_component : Entitas::Component)
      if has_entity?(entity)
        emit OnEntityRemoved, self, entity, index, prev_component
        emit OnEntityAdded, self, entity, index, new_component
        emit OnEntityUpdated, self, entity, index, prev_component, new_component
      end
    end

    # Removes all event handlers from this group.
    # Keep in mind that this will break reactive systems and
    # entity indices which rely on this group.
    #
    # Removes: `OnEntityRemoved`, `OnEntityAdded`, and `OnEntityUpdated`
    def remove_all_event_handlers
      self.clear_on_entity_removed_event_hooks
      self.clear_on_entity_added_event_hooks
      self.clear_on_entity_updated_event_hooks
    end

    def handle_entity(entity : Entity)
      if self.matcher.matches?(entity)
        add_entity_silently(entity) # ? OnEntityAdded : null
      else
        remove_entity_silently(entity) # ? OnEntityRemoved : null
      end
    end

    def add_entity_silently(entity : Entity) : Entity | Bool
      if entity.enabled?
        entities << entity
        self.entities_cache = nil
        self.single_entitie_cache = nil
        entity.retain(self)
        return entity
      end
      false
    end

    def add_entity(entity : Entity, index : Int32, component : Component)
      if add_entity_silently(entity)
        emit OnEntityAdded, self, entity, index, new_component
      end
    end

    def remove_entity_silently(entity : Entity) : Entity
      removed = self.entities.delete(entity)
      if removed
        self.entities_cache = nil
        self.single_entitie_cache = nil
        entity.release(self)
      end
      removed
    end

    def remove_entity(entity : Entity, index : Int32, component : Component) : Entity
      removed = self.entities.delete(entity)
      if removed
        self.entities_cache = nil
        self.single_entitie_cache = nil
        emit OnEntityRemoved, self, entity, index, prev_component
        entity.release(self)
      end
      removed
    end

    # Determines whether this group has the specified entity.
    def contains_entity?(entity : Entity) : Bool
      has_entity?(entity)
    end

    # Determines whether this group has the specified entity.
    def has_entity?(entity : Entity) : Bool
      self.entities.includes?(entity)
    end

    # Returns all entities which are currently in this group.
    # TODO: Do we need buffer?
    def get_entities : Array(Entitas::Entity)
      if entities_cache.nil?
        self.entities_cache = self.entities.dup
      end
      self.entities
    end

    # Returns the only entity in this group. It will return null
    # if the group is empty. It will throw an exception if the group
    # has more than one entity.
    def get_single_entity : Entitas::Entity?
      if single_entitie_cache.nil?
        if size == 1
          self.entities_cache = entities.first
        elsif size == 0
          return nil
        else
          raise Entitas::Group::Error::SingleEntity.new
        end
      end

      single_entitie_cache
    end

    # Enumerable funcs

    # Returns the total number of `Entitas::Entity` in this `Group`
    def size
      self.entities.size
    end

    def each
      self.entities.each do |entity|
        yield entity
      end
    end

    # Misc funcs

    def to_s
      if to_string_cache.nil?
        self.to_string_cache = "Group( )"
      end
      to_string_cache
    end
  end
end
