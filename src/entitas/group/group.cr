require "../entity"
require "../component"

module Entitas
  abstract class Group
    @_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new

    abstract def handle_entity_silently(entity : Entitas::Entity)
    # void HandleEntity(TEntity entity, int index, IComponent component);
    abstract def handle_entity(entity : Entitas::Entity, index : Int32, component : Entitas::Component)
    # GroupChanged<TEntity> HandleEntity(TEntity entity);
    abstract def handle_entity(entity : Entitas::Entity)

    # void UpdateEntity(TEntity entity, int index, IComponent previousComponent, IComponent newComponent);
    abstract def update_entity(entity : Entitas::Entity, index : Int32, previous_component : Entitas::Component, new_component : Entitas::Component)

    # bool ContainsEntity(TEntity entity);
    abstract def contains_entity?(entity : Entitas::Entity) : Bool

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
  end
end
