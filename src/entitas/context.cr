require "../stack"
require "./component"
require "./entity/index"
require "./entity/aerc"

module Entitas
  class Contexts
    def self.shared_instance
      @@_shared_instance ||= Oid::Contexts.new
    end

    def all_contexts
      @contexts ||= Array(Entitas::Context).new
    end

    def reset
      all_contexts.each do |context|
        context.reset
      end
    end
  end

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
    @_context_info : ContextInfo
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
                   context_info : Entitas::Context::ContextInfo | Nil,
                   aerc_factory : Proc(Entitas::Entity, Entitas::AERC) | Nil)
      @_total_components = total_components
      @_creation_index = start_creation_index
      @_context_info = context_info || create_default_context_info
      @_aerc_factory = aerc_factory.nil? ? ->(entity : Entitas::Entity){ SafeAERC(Entitas::Entity).new(entity) } : aerc_factory
    end

    def create_default_context_info : Entitas::Context::ContextInfo
      component_names = Array(String).new
      prefix = "Index "
      total_components.times do |i|
        component_names << prefix + i.to_s
      end

      Entitas::Context::ContextInfo.new("Unnamed Context", component_names, Array(Component.class).new)
    end

    def total_components : Int32
      @_total_components
    end

    def component_pools : Stack(Entitas::Component)
      @_component_pools
    end

    def context_info : ContextInfo
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

    abstract def create_entity : Entitas::Entity

    def has_entity?(entity : Entitas::Entity) : Bool
      @_entities.includes? entity
    end

    def get_entities : Array(Entitas::Entity)
      @_entities ||= Array(Entitas::Entity).new
    end

    class ContextInfo
      getter name : String
      getter component_names : Array(String)
      getter component_types : Array(Component.class)

      def initialize(@name, @component_names, @component_types)
      end
    end
  end
end
