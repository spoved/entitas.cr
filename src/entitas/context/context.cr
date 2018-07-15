require "../../stack"
require "../component"
require "../entity/index"
require "../entity/aerc"
require "./info"

module Entitas
  # A context manages the lifecycle of entities and groups.
  #  You can create and destroy entities and get groups of entities.
  #  The prefered way to create a context is to use the generated methods
  #  from the code generator, e.g. var context = new GameContext();
  abstract class Context
    @_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    @_reusable_entities : Stack(Entitas::Entity) = Stack(Entitas::Entity).new
    @_retained_entities : Array(Entitas::Entity) = Array(Entitas::Entity).new
    # _groups
    @_total_components : Int32
    @_component_pools : Stack(Entitas::Component) = Stack(Entitas::Component).new
    @_context_info : Context::Info
    @_aerc_factory : Proc(Entitas::Entity, Entitas::SafeAERC(Entitas::Entity))
    # _groupsForIndex
    # _groupChangedListPool
    @_entity_indices : Hash(String, Entitas::Entity::Index) = Hash(String, Entitas::Entity::Index).new
    @_creation_index : Int32
    @_entities_cache : Array(Entitas::Entity) = Array(Entitas::Entity).new

    # @_cached_entity_changed : Proc(Entitas::Entity, Int32, Entitas::Component) -> Nil
    # @_cached_component_replaced : Proc(Entitas::Entity, Int32, Entitas::Component, Entitas::Component) -> Nil
    # @_cached_entity_released : Proc(Entitas::Entity) -> Nil
    # @_cached_destroy_entity : Proc(Entitas::Entity) -> Nil
    # @_on_entity_created : Proc(Entitas::Context(Entitas::Entity), Entitas::Entity) -> Nil
    # @_on_entity_will_be_destroyed : Proc(Entitas::Context(Entitas::Entity), Entitas::Entity) -> Nil
    # @_on_entity_destroyed : Proc(Entitas::Context(Entitas::Entity), Entitas::Entity) -> Nil
    # @_on_group_created : Proc(Entitas::Context(Entitas::Entity), Entitas::Entity) -> Nil

    def initialize(total_components : Int32, start_creation_index : Int32,
                   context_info : Entitas::Context::Info | Nil,
                   aerc_factory : Proc(Entitas::Entity, Entitas::AERC) | Nil)
      @_total_components = total_components
      @_creation_index = start_creation_index
      @_context_info = context_info || create_default_context_info
      @_aerc_factory = aerc_factory.nil? ? ->(entity : Entitas::Entity) { SafeAERC(Entitas::Entity).new(entity) } : aerc_factory
    end

    def create_default_context_info : Entitas::Context::Info
      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::Info.new("Unnamed Context", component_names, Array(Component.class).new)
    end

    def total_components : Int32
      @_total_components
    end

    def component_pools : Stack(Entitas::Component)
      @_component_pools
    end

    def context_info : Context::Info
      @_context_info
    end

    # Returns the total number of `Entitas::Entity` in this `Context`
    def size
      @_entities.size
    end

    def reusable_entities_size
      @_reusable_entities.size
    end

    def retained_entities_size
      @_retained_entities.size
    end

    abstract def reset

    def create_entity : Entitas::Entity
      if reusable_entities_size > 0
        entity = @_reusable_entities.pop
        @_creation_index += 1
        entity.reactivate(@_creation_index)
      else
        entity = Entitas::Entity.new
        @_creation_index += 1
        entity.init(@_creation_index, @_total_components, @_component_pools, @_context_info, @_aerc_factory.call(entity))
      end
    end

    def has_entity?(entity : Entitas::Entity) : Bool
      @_entities.includes? entity
    end

    def get_entities : Array(Entitas::Entity)
      @_entities ||= Array(Entitas::Entity).new
    end
  end
end
