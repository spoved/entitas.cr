require "../component/helper"

module Entitas
  class Entity
    ############################
    # Component functions
    ############################

    include Entitas::Component::Helper

    def create_component(index : ::Entitas::Component::Index, **args)
      pool = component_pool(index)
      # FIXME: This should also clear the component
      pool.empty? ? ::Entitas::Component::INDEX_MAP[index].new : pool.pop.init
    end

    def create_component(_type, **args)
      create_component(::Entitas::Component::COMPONENT_MAP[_type], **args)
    end

    # Will add the `Entitas::Component` at the provided index.
    # You can only have one component at an index.
    # Each component type must have its own constant index.
    def add_component(index : Int32, component : Entitas::Component)
      if !enabled?
        raise Error::IsNotEnabled.new "Cannot add component " \
                                      "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if has_component?(index)
        raise Error::AlreadyHasComponent.new "Cannot add component " \
                                             "'#{self.context_info.component_names[index]}' to #{self}! " \
                                             "You should check if an entity already has the component " \
                                             "before adding it or use entity.replace_component()."
      end

      self.components[index] = component
      self.clear_caches!

      emit_event OnComponentAdded.new(self, index, component)

      component
    end

    def add_component(index : ::Entitas::Component::Index, component : Entitas::Component)
      add_component(index.value, component)
    end

    def add_component(component : Entitas::Component)
      add_component(::Entitas::Component::COMPONENT_MAP[component.class], component)
    end

    # Removes a component at the specified index.
    # You can only remove a component at an index if it exists.
    def remove_component(index : Int32) : Nil
      if !enabled?
        raise Error::IsNotEnabled.new "Cannot remove component " \
                                      "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if !has_component?(index)
        raise Error::DoesNotHaveComponent.new "Cannot remove component " \
                                              "'#{self.context_info.component_names[index]}' from #{self}! " \
                                              "You should check if an entity has the component " \
                                              "before removing it."
      end

      self._replace_component(index, nil)
    end

    def remove_component(index : ::Entitas::Component::Index) : Nil
      remove_component(index.value)
    end

    # Replaces an existing component at the specified index
    # or adds it if it doesn't exist yet.
    def replace_component(index : Int32, component : Entitas::Component?)
      if !enabled?
        raise Error::IsNotEnabled.new "Cannot replace component " \
                                      "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if has_component?(index)
        self._replace_component(index, component)
      elsif component.is_a? Entitas::Component
        self.add_component(index, component)
      end
    end

    def replace_component(index : ::Entitas::Component::Index, component : Entitas::Component?)
      replace_component index.value, component
    end

    def replace_component(component : Entitas::Component?)
      replace_component(::Entitas::Component::COMPONENT_MAP[component.class].value, component)
    end

    # Will return the `Entitas::Component` at the provided index.
    # You can only get a component at an index if it exists.
    def get_component(index : Int32) : Entitas::Component
      if has_component?(index)
        self.components[index].as(Entitas::Component)
      else
        raise Error::DoesNotHaveComponent.new "Cannot get component " \
                                              "'#{self.context_info.component_names[index]}' from #{self}!" \
                                              "You should check if an entity has the component " \
                                              "before getting it."
      end
    end

    def get_component(index : ::Entitas::Component::Index) : Entitas::Component
      get_component(index.value)
    end

    # Returns all added components.
    def get_components : Array(Entitas::Component)
      # if the cache is empty, repopulate it
      if components_cache.empty?
        self.components_cache = self.components.reject(Nil)
      end
      components_cache
    end

    # Returns all indices of added components.
    def get_component_indices : Array(Int32)
      if component_indices_cache.empty?
        self.component_indices_cache = self.components.map_with_index { |c, i| c.nil? ? nil : i }.reject(Nil)
      end
      component_indices_cache
    end

    # Determines whether this entity has a component
    # at the specified index.
    def has_component?(index : Int32) : Bool
      (self.components[index]? && !self.components[index].nil?) ? true : false
    end

    def has_component?(index : ::Entitas::Component::Index) : Bool
      has_component? index.value
    end

    # Determines whether this entity has components
    # at all the specified indices.
    def has_components?(indices : Array(Int32)) : Bool
      indices.each do |index|
        return false unless self.has_component?(index)
      end
      true
    end

    def has_components?(indices : Array(::Entitas::Component::Index)) : Bool
      has_components? indices.map &.value
    end

    # Determines whether this entity has a component
    # at any of the specified indices.
    def has_any_component?(indices : Array(Int32)) : Bool
      indices.each do |index|
        return true if self.has_component?(index)
      end
      false
    end

    def has_any_component?(indices : Array(::Entitas::Component::Index)) : Bool
      has_any_component? indices.map &.value
    end

    # Removes all components.
    def remove_all_components! : Nil
      self.components.each_index do |i|
        self._replace_component(i, nil)
      end
    end

    private def _replace_component(index : Int32, replacement : Entitas::Component?) : Nil
      prev_component = self.components[index]

      if prev_component != replacement
        self.components[index] = replacement
        self.clear_cache :components

        if !replacement.nil?
          emit_event OnComponentReplaced.new(self, index, prev_component, replacement)
        else
          self.clear_cache(:indicies)
          self.clear_cache(:strings)
          emit_event OnComponentRemoved.new(self, index, prev_component)
        end

        component_pool(index) << prev_component unless prev_component.nil?
      else
        emit_event OnComponentReplaced.new(self, index, prev_component, replacement)
      end
    end
  end
end
