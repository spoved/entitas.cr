{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "spoved/logger"

# TODO: Write documentation for `Entitas`
module Entitas
  {% if !flag?(:disable_logging) %}spoved_logger{% end %}

  alias ComponentPool = Array(::Entitas::Component)
  alias AERCFactory = Proc(::Entitas::Entity, ::Entitas::SafeAERC)
  alias EntityFactory = Proc(::Entitas::Entity)

  abstract class Component; end

  abstract class Context; end

  abstract class Entity; end

  class Systems; end

  class Group; end

  class Collector; end
end

require "./entitas/*"
