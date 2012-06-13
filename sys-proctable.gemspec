require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'sys-proctable'
  spec.version    = '0.9.2'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Artistic 2.0' 
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://www.rubyforge.org/projects/sysutils'
  spec.platform   = Gem::Platform::CURRENT # Probably altered by Rake task
  spec.summary    = 'An interface for providing process table information'
  spec.test_files = ['test/test_sys_proctable_all.rb']
   
  # Additional files for your platform are added by the 'rake gem' task.
  spec.files = [
    'benchmarks/bench_ps.rb',
    'examples/example_ps.rb',
    'lib/sys/top.rb',
    'CHANGES',
    'MANIFEST',
    'Rakefile',
    'README',
    'sys-proctable.gemspec'
  ]

  spec.rubyforge_project = 'sysutils'
  spec.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST', 'doc/top.txt']

  spec.add_development_dependency('test-unit', '>= 2.4.0')

  spec.description = <<-EOF
    The sys-proctable library provides an interface for gathering information
    about processes on your system, i.e. the process table. Most major
    platforms are supported and, while different platforms may return
    different information, the external interface is identical across
    platforms.
  EOF
end
