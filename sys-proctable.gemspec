require 'rubygems'
require 'rbconfig'

Gem::Specification.new do |gem|
   gem.name       = 'sys-proctable'
   gem.version    = '0.8.2'
   gem.author     = 'Daniel J. Berger'
   gem.license    = 'Artistic 2.0' 
   gem.email      = 'djberg96@gmail.com'
   gem.homepage   = 'http://www.rubyforge.org/projects/sysutils'
   gem.platform   = Gem::Platform::CURRENT
   gem.summary    = 'An interface for providing process table information'
   gem.has_rdoc   = true
   gem.test_files = ['test/test_sys_proctable_all.rb']
   
   # Additional files for your platform are added by the 'rake gem' task.
   gem.files = [
      'benchmarks/bench_ps.rb',
      'examples/example_ps.rb',
      'lib/sys/top.rb',
      'CHANGES',
      'MANIFEST',
      'Rakefile',
      'README',
      'sys-proctable.gemspec'
   ]

   gem.rubyforge_project = 'sysutils'
   gem.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST', 'doc/top.txt']

   gem.add_development_dependency('test-unit', '>= 2.0.3')

   gem.description = <<-EOF
      The sys-proctable library provides an interface for gathering information
      about processes on your system, i.e. the process table. Most major
      platforms are supported and, while different platforms may return
      different information, the external interface is identical across
      platforms.
   EOF
end
