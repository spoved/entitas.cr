{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "spoved/logger"
require "./ext/*"

# TODO: Write documentation for `Entitas`
module Entitas
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  alias ComponentPool = Array(::Entitas::Component)
  alias AERCFactory = Proc(::Entitas::Entity, ::Entitas::SafeAERC)
  alias EntityFactory = Proc(::Entitas::Entity)

  abstract class Component; end

  abstract class Context; end

  abstract class Entity
    abstract class Index(TKey); end
  end

  class Systems; end

  class Group; end

  class Collector; end

  # This is the base interface for all systems.
  # It's not meant to be implemented.
  # Use `Systems::InitializeSystem`, `Systems::ExecuteSystem`,
  # `Systems::CleanupSystem` or `Systems::TearDownSystem`.
  module Entitas::System; end
end

require "./entitas/*"
