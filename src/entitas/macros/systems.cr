macro create_feature(name, systems)
  class {{name}}Systems < Entitas::Feature
    def initialize(contexts)
      @name = "{{name}} Systems"
      {% for sys in systems %}
        add {{sys.id}}.new(contexts)
      {% end %}
    end
  end
end

macro create_controller(name, features)
  class {{name}}Controller < Entitas::Controller
    def create_systems(contexts : Contexts)
      Entitas::Feature.new("Systems")
      {% for sys in features %}
        .add({{sys.id}}.new(contexts))
      {% end %}
    end
  end
end
