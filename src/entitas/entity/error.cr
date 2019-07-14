require "../error"
require "../component"

module Entitas
  class Entity
    class Error < Exception
    end

    class EntityIsNotEnabledException < Error
    end

    class EntityDoesNotHaveComponentException < Error
    end

    class EntityAlreadyHasComponentException < Error
    end
  end
end
