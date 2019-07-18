require "./entity/error"

module Entitas
  class Error < Exception
    class MethodNotImplemented < Error
    end

    class ContextInfo < Error
    end

    class Matcher < Error
    end
  end
end
