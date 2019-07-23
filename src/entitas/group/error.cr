require "../error"

module Entitas
  abstract class Group
    class Error < Exception
      class SingleEntity < Error
      end
    end
  end
end
