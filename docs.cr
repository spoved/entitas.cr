############################################
# NOTICE: this file is purely to allow
# the documentation to generate. It should
# not be used anywhere else.
#
# Use `crystal doc docs.cr` to generate up
# to date documentation
############################################

require "./src/entitas.cr"

@[Context(Example)]
class ExampleComponent < Entitas::Component
  prop :message, String, default: ""

  def to_s(io)
    io << message
  end
end
