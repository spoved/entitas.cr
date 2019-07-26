require "spoved/logger"

# TODO: Write documentation for `Entitas`
module Entitas
  spoved_logger

  alias ComponentPool = Array(::Entitas::Component)
  alias AERCFactory = Proc(::Entitas::Entity, ::Entitas::SafeAERC)
  alias EntityFactory = Proc(::Entitas::Entity)

  abstract class Component; end

  abstract class Context; end

  abstract class Entity; end

  abstract class Systems; end

  class Group; end

  class Collector; end
end

require "./entitas/*"

# Test code below

require "../spec/fixtures/*"
