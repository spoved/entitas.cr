require "../error"

module Entitas
  class Entity
    module Index
      getter name : String | Nil

      def activate : Nil
        raise Entitas::MethodNotImplementedError
      end

      def deactivate : Nil
        raise Entitas::MethodNotImplementedError
      end
    end
  end
end
