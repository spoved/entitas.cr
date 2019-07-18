require "./component"
require "./entity/*"
require "./aerc"
require "./context/info"
require "./aliases"

module Entitas
  class Entity
    class Error < Exception
    end

    include Entitas::Entity::Events

    # Each entity has its own unique `creation_index` which will be set by
    # the context when you create the entity.
    getter creation_index : Int32 = -1
    protected setter creation_index

    protected setter context_info : Entitas::Context::Info? = nil
    protected setter aerc : AERC? = nil

    # The context manages the state of an entity.
    # Active entities are enabled, destroyed entities are not.
    protected property is_enabled : Bool = false

    protected property components_cache = Array(Entitas::Component).new
    protected property component_indices_cache = Array(Int32).new
    protected property to_string_cache : String? = nil

    protected getter components = Array(Entitas::Component?).new(::Entitas::Component::TOTAL_COMPONENTS, nil)

    def initialize(
      @creation_index : Int32 = 0,
      @context_info : Entitas::Context::Info? = nil,
      @aerc : SafeAERC? = nil
    )
      reactivate(@creation_index)
    end

    def init(creation_index ct_index : Int32 = 0,
             context_info ctx_info : Entitas::Context::Info? = nil,
             aerc _aerc : SafeAERC? = nil)
      self.aerc = _aerc
      self.context_info = ctx_info
      self.creation_index = ct_index

      # Clear caches
      self.clear_caches!

      self.reactivate(ct_index)
      self
    end

    ############################
    # State functions
    ############################

    # The context manages the state of an entity.
    # Active entities are enabled, destroyed entities are not.
    def enabled?
      self.is_enabled
    end

    # Re-enable the entity and set its creation index
    def reactivate(creation_index : Int32) : Entity
      # Set our passed variables
      self.creation_index = creation_index
      self.is_enabled = true

      # Clear caches
      self.clear_caches!
      self
    end

    # Re-enable the entity and set its creation index
    def reactivate(creation_index : Int32, context_info : Entitas::Context::Info) : Entity
      self.context_info = context_info
      reactivate(creation_index)
    end

    # Dispatches `OnDestroyEntity` which will start the destroy process.
    def destroy : Nil
      self.destroy!
    end

    def destroy! : Nil
      if !self.enabled?
        raise Error::IsNotEnabled.new "Cannot destroy #{self}!"
      end

      emit_event OnDestroyEntity.new(self)
    end

    # This method is used internally. Don't call it yourself. use `destroy`
    def _destroy!
      self.is_enabled = false
      self.remove_all_components!
    end

    ############################
    # AERC functions
    ############################

    # Automatic Entity Reference Counting (AERC)
    # is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def aerc : AERC
      @aerc ||= SafeAERC.new(self)
    end

    # Returns the number of objects that retain this entity.
    def retain_count
      aerc.retain_count
    end

    # Retains the entity. An owner can only retain the same entity once.
    # Retain/Release is part of AERC (Automatic Entity Reference Counting)
    # and is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def retain(owner)
      aerc.retain(owner)
    end

    # Releases the entity. An owner can only release an entity
    # if it retains it.
    # Retain/Release is part of AERC (Automatic Entity Reference Counting)
    # and is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def release(owner)
      aerc.release(owner)

      if self.retain_count.zero?
        emit_event OnEntityReleased.new(self)
      end
    end

    ############################
    # Context functions
    ############################

    # The `context_info` is set by the context which created the entity and
    # contains information about the context.
    # It's used to provide better error messages.
    def context_info : Entitas::Context::Info
      @context_info ||= self.create_default_context_info
    end

    ############################
    # Cache control functions
    ############################

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
        self.components_cache = Array(Entitas::Component).new
      when :indicies
        self.component_indices_cache = Array(Int32).new
      when :strings
        self.to_string_cache = nil
      else
        raise Error.new "Unknown cache: #{cache} to clear"
      end
    end

    # Will clear all the caches by default. Pass the corresponding `true`/`false` options to
    # enable/disable clearing of specific ones
    private def clear_caches!(clear_components = true, clear_indices = true, clear_strings = true)
      clear_cache(:components) if clear_components
      clear_cache(:indicies) if clear_indices
      clear_cache(:strings) if clear_strings
    end

    # This will create a default `Entitas::Context::Info`
    private def create_default_context_info : Entitas::Context::Info
      component_names = Array(String).new
      0..Entitas::Component::TOTAL_COMPONENTS.times do |i|
        component_names << "Index #{i}"
      end

      Entitas::Context::Info.new("No Context", component_names, nil)
    end

    ############################
    # Misc functions
    ############################

    def to_s
      if self.to_string_cache.nil?
        self.to_string_cache = String::Builder.build do |builder|
          builder << "Entity_#{self.creation_index}("
          builder << get_components.map { |c| c.class.to_s }.join(",")
          builder << ")"
        end
      end

      self.to_string_cache
    end
  end
end
