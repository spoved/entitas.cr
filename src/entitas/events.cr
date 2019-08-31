require "./macros"

module Entitas::Events
  create_event OnEntityAdded, {group: IGroup, entity: IEntity, index: Int32, component: Entitas::IComponent?}
  create_event OnEntityRemoved, {group: IGroup, entity: IEntity, index: Int32, component: Entitas::IComponent?}
  create_event OnEntityUpdated, {group: IGroup, entity: IEntity, index: Int32, prev_component: Entitas::IComponent?, new_component: Entitas::IComponent?}

  alias GroupChanged = OnEntityAdded.class | OnEntityRemoved.class | OnEntityUpdated.class | Nil

  enum GroupEvent
    Added
    Removed
    AddedOrRemoved
  end

  create_event OnEntityCreated, {context: IContext, entity: IEntity}
  create_event OnEntityWillBeDestroyed, {context: IContext, entity: IEntity}
  create_event OnEntityDestroyed, {context: IContext, entity: IEntity}
  create_event OnEntityReleased, {entity: IEntity}
  create_event OnEntityChanged, {entity: IEntity, index: Int32, component: Entitas::IComponent?}

  create_event OnComponentAdded, {entity: IEntity, index: Int32, component: Entitas::IComponent}
  create_event OnComponentRemoved, {entity: IEntity, index: Int32, component: Entitas::IComponent?}
  create_event OnComponentReplaced, {entity: IEntity, index: Int32, prev_component: Entitas::IComponent?, new_component: Entitas::IComponent?}

  create_event OnDestroyEntity, {entity: IEntity}

  create_event OnGroupCreated, {context: IContext, group: IGroup}

  struct TriggerOn
    getter matcher : Entitas::Matcher
    getter event : Entitas::Events::GroupEvent

    def initialize(@matcher, @event); end
  end
end
