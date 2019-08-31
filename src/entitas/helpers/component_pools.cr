require "../component"

module Entitas::Helper::ComponentPools
  ############################
  # ComponentPool functions
  ############################

  abstract def component_index_value(index) : Int32

  # component_pools is set by the context which created the entity and is used to reuse removed components.
  # Removed components will be pushed to the componentPool. Use entity.CreateComponent(index, type) to get
  # a new or reusable component from the componentPool. Use entity.GetComponentPool(index) to get a
  # componentPool for a specific component index.
  getter component_pools : Array(Entitas::ComponentPool)

  # Returns the `ComponentPool` for the specified component index.
  # `component_pools` is set by the context which created the entity and
  # is used to reuse removed components.
  # Removed components will be pushed to the componentPool.
  # Use entity.create_component(index, type) to get a new or
  # reusable component from the `ComponentPool`.
  def component_pool(index : Int32) : ComponentPool
    self.component_pools[index]
  end

  def component_pool(index : Entitas::Component::ComponentTypes) : ComponentPool
    self.component_pool(component_index_value(index))
  end

  # Clears the `ComponentPool` at the specified index.
  def clear_component_pool(index : Int32)
    component_pools[index].clear
  end

  def clear_component_pool(index : Entitas::Component::ComponentTypes)
    component_pool(component_index_value(index)).clear
  end

  # Clears all `ComponentPool`s.
  def clear_component_pools
    self.component_pools.each do |pool|
      pool.clear
    end
  end

  macro finished
    def component_pool(index : Entitas::Component::Index) : ComponentPool
      self.component_pool(component_index_value(index))
    end
  end
end
