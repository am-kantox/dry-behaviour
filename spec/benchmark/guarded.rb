require 'benchmark/ips'

class GuardBenchmark
  include Dry::Guards

  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Lint/DuplicateMethods
  # rubocop:disable Style/SingleLineMethods
  # rubocop:disable Style/EmptyLineBetweenDefs
  def a(p1); [p1]; end
  def a(p1, p2); [p1, p2]; end
  def a(p1, p2, p3); [p1, p2, p3]; end
  def a(p1, p2, p3, p4, when: { p4: Integer }); [p1, p2, p3, p4]; end

  def b(_p1, _p2, _p3, _p4); 'NOT GUARDED'; end
  # rubocop:enable Style/EmptyLineBetweenDefs
  # rubocop:enable Style/SingleLineMethods
  # rubocop:enable Lint/DuplicateMethods
  # rubocop:enable Lint/UnusedMethodArgument
end

GB = GuardBenchmark.new

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('1 arg') { GB.a(1) }
  x.report('2 args') { GB.a(1, 2) }
  x.report('3 args') { GB.a(1, 2, 3) }
  x.report('4 + guard') { GB.a(1, 2, 3, 4) }
  x.report('¬guarded') { GB.b(1, 2, 3, 4) }

  x.compare!
end
