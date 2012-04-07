require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'
include RbConfig

CLEAN.include(
  '**/*.core',              # Core dump files
  '**/*.gem',               # Gem files
  '**/*.rbc',               # Rubinius
  '.rbx', '**/*/.rbx',      # Rubinius
  '**/*.o',                 # C object file
  '**/*.log',               # Ruby extension build log
  '**/Makefile',            # C Makefile
  '**/conftest.dSYM',       # OS X build directory
  "**/*.#{CONFIG['DLEXT']}" # C shared object
)

desc 'Build the sys-proctable library for C versions of sys-proctable'
task :build => [:clean] do
  case CONFIG['host_os']
    when /bsd/i
      dir = 'ext/bsd'
    when /darwin/i
      dir = 'ext/darwin'
    when /hpux/i
      dir = 'ext/hpux'
  end

  unless CONFIG['host_os'] =~ /win32|mswin|dos|cygwin|mingw|windows|linux|sunos|solaris/i
    Dir.chdir(dir) do
      ruby 'extconf.rb'
      sh 'make'
      cp 'proctable.' + CONFIG['DLEXT'], 'sys'
    end
  end
end

desc 'Install the sys-proctable library'
task :install => [:build] do
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
    when /bsd/i
      Dir.chdir('ext/bsd'){ sh 'make install' }
    when /darwin/i
      Dir.chdir('ext/darwin'){ sh 'make install' }
    when /hpux/i
      Dir.chdir('ext/hpux'){ sh 'make install' }
  end

  cp(file, dir, :verbose => true) if file
end

desc 'Uninstall the sys-proctable library'
task :uninstall do
  case CONFIG['host_os']
    when /win32|mswin|dos|cygwin|mingw|windows|linux|sunos|solaris/i
      dir  = File.join(CONFIG['sitelibdir'], 'sys')
      file = File.join(dir, 'proctable.rb')
    else
      dir  = File.join(CONFIG['sitearchdir'], 'sys')
      file = File.join(dir, 'proctable.' + CONFIG['DLEXT'])
  end

  rm(file) 
end

desc 'Run the benchmark suite'
task :bench => [:build] do
  sh "ruby -Ilib benchmarks/bench_ps.rb"
end

desc 'Run the example program'
task :example => [:build] do
  sh 'ruby -Ilib -Iext examples/example_ps.rb'
end

desc 'Run the test suite'
Rake::TestTask.new do |t|
  task :test => :build
  t.libs << 'test' << '.'
   
  case CONFIG['host_os']
    when /mswin|msdos|cygwin|mingw|windows/i
      t.test_files = FileList['test/test_sys_proctable_windows.rb']
      t.libs << 'lib/windows'
    when /linux/i
      t.test_files = FileList['test/test_sys_proctable_linux.rb']
      t.libs << 'lib/linux'
    when /sunos|solaris/i
      t.test_files = FileList['test/test_sys_proctable_sunos.rb']
      t.libs << 'lib/sunos'
    when /darwin/i
      t.libs << 'ext/darwin'
      t.test_files = FileList['test/test_sys_proctable_darwin.rb']
    when /bsd/i
      t.libs << 'ext/bsd'
      t.test_files = FileList['test/test_sys_proctable_bsd.rb']  
    when /hpux/i
      t.libs << 'ext/hpux'
      t.test_files = FileList['test/test_sys_proctable_hpux.rb']  
  end
end

namespace :gem do
  desc 'Create a gem'
  task :create => [:clean] do
    spec = eval(IO.read('sys-proctable.gemspec'))

    # I've had to manually futz with the spec here in some cases
    # in order to get the universal platform settings I want because
    # of some bugginess in Rubygems' platform.rb.
    #
    case CONFIG['host_os']
      when /bsd/i
         spec.platform = Gem::Platform.new(['universal', 'freebsd'])
         spec.platform.version = nil
         spec.files << 'ext/bsd/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/bsd/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_bsd.rb'
         spec.extensions = ['ext/bsd/extconf.rb']
      when /darwin/i
         spec.platform = Gem::Platform.new(['universal', 'darwin'])
         spec.files << 'ext/darwin/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/darwin/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_darwin.rb'
         spec.extensions = ['ext/darwin/extconf.rb']
      when /hpux/i
         spec.platform = Gem::Platform.new(['universal', 'hpux'])
         spec.files << 'ext/hpux/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/hpux/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_hpux.rb'
         spec.extensions = ['ext/hpux/extconf.rb']
      when /linux/i
         spec.platform = Gem::Platform.new(['universal', 'linux'])
         spec.require_paths = ['lib', 'lib/linux']
         spec.files += ['lib/linux/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_linux.rb'
      when /sunos|solaris/i
         spec.platform = Gem::Platform.new(['universal', 'solaris'])
         spec.require_paths = ['lib', 'lib/sunos']
         spec.files += ['lib/sunos/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_sunos.rb'
      when /mswin|win32|dos|cygwin|mingw|windows/i
         spec.platform = Gem::Platform.new(['universal', 'mingw'])
         spec.require_paths = ['lib', 'lib/windows']
         spec.files += ['lib/windows/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_windows.rb'
    end
 
    # https://github.com/rubygems/rubygems/issues/147
    spec.original_platform = spec.platform

    Gem::Builder.new(spec).build
  end

  desc 'Install the sys-proctable library as a gem'
  task :install => [:create] do
    gem_name = Dir['*.gem'].first
    sh "gem install #{gem_name}"
  end
end

task :default => :test
