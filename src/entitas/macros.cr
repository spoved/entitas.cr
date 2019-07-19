require "./error"

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

macro provides_event_hooks(*names)
  {% for name in names %}
  provides_event_hook {{name}}
  {% end %}
end

macro provides_event_hook(name)
  property {{name.id.underscore.id}}_event_cache : Proc(Events::{{name.id}}, Nil)? = nil

  def {{name.id.underscore.id}}(event : ::Entitas::Events::{{name.id}}) : Nil
    logger.info "Processing OnEntityChanged: #{event}"
    raise Entitas::Error::MethodNotImplemented.new
  end
end

macro emits_events(*names)
  {% for name in names %}
  emits_event {{name}}
  {% end %}
end

macro emits_event(name)
  # accept_event {{name}}
  provides_event_hook {{name}}
end

macro emit_event(event, *args)
  logger.warn "Emiting event {{event.id}}", self.to_s
  self.{{event.id.underscore.id}}_events.each &.call(::Entitas::Events::{{event.id}}.new({{*args}}))
end

macro accept_events(*names)
  {% for name in names %}
  accept_event {{name}}
  {% end %}
end

macro accept_event(name)
  getter {{name.id.underscore.id}}_events : Array(Proc(::Entitas::Events::{{name.id}}, Nil)) = Array(Proc(::Entitas::Events::{{name.id}}, Nil)).new

  def {{name.id.underscore.id}}(&block : ::Entitas::Events::{{name.id}} -> Nil)
    self.{{name.id.underscore.id}}_events << block
  end

  private def clear_{{name.id.underscore.id}}_event_hooks : Nil
    self.{{name.id.underscore.id}}_events.clear
  end
end
