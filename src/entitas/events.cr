require "./macros"

module ::Entitas::Events
  create_event OnEntityAdded, {group: Group, entity: Entity, index: Int32, new_component: Entitas::Component?}
  create_event OnEntityRemoved, {group: Group, entity: Entity, index: Int32, prev_component: Entitas::Component?}
  create_event OnEntityUpdated, {group: Group, entity: Entity, index: Int32, prev_component: Entitas::Component?, new_component: Entitas::Component?}

  create_event OnEntityCreated, {context: Context, entity: Entity}
  create_event OnEntityWillBeDestroyed, {context: Context, entity: Entity}
  create_event OnEntityDestroyed, {context: Context, entity: Entity}
  create_event OnEntityReleased, {entity: Entity}
  create_event OnEntityChanged, {entity: Entity, index: Int32, component: Entitas::Component?}

  create_event OnComponentAdded, {entity: Entity, index: Int32, component: Entitas::Component}
  create_event OnComponentRemoved, {entity: Entity, index: Int32, component: Entitas::Component?}
  create_event OnComponentReplaced, {entity: Entity, index: Int32, prev_component: Entitas::Component?, new_component: Entitas::Component?}

  create_event OnDestroyEntity, {entity: Entity}

  create_event OnGroupCreated, {context: Context, entity: Entity}
end
