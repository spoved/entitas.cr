require "../error"
require "../component"

module Entitas
  abstract class Entity
    abstract class Index(TKey)
      class Error < Exception; end
    end

    class Error < Exception
      class IsNotEnabled < Error; end

      class DoesNotHaveComponent < Error; end

      class AlreadyHasComponent < Error; end

      class IsAlreadyRetainedByOwner < Error; end

      class IsNotRetainedByOwner < Error; end

      class IsNotDestroyedException < Error; end
    end
  end
end
