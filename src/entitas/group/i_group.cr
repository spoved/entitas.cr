require "../helpers/entities"
require "../matcher"

module Entitas::IGroup(TEntity)
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  include Entitas::Helper::Entities(TEntity)

  protected getter matcher : Entitas::Matcher

  abstract def remove_all_event_handlers

  abstract def handle_entity_silently(entity : TEntity)

  abstract def handle_entity(entity : TEntity) : Entitas::Events::GroupChanged
  abstract def handle_entity(entity : TEntity, index : Int32, component : Entitas::Component)

  abstract def update_entity(entity : TEntity, index : Int32, prev_component : Entitas::Component?, new_component : Entitas::Component?)

  abstract def get_entities(buff : Array(TEntity)) : Array(TEntity)
  abstract def get_single_entity : TEntity?

  accept_events OnEntityAdded, OnEntityRemoved, OnEntityUpdated
end
