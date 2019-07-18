require "./component"
require "./entity"
require "./aerc"

module Entitas
  alias ComponentPool = Array(::Entitas::Component)
  alias AERCFactory = Proc(::Entitas::Entity, ::Entitas::SafeAERC)
  alias EntityFactory = Proc(::Entitas::Entity)
end
