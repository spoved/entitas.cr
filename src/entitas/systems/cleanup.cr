require "../system"

module Entitas::Systems::CleanupSystem
  include Entitas::System

  abstract def cleanup : Nil
end