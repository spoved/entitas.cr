module Entitas::IEntityIndex
  abstract def name : String
  abstract def activate : Nil
  abstract def deactivate : Nil
end
