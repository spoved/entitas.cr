require "../interfaces/i_entity_index"
require "../group"

abstract class Entitas::AbstractEntityIndex(TEntity, TKey)
  include Entitas::IEntityIndex

  abstract def clear
  abstract def add_entity(key : TKey, entity : TEntity)
  abstract def del_entity(key : TKey, entity : TEntity)

  protected property group : Entitas::Group(TEntity)
  protected setter get_key : Proc(TEntity, Entitas::IComponent?, TKey)? = nil
  protected setter get_keys : Proc(TEntity, Entitas::IComponent?, Array(TKey))? = nil

  def get_key : Proc(TEntity, Entitas::IComponent?, TKey)
    raise Exception.new("Must set get_key for #{self}") if @get_key.nil?
    @get_key.as(Proc(TEntity, Entitas::IComponent?, TKey))
  end

  def get_keys : Proc(TEntity, Entitas::IComponent?, Array(TKey))
    raise Exception.new("Must set get_keys for #{self}") if @get_keys.nil?
    @get_keys.as(Proc(TEntity, Entitas::IComponent?, Array(TKey)))
  end

  getter name : String
  protected property is_single_key : Bool

  @on_entity_added : Proc(Entitas::Events::OnEntityAdded, Nil)? = nil
  @on_entity_removed : Proc(Entitas::Events::OnEntityRemoved, Nil)? = nil

  def activate : Nil
    Log.info { "#{self.class} activating" }

    group.on_entity_added_event_hooks << @on_entity_added.as(Proc(Entitas::Events::OnEntityAdded, Nil))
    group.on_entity_removed_event_hooks << @on_entity_removed.as(Proc(Entitas::Events::OnEntityRemoved, Nil))
    self.index_entities(self.group)
  end

  def deactivate : Nil
    group.on_entity_added_event_hooks.delete @on_entity_added
    group.on_entity_removed_event_hooks.delete @on_entity_removed
    self.clear
  end

  def initialize(
    @name : String, @group : Entitas::Group(TEntity),
    @get_key : Proc(TEntity, Entitas::IComponent?, TKey)?,
    @get_keys : Proc(TEntity, Entitas::IComponent?, Array(TKey))?,
    @is_single_key : Bool
  )
    @on_entity_added = ->self.on_entity_added(Entitas::Events::OnEntityAdded)
    @on_entity_removed = ->self.on_entity_removed(Entitas::Events::OnEntityRemoved)
  end

  def self.new(name : String, group : Entitas::Group(TEntity), get_key : Proc(TEntity, Entitas::IComponent?, TKey))
    instance = self.allocate
    instance.initialize(
      name: name,
      group: group,
      get_key: get_key,
      get_keys: nil,
      is_single_key: true
    )
    instance.activate
    instance
  end

  def self.new(name : String, group : Entitas::Group(TEntity), get_keys : Proc(TEntity, Entitas::IComponent?, Array(TKey)))
    instance = self.allocate
    instance.initialize(
      name: name,
      group: group,
      get_key: nil,
      get_keys: get_keys,
      is_single_key: false
    )
    instance.activate
    instance
  end

  protected def single_key?
    @is_single_key
  end

  protected def index_entities(group : Entitas::Group)
    Log.warn { "#{self.class} indexing group #{group}" }
    group.entities.each do |entity|
      if single_key?
        add_entity(self.get_key.call(entity, nil), entity)
      else
        self.get_keys.call(entity, nil).each do |key|
          add_entity(key, entity)
        end
      end
    end
  end

  protected def on_entity_added(event : Entitas::Events::OnEntityAdded)
    entity = event.entity.as(TEntity)
    if single_key?
      add_entity(self.get_key.call(entity, event.component), entity)
    else
      self.get_keys.call(entity, event.component).each do |key|
        add_entity(key, entity)
      end
    end
  end

  protected def on_entity_removed(event : Entitas::Events::OnEntityRemoved)
    entity = event.entity.as(TEntity)
    if single_key?
      del_entity(self.get_key.call(entity, event.component), entity)
    else
      self.get_keys.call(entity, event.component).each do |key|
        del_entity(key, entity)
      end
    end
  end

  def finalize
    self.deactivate
  end
end
