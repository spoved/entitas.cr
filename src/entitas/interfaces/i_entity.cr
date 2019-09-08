require "../events"
require "../context/info"

module Entitas::IEntity
  {% if flag?(:entitas_enable_logging) %}spoved_logger{% end %}

  # The context manages the state of an entity.
  # Active entities are enabled, destroyed entities are not.
  protected property is_enabled : Bool = false

  # The context manages the state of an entity.
  # Active entities are enabled, destroyed entities are not.
  def enabled?
    self.is_enabled
  end

  # The total amount of components an entity can possibly have.
  getter total_components : Int32
  getter creation_index : Int32

  protected setter context_info : Entitas::Context::Info? = nil

  abstract def context_info : Entitas::Context::Info

  protected setter aerc : SafeAERC? = nil

  abstract def aerc : AERC
  abstract def retain_count : Int32
  abstract def retained_by?(owner)
  abstract def release(owner)

  abstract def reactivate(creation_index : Int32)
  abstract def reactivate(creation_index : Int32, context_info : Entitas::Context::Info)

  abstract def component_index(index) : Entitas::Component::Index
  abstract def component_index_value(index) : Int32
  abstract def component_index_class(index) : Entitas::Component::ComponentTypes

  abstract def component_pools : Array(Entitas::ComponentPool)

  def create_component(_type : Entitas::Component::ComponentTypes, **args)
    self.create_component(_type.index, **args)
  end

  abstract def add_component(index : Int32, component : Entitas::IComponent)

  def add_component(index : Entitas::Component::Index, component : Entitas::IComponent) : Entitas::IComponent
    self.add_component(self.component_index_value(index), component)
  end

  def add_component(component : Entitas::IComponent) : Entitas::IComponent
    self.add_component(self.component_index_value(component.class), component)
  end

  abstract def remove_component(index : Int32)

  def remove_component(index : Entitas::Component::Index) : Nil
    self.remove_component(self.component_index_value(index))
  end

  abstract def create_component(index : Entitas::Component::Index, **args)

  abstract def replace_component(index : Int32, component : Entitas::IComponent?)

  def replace_component(index : Entitas::Component::Index, component : Entitas::IComponent?)
    self.replace_component(self.component_index_value(index), component)
  end

  def replace_component(component : Entitas::IComponent?)
    self.replace_component(self.component_index_value(component.class), component)
  end

  # Will return the `Entitas::Component` at the provided index.
  # You can only get a component at an index if it exists.
  abstract def get_component(index : Int32)

  def get_component(index : Entitas::Component::Index) : Entitas::IComponent
    self.get_component(self.component_index_value(index))
  end

  abstract def get_components : Enumerable(Entitas::IComponent)

  # Returns all indices of added components.
  abstract def get_component_indices : Enumerable(Int32)

  # Determines whether this entity has a component
  # at the specified index.
  abstract def has_component?(index : Int32) : Bool

  def has_component?(index : Entitas::Component::Index) : Bool
    self.has_component?(self.component_index_value(index))
  end

  # Determines whether this entity has components
  # at all the specified indices.
  abstract def has_components?(indices : Enumerable(Int32)) : Bool

  # Determines whether this entity has a component
  # at any of the specified indices.
  abstract def has_any_component?(indices : Enumerable(Int32)) : Bool

  # Removes all components.
  abstract def remove_all_components! : Nil

  abstract def destroy! : Nil

  # This method is used internally. Don't call it yourself. use `destroy`
  abstract def internal_destroy!

  abstract def remove_all_on_entity_released_handlers

  accept_events OnEntityWillBeDestroyed, OnComponentAdded, OnComponentReplaced,
    OnComponentRemoved, OnEntityReleased, OnEntityCreated, OnEntityDestroyed,
    OnDestroyEntity, OnGroupCreated
end
