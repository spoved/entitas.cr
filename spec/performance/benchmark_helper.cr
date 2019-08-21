require "benchmark"
require "colorize"

IPS_HEADER = "label | human_mean (itr/sec) | human_iteration_time | relative_stddev | bytes_per_op | human_compare".colorize(:yellow)
IPS_WARMUP =  4
IPS_CALC   = 10
LOGGER     = Logger.new(STDOUT)

def logger
  LOGGER
end

alias BenchCall = Proc(Benchmark::IPS::Job | Benchmark::BM::Job, Nil)

module BenchmarkHelper
  extend self
  class_getter context : String? = nil
  class_getter group : String? = nil

  class_getter contexts : Array(String) = Array(String).new

  class_property context_tasks = Hash(String, Array(BenchCall)).new
  class_property context_ips_tasks = Hash(String, Array(BenchCall)).new
  class_property context_groups = Hash(String, Hash(String, Array(BenchCall))).new
  class_property context_ips_groups = Hash(String, Hash(String, Array(BenchCall))).new

  def context=(value)
    if value.nil?
      @@context = nil
    else
      @@context = "#{value}"
      contexts << current_context_name unless contexts.includes?(current_context_name)
      context_tasks[current_context_name] = Array(BenchCall).new unless context_tasks[current_context_name]?
      context_ips_tasks[current_context_name] = Array(BenchCall).new unless context_ips_tasks[current_context_name]?
      context_groups[current_context_name] = Hash(String, Array(BenchCall)).new unless context_groups[current_context_name]?
      context_ips_groups[current_context_name] = Hash(String, Array(BenchCall)).new unless context_ips_groups[current_context_name]?

      @@context
    end
  end

  def group=(value)
    if value.nil?
      @@group = nil
    else
      @@group = "#{value}"

      groups[current_group_name] = Array(BenchCall).new unless groups[current_group_name]?
      ips_groups[current_group_name] = Array(BenchCall).new unless ips_groups[current_group_name]?

      current_group_name
    end
  end

  def tasks
    context_tasks[current_context_name]
  end

  def tasks?
    !tasks.empty?
  end

  def ips_tasks
    context_ips_tasks[current_context_name]
  end

  def ips_tasks?
    !ips_tasks.empty?
  end

  def groups
    context_groups[current_context_name]
  end

  def groups?
    groups.each do |_, v|
      return true unless v.empty?
    end
    false
  end

  def ips_groups
    context_ips_groups[current_context_name]
  end

  def ips_groups?
    ips_groups.each do |_, v|
      return true unless v.empty?
    end
    false
  end

  def current_context_name : String
    raise "NO CURRENT CONTEXT FOR TASK" if context.nil?
    context.as(String)
  end

  def current_group_name : String
    raise "NO CURRENT GROUP FOR TASK" if group.nil?
    group.as(String)
  end

  def current_group : Array(BenchCall)
    raise "NO CURRENT GROUP FOR TASK" if group.nil?
    groups[group.as(String)]
  end

  def current_ips_group : Array(BenchCall)
    raise "NO CURRENT GROUP FOR TASK" if group.nil?
    ips_groups[group.as(String)]
  end

  def add_task(value)
    raise "NO CURRENT CONTEXT FOR TASK" if context.nil?
    logger.debug("Adding task")
    if group.nil?
      logger.debug("Adding to tasks")
      tasks << value
    else
      logger.debug "Adding to current group: #{current_group_name}"
      current_group << value
    end
  end

  def add_ips_task(value)
    raise "NO CURRENT CONTEXT FOR TASK" if context.nil?
    logger.debug("Adding task")
    if group.nil?
      logger.debug("Adding to tasks")
      ips_tasks << value
    else
      logger.debug "Adding to current group: #{current_group_name}"
      current_ips_group << value
    end
  end

  def run
    contexts.each do |ctx|
      @@context = ctx
      puts ""
      puts "--## #{ctx} ##--".colorize(:green).mode(:bold)

      if tasks? || groups?
        puts "-- Total execution time --".colorize(:green)

        if tasks?
          puts ""
          run_tasks
          GC.collect
        end

        if groups?
          puts ""
          run_groups
          GC.collect
        end
      end

      if ips_tasks? || ips_groups?
        puts "-- Instruction per second --".colorize(:green)

        if ips_tasks?
          puts ""
          run_ips_tasks
          GC.collect
        end

        if ips_groups?
          puts ""
          run_ips_groups
          GC.collect
        end
      end
    end
  end

  def run_tasks
    Benchmark.bm do |x|
      tasks.each do |t|
        t.call(x)
        GC.collect
      end
    end
  end

  def run_groups
    unless groups.empty?
      groups.each do |g, ts|
        next if ts.empty?
        puts "- #{g} -".colorize(:blue)

        Benchmark.bm do |x|
          ts.each do |t|
            t.call(x)
            GC.collect
          end
        end
        GC.collect
        puts ""
      end
    end
  end

  def run_ips_tasks
    unless ips_tasks.empty?
      puts IPS_HEADER
      ips_tasks.each do |t|
        Benchmark.ips(warmup: IPS_WARMUP, calculation: IPS_CALC) do |x|
          t.call(x)
          GC.collect
        end
        GC.collect
      end
    end
  end

  def run_ips_groups
    unless ips_groups.empty?
      ips_groups.each do |g, ts|
        next if ts.empty?
        puts "- #{g} -".colorize(:blue)
        puts IPS_HEADER
        Benchmark.ips(warmup: IPS_WARMUP, calculation: IPS_CALC) do |x|
          ts.each do |t|
            t.call(x)
            GC.collect
          end
        end
        GC.collect
        puts ""
      end
    end
  end
end

macro start_bench(subject, block)
  BenchmarkHelper.context = {{subject}}

  {{block.body}}
end

macro group(name, tasks)
  BenchmarkHelper.group = {{name}}

  {{tasks.body}}

  BenchmarkHelper.group = nil
end

macro bench(name, before, task, after, ips = false)
  func = ->(x : Benchmark::IPS::Job | Benchmark::BM::Job) do
    begin
      {{before.body}}
      x.report({{name}}) do
        {{task.body}}
      end
      {{after.body}}
    end
    nil
  end

  {% if ips == false %}
    BenchmarkHelper.add_task func
  {% else %}
    BenchmarkHelper.add_ips_task func
  {% end %}
end

macro bench_n_times(name, n, before, task, after, ips = false)
  {% if ips == false %}
    func = ->(x : Benchmark::IPS::Job | Benchmark::BM::Job) do
      begin
        {{before.body}}
        x.report({{name}}) do
          {{n}}.times do
            {{task.body}}
          end
        end
        {{after.body}}
      end
      nil
    end
    BenchmarkHelper.add_task func
  {% else %}
    BenchmarkHelper.add_ips_task ->(x : Benchmark::IPS::Job | Benchmark::BM::Job) do
      begin
        {{before.body}}
        x.report({{name}}) do
          {{task.body}}
        end
        {{after.body}}
      end
      nil
    end
  {% end %}
end
