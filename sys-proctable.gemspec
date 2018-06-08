require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'sys-proctable'
  spec.version    = '1.2.1'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Apache 2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/sys-proctable'
  spec.summary    = 'An interface for providing process table information'
  spec.test_files = FileList['spec/**/*.rb']
  spec.cert_chain = ['certs/djberg96_pub.pem']
   
  spec.files = FileList[
    "benchmarks/**/*.rb",
    "examples/**/*.rb",
    "lib/**/*.rb",
    'CHANGES',
    'MANIFEST',
    'Rakefile',
    'README',
    'sys-proctable.gemspec'
  ]

  spec.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST', 'doc/top.txt']

  spec.add_dependency('ffi')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The sys-proctable library provides an interface for gathering information
    about processes on your system, i.e. the process table. Most major
    platforms are supported and, while different platforms may return
    different information, the external interface is identical across
    platforms.
  EOF
end
