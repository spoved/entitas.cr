require "../error"
require "../component"

module Entitas
  class Entity
    class Error < Exception
    end

    class IsNotEnabledException < Error
    end

    class DoesNotHaveComponentException < Error
    end

    class AlreadyHasComponentException < Error
    end

    class IsAlreadyRetainedByOwnerException < Error
    end

    class IsNotRetainedByOwnerException < Error
    end
  end
end
