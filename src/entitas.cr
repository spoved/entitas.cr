{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "spoved/logger"
require "./entitas/version"
require "./entitas/annotations"

module Entitas
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  class Error < Exception; end

  abstract class Component; end

  class Contexts; end

  abstract class Context(TEntity)
    class Info; end
  end

  abstract class Entity; end

  class Systems; end

  class Group(TEntity); end

  class Collector(TEntity); end

  class Matcher; end

  # This is the base interface for all systems.
  # It's not meant to be implemented.
  # Use `Systems::InitializeSystem`, `Systems::ExecuteSystem`,
  # `Systems::CleanupSystem` or `Systems::TearDownSystem`.
  module System; end

  abstract class AbstractEntityIndex(TEntity, TKey); end

  class EntityIndex(TEntity, TKey) < AbstractEntityIndex(TEntity, TKey); end

  class PrimaryEntityIndex(TEntity, TKey) < AbstractEntityIndex(TEntity, TKey); end

  abstract struct AERC; end

  struct SafeAERC < AERC; end

  struct UnsafeAERC < AERC; end
end

alias Contexts = Entitas::Contexts

require "./entitas/macros/component"
require "./entitas/macros/contexts"
require "./entitas/macros/events"
require "./entitas/macros/global"
require "./entitas/macros/matcher"
require "./entitas/macros/properties"

require "./entitas/interfaces/i_collector"
require "./entitas/interfaces/i_component"
require "./entitas/interfaces/i_context"
require "./entitas/interfaces/i_entity"
require "./entitas/interfaces/i_group"
require "./entitas/interfaces/i_entity_index"
require "./entitas/interfaces/i_matcher"

module Entitas
  alias ComponentPool = Array(Entitas::IComponent)
  alias AERCFactory = Proc(Entitas::Entity, Entitas::SafeAERC)
  alias EntityFactory = Proc(Entitas::Entity)
end

require "./entitas/error"
require "./entitas/events"

require "./entitas/helpers/component_pools"
require "./entitas/helpers/entities"

require "./entitas/interfaces/*"
require "./entitas/*"
require "./entitas/macros/generator"
