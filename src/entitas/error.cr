module Entitas
  class MethodNotImplementedError < Exception
  end

  class EntityIsAlreadyRetainedByOwnerException < Exception
  end

  class EntityIsNotRetainedByOwnerException < Exception
  end

  class ContextInfoException < Exception
  end

  class MatcherException < Exception
  end
end
