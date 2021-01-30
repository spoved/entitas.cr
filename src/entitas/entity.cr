require "./error"
require "./interfaces/i_entity"
require "./events"
require "./helpers/*"
require "./entity/*"
require "./context/info"

module Entitas
  abstract class Entity
    include IEntity

    protected property components_cache : Array(Entitas::IComponent)? = nil
    protected property component_indices_cache : Array(Int32)? = nil
    protected property to_string_cache : String? = nil

    protected getter components : Array(Entitas::IComponent?)

    def initialize(
      @creation_index : Int32,
      @total_components : Int32,
      @component_pools : Array(ComponentPool),
      @context_info : Entitas::Context::Info? = nil,
      @aerc : SafeAERC? = nil
    )
      @components = Array(Entitas::IComponent?).new(@total_components, nil)
      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "Calling initialize: #{self.object_id}" }
      {% end %}

      reactivate(@creation_index)

      call_post_constructors
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "name", to_s
        json.field "creation_index", creation_index
        json.field "component_indices", get_component_indices
        json.field "components", components
        json.field "context_info", context_info
        json.field "retain_count", retain_count
      end
    end

    def init(creation_index ct_index : Int32 = 0,
             context_info ctx_info : Entitas::Context::Info? = nil,
             aerc _aerc : SafeAERC? = nil)
      {% if flag?(:entitas_enable_logging) %}Log.debug { "Calling init: #{self.object_id}" }{% end %}

      self.aerc = _aerc
      self.context_info = ctx_info
      @creation_index = ct_index

      self.reactivate(ct_index)
      self
    end

    ############################
    # State functions
    ############################

    # Re-enable the entity and set its creation index
    def reactivate(creation_index : Int32) : Entity
      {% if flag?(:entitas_enable_logging) %}Log.debug { "Reactivating Entity: #{self.object_id}" }{% end %}
      # Set our passed variables
      @creation_index = creation_index
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
      {% if flag?(:entitas_enable_logging) %}Log.info { "Starting to destroy entity: #{self}" }{% end %}

      if !self.enabled?
        raise Error::IsNotEnabled.new "Cannot destroy #{self}!"
      end

      emit_event OnDestroyEntity, self
    end

    # This method is used internally. Don't call it yourself. use `destroy`
    def internal_destroy!
      {% if flag?(:entitas_enable_logging) %}Log.info { "Destroying entity: #{self}" }{% end %}

      self.is_enabled = false
      self.remove_all_components!

      self.clear_on_component_added_event_hooks
      self.clear_on_component_removed_event_hooks
      self.clear_on_component_replaced_event_hooks
      self.clear_on_destroy_entity_event_hooks
    end

    ############################
    # AERC functions
    ############################

    # Automatic Entity Reference Counting (AERC)
    # is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def aerc : SafeAERC
      @aerc ||= SafeAERC.new(self)
    end

    # Returns the number of objects that retain this entity.
    def retain_count : Int32
      aerc.retain_count
    end

    # Retains the entity. An owner can only retain the same entity once.
    # Retain/Release is part of AERC (Automatic Entity Reference Counting)
    # and is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def retain(owner)
      {% if flag?(:entitas_enable_logging) %}
      Log.trace &.emit("Retaining entity", entity: self.to_s, entity_id: self.object_id.to_s,
        owner: owner.to_s, owner_id: owner.object_id.to_s)
      {% end %}
      aerc.retain(owner)
    end

    # Returns `Bool` if the `owner` retains this instance
    def retained_by?(owner)
      self.aerc.includes?(owner)
    end

    # Releases the entity. An owner can only release an entity
    # if it retains it.
    # Retain/Release is part of AERC (Automatic Entity Reference Counting)
    # and is used internally to prevent pooling retained entities.
    # If you use retain manually you also have to
    # release it manually at some point.
    def release(owner)
      {% if flag?(:entitas_enable_logging) %}
      Log.trace &.emit("Releasing entity", entity: self.to_s, entity_id: self.object_id.to_s,
        owner: owner.to_s, owner_id: owner.object_id.to_s)
      {% end %}

      aerc.release(owner)

      if self.retain_count.zero?
        emit_event OnEntityReleased, self
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
      {% if flag?(:entitas_enable_logging) %}Log.debug { "Clearing cache: #{cache}" }{% end %}

      case cache
      when :components
        self.components_cache = nil
      when :indicies
        self.component_indices_cache = nil
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
      Entitas::Context::Info.new(
        "No Context",
        Entitas::Component::COMPONENT_NAMES,
        Entitas::Component::COMPONENT_KLASSES
      )
    end

    ############################
    # Misc functions
    ############################

    def remove_all_on_entity_released_handlers
      self.on_entity_released_event_hooks.clear
    end

    def to_s(io)
      if @to_string_cache.nil?
        @to_string_cache = String::Builder.build do |builder|
          builder << self.class
          builder << "_#{self.creation_index}("
          builder << get_components.map { |c| c.class.to_s }.join(",")
          builder << ")"
        end
      end

      io << @to_string_cache.as(String)
    end
  end
end
