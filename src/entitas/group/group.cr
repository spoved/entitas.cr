require "../entity"
require "../component"

module Entitas
  abstract class Group
    include Enumerable(Entitas::Entity)

    @_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    @_entities_cache : Array(Entitas::Entity) = Array(Entitas::Entity).new
    @_single_entitie_cache : Entitas::Entity | Nil
    @_to_string_cache : String | Nil

    def contains_entity?(entity : Entitas::Entity) : Bool
      @_entities.includes?(entity)
    end

    def initialize(@_matcher : Entitas::Matcher)
    end

    # This is used by the context to manage the group.
    def handle_entity_silently(entity : Entity)
      if @_matcher.matches?(entity)
        add_entity_silently(entity)
      else
        remove_entity_silently(entity)
      end
    end

    def add_entity_silently(entity : Entity)
    end

    def remove_entity_silently(entity : Entity)
    end

    # This is used by the context to manage the group.
    def handle_entity(entity : Entity, index : Int32, component : Entitas::Component)
      if @_matcher.matches(entity)
        add_entity(entity, index, component)
      else
        remove_entity(entity, index, component)
      end
    end

    def add_entity(entity : Entity)
    end

    def remove_entity(entity : Entity)
    end

    # This is used by the context to manage the group.
    def update_entity(entity : Entity, index : Int32, previous_component : Entitas::Component, new_component : Entitas::Component)
      if @_entities.includes?(entity)
        # if (OnEntityRemoved != null) {
        #     OnEntityRemoved(this, entity, index, previousComponent);
        # }
        # if (OnEntityAdded != null) {
        #     OnEntityAdded(this, entity, index, newComponent);
        # }
        # if (OnEntityUpdated != null) {
        #     OnEntityUpdated(
        #         this, entity, index, previousComponent, newComponent
        #     );
        # }
      end
    end

    def get_entities : Array(Entitas::Entity)
      @_entities
    end

    def get_single_entity : Entitas::Entity
      @_entities.first
    end

    # Returns the total number of `Entitas::Entity` in this `Group`
    def size
      @_entities.size
    end

    def each
      @_entities.each do |entity|
        yield entity
      end
    end
  end
end
