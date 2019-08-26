module Entitas::IContext(TEntity)
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  abstract def total_components : Int32
  abstract def component_index_value(klass) : Int32
  abstract def entity_factory : Entitas::Entity
  abstract def component_pools : Array(Entitas::ComponentPool)

  abstract def destroy_all_entities

  abstract def add_entity_index(entity_index : Entitas::IEntityIndex)
  abstract def get_entity_index(name : String) : Entitas::IEntityIndex

  abstract def reset_creation_index

  abstract def clear_component_pool(index : Int32)
  abstract def clear_component_pools

  abstract def remove_all_event_handlers
  abstract def reset

  abstract def create_entity : TEntity
  abstract def has_entity?(entity : TEntity) : Bool
  abstract def get_entities : Array(TEntity)

  abstract def size : Int32
  abstract def each(&block : TEntity -> Nil)

  abstract def get_group(matcher : Entitas::Matcher) : Entitas::Group

  accept_events OnEntityCreated, OnEntityWillBeDestroyed, OnEntityDestroyed, OnGroupCreated
end
