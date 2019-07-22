require "spoved/logger"

# TODO: Write documentation for `Entitas`
module Entitas
  spoved_logger

  abstract class Component; end

  abstract class Context; end

  abstract class Entity; end
end

require "./entitas/*"

# Test code below

require "../spec/fixtures/*"
