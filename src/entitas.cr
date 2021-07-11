require "json"

{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "spoved/logger"

# TODO: Write documentation for `Entitas`
module Entitas
  Log = ::Log.for(self)

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

  alias ComponentPool = Array(Entitas::IComponent)
  alias AERCFactory = Proc(Entitas::Entity, Entitas::SafeAERC)
  alias EntityFactory = Proc(Entitas::Entity)
end

alias Contexts = Entitas::Contexts

require "./entitas/annotations"
require "./entitas/macros/*"
require "./entitas/interfaces/*"
require "./entitas/*"
require "./entitas/generators/main"
