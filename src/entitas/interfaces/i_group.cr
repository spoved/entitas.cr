require "../events"
require "../helpers/entities"
require "../matcher"

module Entitas::IGroup
  {% if flag?(:entitas_enable_logging) %}spoved_logger{% end %}

  include Entitas::Helper::Entities(IEntity)

  protected getter matcher : Entitas::Matcher

  abstract def remove_all_event_handlers

  abstract def handle_entity_silently(entity : IEntity)

  abstract def handle_entity(entity : IEntity) : Entitas::Events::GroupChanged
  abstract def handle_entity(entity : IEntity, index : Int32, component : Entitas::IComponent)

  abstract def update_entity(entity : IEntity, index : Int32, prev_component : Entitas::IComponent?, new_component : Entitas::IComponent?)

  abstract def get_entities(buff : Array(IEntity)) : Array(IEntity)
  abstract def get_single_entity : IEntity?

  accept_events OnEntityAdded, OnEntityRemoved, OnEntityUpdated
end
