require "../error"
require "../component"

module Entitas
  abstract class Entity
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

      class IsNotDestroyedException < Error
      end
    end
  end
end
