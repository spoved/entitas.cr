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

  abstract class Context; end

  abstract class Entity; end

  class Systems; end

  class Group; end

  class Collector; end

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

require "./entitas/*"
