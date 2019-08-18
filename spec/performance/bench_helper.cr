{% if flag?(:benchmark) %}
  require "bencher"
{% end %}

require "../../src/entitas.cr"
require "./fixtures"
require "benchmark"
require "colorize"

macro start_bench(subject, block)
  Bencher.begin({{subject}}) do
    {{block.body}}
  end
end

macro group(name, tasks)
  Bencher.begin({{name}}) do
    {{tasks.body}}
  end
end

macro bench(name, before, task, after)
  Bencher.begin({{name}}) do
    {{before.body}}
    {{task.body}}
    {{after.body}}
  end
end

macro bench_n_times(name, n, before, task, after)
  Bencher.begin({{name}}) do
    {{before.body}}
    {{n}}.times do
      {{task.body}}
    end
    {{after.body}}
  end
end
