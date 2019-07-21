require "./error"

module Entitas
  abstract class Entity
    module Index
      getter name : String | Nil

      def activate : Nil
        raise Entitas::MethodNotImplemented
      end

      def deactivate : Nil
        raise Entitas::MethodNotImplemented
      end
    end
  end
end
