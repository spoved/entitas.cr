require "../spec_helper"

private def new_contexts
  Contexts.new
end

private def new_standard_event_system
  Test4::StandardEvent::AnyListener::System.new(new_contexts)
end

private class RemoveEventTest
  include ::StandardEvent::AnyListener

  def on_standard_event(entity, component)
  end

  def on_any_standard_event_listener(entity, component)
  end
end

describe "Events" do
  describe "event" do
    it "can remove listener in callback" do
    end
  end
end
