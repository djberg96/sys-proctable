require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'
require 'rspec/core/rake_task'
include RbConfig

desc 'Install the sys-proctable library'
task :install do
  file = nil
  dir  = File.join(CONFIG['sitelibdir'], 'sys')

  Dir.mkdir(dir) unless File.exists?(dir)

  case CONFIG['host_os']
    when /mswin|win32|msdos|cygwin|mingw|windows/i
      file = 'lib/windows/sys/proctable.rb'
    when /linux/i
      file = 'lib/linux/sys/proctable.rb'
    when /sunos|solaris/i
      file = 'lib/sunos/sys/proctable.rb'
    when /aix/i
      file = 'lib/aix/sys/proctable.rb'
    when /freebsd/i
      file = 'lib/freebsd/sys/proctable.rb'
    when /darwin/i
      file = 'lib/darwin/sys/proctable.rb'
  end

  cp(file, dir, :verbose => true) if file
end

desc 'Uninstall the sys-proctable library'
task :uninstall do
  dir  = File.join(CONFIG['sitelibdir'], 'sys')
  file = File.join(dir, 'proctable.rb')
  rm(file) 
end

desc 'Run the benchmark suite'
task :bench do
  sh "ruby -Ilib benchmarks/bench_ps.rb"
end

desc 'Run the example program'
task :example do
  sh 'ruby -Ilib -Iext examples/example_ps.rb'
end

desc 'Run the test suite for the sys-proctable library'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/sys_proctable_all_spec.rb']

  case CONFIG['host_os']
    when /aix/i
      t.rspec_opts = '-Ilib/aix'
      t.pattern << 'spec/sys_proctable_aix.rb'
    when /darwin/i
      t.rspec_opts = '-Ilib/darwin'
      t.pattern << 'spec/sys_proctable_darwin_spec.rb'
    when /freebsd/i
      t.rspec_opts = '-Ilib/freebsd'
      t.pattern << 'spec/sys_proctable_freebsd_spec.rb'
    when /linux/i
      t.rspec_opts = '-Ilib/linux'
      t.pattern << 'spec/sys_proctable_linux_spec.rb'
    when /sunos|solaris/i
      t.rspec_opts = '-Ilib/sunos'
      t.pattern << 'spec/sys_proctable_sunos_spec.rb'
    when /mswin|msdos|cygwin|mingw|windows/i
      t.rspec_opts = '-Ilib/windows'
      t.pattern << 'spec/sys_proctable_windows_spec.rb'
  end
end

namespace :gem do
  desc 'Create a gem for the specified OS, or your current OS by default'
  task :create, [:os] => [:clean] do |_task, args|
    require 'rubygems/package'

    if args.is_a?(String)
      os = args
    else
      args.with_defaults(:os => CONFIG['host_os'])
      os = args[:os]
    end

    spec = eval(IO.read('sys-proctable.gemspec'))
    spec.files += ['lib/sys-proctable.rb']

    # I've had to manually futz with the spec here in some cases
    # in order to get the universal platform settings I want because
    # of some bugginess in Rubygems' platform.rb.
    #
    case os
      when /aix/i
         spec.platform = Gem::Platform.new(['universal', 'aix5'])
         spec.require_paths = ['lib', 'lib/aix']
         spec.files += ['lib/aix/sys/proctable.rb']
         spec.test_files << 'spec/sys_proctable_aix_spec.rb'
      when /darwin/i
         spec.platform = Gem::Platform.new(['universal', 'darwin'])
         spec.require_paths = ['lib', 'lib/darwin']
         spec.files += ['lib/darwin/sys/proctable.rb']
         spec.test_files << 'spec/sys_proctable_darwin_spec.rb'
         spec.add_dependency('ffi')
      when /freebsd/i
         spec.platform = Gem::Platform.new(['universal', 'freebsd'])
         spec.require_paths = ['lib', 'lib/freebsd']
         spec.files += ['lib/freebsd/sys/proctable.rb']
         spec.test_files << 'spec/sys_proctable_freebsd_spec.rb'
         spec.add_dependency('ffi')
      when /linux/i
         spec.platform = Gem::Platform.new(['universal', 'linux'])
         spec.require_paths = ['lib', 'lib/linux']
         spec.files += ['lib/linux/sys/proctable.rb', 'lib/linux/sys/proctable/cgroup_entry.rb', 'lib/linux/sys/proctable/smaps.rb']
         spec.test_files << 'spec/sys_proctable_linux_spec.rb'
      when /sunos|solaris/i
         spec.platform = Gem::Platform.new(['universal', 'solaris'])
         spec.require_paths = ['lib', 'lib/sunos']
         spec.files += ['lib/sunos/sys/proctable.rb']
         spec.test_files << 'spec/sys_proctable_sunos_spec.rb'
      when /mswin|win32|dos|cygwin|mingw|windows/i
         spec.platform = Gem::Platform.new(['universal', 'mingw32'])
         spec.require_paths = ['lib', 'lib/windows']
         spec.files += ['lib/windows/sys/proctable.rb']
         spec.test_files << 'spec/sys_proctable_windows_spec.rb'
      else
         raise "Unsupported platform: #{os}"
    end

    spec.test_files << 'test/test_sys_top.rb'
 
    # https://github.com/rubygems/rubygems/issues/147
    spec.original_platform = spec.platform

    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')

    Gem::Package.build(spec, true)
  end

  desc 'Create a gem for each supported OS'
  task :create_all => [:clean] do
    platforms = %w[aix darwin freebsd linux solaris windows]
    Rake::Task["clean"].execute
    platforms.each{ |os|
      FileUtils.mkdir_p("pkg/#{os}")
      Rake::Task["gem:create"].execute(os)
      Dir.glob("*.gem").each{ |gem| FileUtils.mv(gem, "pkg/#{os}") }
    }
  end

  desc 'Push all gems for each supported OS'
  task :push_all do
    Dir["pkg/**/*.gem"].each{ |file|
      sh "gem push #{file}"
    }
  end

  desc 'Install the sys-proctable library as a gem'
  task :install => [:create] do
    gem_name = Dir['*.gem'].first
    sh "gem install -l #{gem_name}"
  end
end

task :default => :spec
