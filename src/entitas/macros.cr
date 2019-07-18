macro create_event(name, opts)
  protected getter on_{{name.id.underscore.id}}_events = Array(Proc(On{{name.id}}, Nil)).new

  def on_{{name.id.underscore.id}}(&block : On{{name.id}} -> Nil)
    self.on_{{name.id.underscore.id}}_events << block
  end

  def clear_on_{{name.id.underscore.id}}_event_hooks : Nil
    self.on_{{name.id.underscore.id}}_events.clear
  end

  struct On{{name.id}}
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
