require 'rubygems'
require_relative 'lib/sys/proctable/version'

Gem::Specification.new do |spec|
  spec.name       = 'sys-proctable'
  spec.version    = Sys::ProcTable::VERSION
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Apache-2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/sys-proctable'
  spec.summary    = 'An interface for providing process table information'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.test_files = Dir['spec/*.rb']
  spec.cert_chain = ['certs/djberg96_pub.pem']
   
  spec.add_dependency('ffi', '~> 1.1')
  spec.add_development_dependency('rspec', '~> 3.9')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop')
  spec.add_development_dependency('rubocop-rspec')
  spec.add_development_dependency('mkmf-lite')

  spec.metadata = {
    'homepage_uri'          => 'https://github.com/djberg96/sys-proctable',
    'bug_tracker_uri'       => 'https://github.com/djberg96/sys-proctable/issues',
    'changelog_uri'         => 'https://github.com/djberg96/sys-proctable/blob/main/CHANGES.md',
    'documentation_uri'     => 'https://github.com/djberg96/sys-proctable/wiki',
    'source_code_uri'       => 'https://github.com/djberg96/sys-proctable',
    'wiki_uri'              => 'https://github.com/djberg96/sys-proctable/wiki',
    'rubygems_mfa_required' => 'true'
  }

  spec.description = <<-EOF
    The sys-proctable library provides an interface for gathering information
    about processes on your system, i.e. the process table. Most major
    platforms are supported and, while different platforms may return
    different information, the external interface is identical across
    platforms.
  EOF
end
