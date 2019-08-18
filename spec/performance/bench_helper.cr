{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "../../src/entitas.cr"
require "./fixtures"
require "benchmark"
require "colorize"

macro start_bench(subject, block)
  {% if flag?(:benchmark) %}
  Bencher.begin({{subject}}) do
    {{block.body}}
  end
  {% else %}
  {{block.body}}
  {% end %}
end

macro group(name, tasks)
  {% if flag?(:benchmark) %}
  Bencher.begin({{name}}) do
    {{tasks.body}}
  end
  {% else %}
  {{tasks.body}}
  {% end %}
end

macro bench(name, before, task, after)
  {% if flag?(:benchmark) %}
  {{before.body}}
  Bencher.begin({{name}}) do
    {{task.body}}
  end
  {{after.body}}
  {% else %}
  Benchmark.bm do |x|
    {{before.body}}
    x.report({{name}}.to_s) do
      {{task.body}}
    end
    {{after.body}}
  end
  {% end %}
end

macro bench_n_times(name, n, before, task, after)
  {% if flag?(:benchmark) %}
  {{before.body}}
  Bencher.begin({{name}}) do
    {{n}}.times do
      {{task.body}}
    end
  end
  {{after.body}}
  {% else %}
  Benchmark.bm do |x|
    {{before.body}}
    x.report({{name}}.to_s) do
      {{n}}.times do
        {{task.body}}
      end
    end
    {{after.body}}
  end
  {% end %}
end
