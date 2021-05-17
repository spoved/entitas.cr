module Entitas::IComponent
  Log = ::Log.for(self)

  # Will return true if the class is a unique component for a context
  abstract def is_unique? : Bool
  abstract def init(**args)
  abstract def reset

  macro included
    macro inherited
      Entitas::Component.check_components
    end
  end
end
