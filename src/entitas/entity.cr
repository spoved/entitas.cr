require "./component"
require "./entity/*"
require "./stack"

module Entitas
  class Entity
    class Error < Exception
    end

    include Entitas::Entity::Index

    # Each entity has its own unique `creation_index` which will be set by
    # the context when you create the entity.
    @_creation_index : Int32 = -1

    # The context manages the state of an entity.
    # Active entities are enabled, destroyed entities are not.
    @_is_enabled : Bool = false

    @_components : Array(Entitas::Component?) = Array(Entitas::Component?).new(Entitas::Component::TOTAL_COMPONENTS, nil)

    # componentPools is set by the context which created the entity and
    # is used to reuse removed components.
    # Removed components will be pushed to the componentPool.
    # Use entity.CreateComponent(index, type) to get a new or
    # reusable component from the componentPool.
    # Use entity.GetComponentPool(index) to get a componentPool for
    # a specific component index.
    # @_component_pools : Stack(Entitas::Component)

    @_components_cache : Array(Entitas::Component) = Array(Entitas::Component).new
    @_component_indices_cache : Array(Int32) = Array(Int32).new
    @_to_string_cache : Array(String) = Array(String).new

    # @_to_string_builder : String::Builder

    def initialize(
      creation_index : Int32? = nil,
      context_info : Entitas::Context::Info? = nil
    )
      if context_info.nil?
        @_context_info = create_default_context_info
      else
        @_context_info = context_info.as(Entitas::Context::Info)
      end

      # Clear caches
      self.clear_caches!

      # only set creation_index if we passed it
      reactivate(creation_index) unless creation_index.nil?

      # @_component_pools = component_pools
    end

    # Re-enable the entity and set its creation index
    def reactivate(creation_index)
      # Set our passed variables
      @_creation_index = creation_index
      @_is_enabled = true
    end

    # The total amount of components an entity can possibly have.
    def self.total_components : Int32
      Entitas::Component::TOTAL_COMPONENTS
    end

    # The total amount of components an entity can possibly have.
    def total_components : Int32
      Entitas::Component::TOTAL_COMPONENTS
    end

    # Each entity has its own unique creationIndex which will be set by
    # the context when you create the entity.
    def creation_index : Int32
      @_creation_index
    end

    # The context manages the state of an entity.
    # Active entities are enabled, destroyed entities are not.
    def enabled?
      @_is_enabled
    end

    # TODO: implement component_pools
    # componentPools is set by the context which created the entity and
    # is used to reuse removed components.
    # Removed components will be pushed to the componentPool.
    # Use entity.CreateComponent(index, type) to get a new or
    # reusable component from the componentPool.
    # Use entity.GetComponentPool(index) to get a componentPool for
    # a specific component index.
    #
    # def component_pools : Array(Stack(Entitas::Component))
    # end

    # TODO: impliment context_info
    # The contextInfo is set by the context which created the entity and
    # contains information about the context.
    # It's used to provide better error messages.
    #
    # def context_info : Context::Info
    # end

    # TODO: Implement AERC?

    # Will add the `Entitas::Component` at the provided index.
    # You can only have one component at an index.
    # Each component type must have its own constant index.
    def add_component(index : Int32, component : Entitas::Component)
      if !enabled?
        raise EntityIsNotEnabledException.new "Cannot add component " \
                                              "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if has_component?(index)
        raise EntityAlreadyHasComponentException.new "Cannot add component " \
                                                     "'#{self.context_info.component_names[index]}' to #{self}! " \
                                                     "You should check if an entity already has the component " \
                                                     "before adding it or use entity.replace_component()."
      end

      self.components[index] = component
      self.clear_caches!

      # TODO: trigger OnComponentAdded event with (self, index, component)
    end

    def add_component(index : ::Entitas::Component::Index, component : Entitas::Component)
      add_component(index.value, component)
    end

    # Removes a component at the specified index.
    # You can only remove a component at an index if it exists.
    def remove_component(index : Int32) : Nil
      if !enabled?
        raise EntityIsNotEnabledException.new "Cannot remove component " \
                                              "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if !has_component?(index)
        raise EntityDoesNotHaveComponentException.new "Cannot remove component " \
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
    def replace_component(index : Int32, component : Entitas::Component)
      if !enabled?
        raise EntityIsNotEnabledException.new "Cannot replace component " \
                                              "'#{self.context_info.component_names[index]}' from #{self}!"
      end

      if has_component?(index)
        self._replace_component(index, component)
      else
        self.add_component(index, component)
      end
    end

    def replace_component(index : ::Entitas::Component::Index, component : Entitas::Component)
      replace_component index.value
    end

    # Will return the `Entitas::Component` at the provided index.
    # You can only get a component at an index if it exists.
    def get_component(index : Int32) : Entitas::Component
      if has_component?(index)
        self.components[index].as(Entitas::Component)
      else
        raise EntityDoesNotHaveComponentException.new "Cannot get component " \
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
      if @_components_cache.empty?
        @_components_cache = self.components.reject(Nil)
      end
      @_components_cache
    end

    # Returns all indices of added components.
    def get_component_indices : Array(Int32)
      if @_component_indices_cache.empty?
        @_component_indices_cache = self.components.each_index { |c, i| c.nil? ? nil : i }.reject(Nil)
      end
      @_component_indices_cache
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
      self.components.each_index do |_, i|
        self._replace_component(i, nil)
      end
      # TODO: Do we need to clear_caches! ?
    end

    # Dispatches OnDestroyEntity which will start the destroy process.
    def destroy : Nil
      if !self.enabled?
        raise EntityIsNotEnabledException.new "Cannot destroy #{self}!"
      end

      # TODO: Call OnDestroyEntity event with (self)
    end

    # This method is used internally. Don't call it yourself. use `destroy`
    def destroy!
      @_is_enabled = false
      self.remove_all_components!
    end

    private def _replace_component(index : Int32, replacement : Entitas::Component?) : Nil
      prev_component = self.components[index]

      if prev_component != replacement
        self.components[index] = replacement
        self.clear_cache :components

        if replacement.nil?
          # TODO: trigger OnComponentReplaced event with (self, index, previousComponent, replacement)
        else
          self.clear_cache(:indicies)
          self.clear_cache(:strings)
          # TODO: trigger OnComponentRemoved event with (self, index, previousComponent)
        end

        # TODO: GetComponentPool(index).Push(previousComponent);
      else
        # TODO: trigger OnComponentReplaced event with (self, index, previousComponent, replacement)
      end
    end

    # Returns the entities array of `Entitas::Component`
    private def components
      @_components
    end

    # The `context_info` is set by the context which created the entity and
    # contains information about the context.
    # It's used to provide better error messages.
    private def context_info : Entitas::Context::Info
      @_context_info
    end

    # Clears a single cache specified by *cache*.
    # can be `:components`, `:indicies`, or `:strings`
    #
    # ```
    # @_components_cache.size # => 2
    # clear_cache(:components)
    # @_components_cache.size # => 0
    # ```
    private def clear_cache(cache : Symbol)
      case cache
      when :components
        @_components_cache.clear
      when :indicies
        @_component_indices_cache.clear
      when :strings
        @_to_string_cache.clear
      else
        raise Error.new "Unknown cache: #{cache} to clear"
      end
    end

    # Will clear all the caches by default. Pass the corresponding `true`/`false` options to
    # enable/disable clearing of specific ones
    private def clear_caches!(clear_components = true, clear_indices = true, clear_strings = true)
      @_components_cache.clear if clear_components
      @_component_indices_cache.clear if clear_indices
      @_to_string_cache.clear if clear_strings
    end

    # This will create a default `Entitas::Context::Info`
    private def create_default_context_info : Entitas::Context::Info
      component_names = Array(String).new
      0..Entitas::Component::TOTAL_COMPONENTS.times do |i|
        component_names << i.to_s
      end

      Entitas::Context::Info.new("No Context", component_names, nil)
    end
  end
end
