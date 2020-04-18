{% if flag?(:benchmark) %}
  require "./bencher_helper.cr"
{% else %}
  require "./benchmark_helper.cr"
{% end %}

require "../../src/entitas"
require "./fixtures"
require "benchmark"
require "colorize"
require "json"
require "./tasks"

{% if !flag?(:benchmark) %}
  BenchmarkHelper.run
{% end %}
