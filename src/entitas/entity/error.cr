require "../error"
require "../component"

module Entitas
  class Entity
    class Error < Exception
      class IsNotEnabled < Error
      end

      class DoesNotHaveComponent < Error
      end

      class AlreadyHasComponent < Error
      end

      class IsAlreadyRetainedByOwner < Error
      end

      class IsNotRetainedByOwner < Error
      end
    end
  end
end
