{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "spoved/logger"
require "./ext/*"

# TODO: Write documentation for `Entitas`
module Entitas
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  class Error < Exception; end

  abstract class Component; end

  class Contexts; end

  abstract class Context(TEntity); end

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

  alias ComponentPool = Array(Entitas::Component)
  alias AERCFactory = Proc(Entitas::Entity, Entitas::SafeAERC)
  alias EntityFactory = Proc(Entitas::Entity)
end

alias Contexts = Entitas::Contexts

require "./entitas/macros/context"
require "./entitas/*"
