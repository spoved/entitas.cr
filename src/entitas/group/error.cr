require "../error"

module Entitas
  class Group
    class Error < Exception
      class SingleEntity < Error
      end
    end
  end
end
