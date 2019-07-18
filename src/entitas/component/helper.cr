module Entitas::Component::Helper
  extend self

  # The total amount of components an entity can possibly have.
  def total_components : Int32
    Entitas::Component::TOTAL_COMPONENTS
  end

  # component_pools is set by the context which created the entity and
  # is used to reuse removed components.
  # Removed components will be pushed to the componentPool.
  # Use entity.CreateComponent(index, type) to get a new or
  # reusable component from the componentPool.
  # Use entity.GetComponentPool(index) to get a componentPool for
  # a specific component index.
  #
  def component_pools : Array(ComponentPool)
    ::Entitas::Component::POOLS
  end

  # Returns the `ComponentPool` for the specified component index.
  # `component_pools` is set by the context which created the entity and
  # is used to reuse removed components.
  # Removed components will be pushed to the componentPool.
  # Use entity.create_component(index, type) to get a new or
  # reusable component from the `ComponentPool`.
  def component_pool(index : Int32) : ComponentPool
    self.component_pools[index] = ComponentPool.new unless self.component_pools[index]?
    self.component_pools[index]
  end

  def component_pool(index : ::Entitas::Component::Index) : ComponentPool
    component_pool index.value
  end

  def klass_to_index(klass)
    COMPONENT_MAP[klass]
  end
end
