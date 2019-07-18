macro create_event(name, opts)
  struct ::Entitas::Events::On{{name.id}}
    {% for a, t in opts %}
    getter {{a.id}} : {{t.id}}
    {% end %}

    def initialize(
      {% for a, t in opts %}
      @{{a.id}} : {{t.id}},
      {% end %}
    )
    end
  end
end

macro emits_events(*names)
  {% for name in names %}
  emits_event {{name}}
  {% end %}
end

macro emits_event(name)
  # alias {{name.id}} = ::Entitas::Events::{{name.id}}
   getter {{name.id.underscore.id}}_events : Array(Proc(::Entitas::Events::{{name.id}}, Nil)) = Array(Proc(::Entitas::Events::{{name.id}}, Nil)).new
   getter {{name.id.underscore.id}}_event_cache : Proc(::Entitas::Events::{{name.id}}, Nil)? = nil

  private def clear_{{name.id.underscore.id}}_event_hooks : Nil
    self.{{name.id.underscore.id}}_events.clear
  end

  def {{name.id.underscore.id}}(&block : ::Entitas::Events::{{name.id}} -> Nil)
    self.{{name.id.underscore.id}}_events << block
  end

  def {{name.id.underscore.id}}_event(event : ::Entitas::Events::{{name.id}}) : Nil
  end
end

macro emit_event(event, *args)
  logger.warn "Emiting event {{event.id}}", self.to_s
  self.{{event.id.underscore.id}}_events.each &.call(::Entitas::Events::{{event.id}}.new({{*args}}))
end
