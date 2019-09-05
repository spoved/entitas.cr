module Entitas
  abstract class Controller
    private property systems : Systems? = nil
    private property contexts : Contexts? = nil

    def start
      self.contexts = Contexts.shared_instance
      self.systems = create_systems(self.contexts.as(Contexts))
      self.systems.as(Systems).init
    end

    def update
      if systems.nil?
        raise "Called update before start! no systems initialized!"
      end
      systems.as(Systems).execute
      systems.as(Systems).cleanup
    end

    abstract def create_systems(contexts : Contexts)
  end
end
