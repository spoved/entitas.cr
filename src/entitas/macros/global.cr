macro call_post_constructors
  {% for meth in @type.methods %}
    {% if meth.annotation(Entitas::PostConstructor) %}
      {{meth.name.id}}
    {% end %}
  {% end %}
end
