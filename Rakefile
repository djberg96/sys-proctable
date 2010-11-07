require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'

desc 'Clean the build files for C versions of sys-proctable'
task :clean do
  rm_rf('.test-result') if File.exists?('.test-result')
  Dir['*.gem'].each{ |f| File.delete(f) }
  Dir['**/*.rbc'].each{ |f| File.delete(f) } # Rubinius
   
  case Config::CONFIG['host_os']
    when /bsd/i
      dir = 'ext/bsd'
    when /darwin/i
      dir = 'ext/darwin'
    when /hpux/i
      dir = 'ext/hpux'
  end

  unless Config::CONFIG['host_os'] =~ /win32|mswin|dos|cygwin|mingw|linux|sunos|solaris/i
    Dir.chdir(dir) do
      if Dir['*.o'].length > 0
        sh 'make distclean'
        Dir['sys/proctable.*'].each{ |f| rm(f) if File.extname(f) != '.c' }
      end
    end
  end
end

desc 'Build the sys-proctable library for C versions of sys-proctable'
task :build => [:clean] do
  case Config::CONFIG['host_os']
    when /bsd/i
      dir = 'ext/bsd'
    when /darwin/i
      dir = 'ext/darwin'
    when /hpux/i
      dir = 'ext/hpux'
  end

  unless Config::CONFIG['host_os'] =~ /win32|mswin|dos|cygwin|mingw|linux|sunos|solaris/i
    Dir.chdir(dir) do
      ruby 'extconf.rb'
      sh 'make'
      cp 'proctable.' + Config::CONFIG['DLEXT'], 'sys'
    end
  end
end

desc 'Install the sys-proctable library'
task :install => [:build] do
  file = nil
  dir  = File.join(Config::CONFIG['sitelibdir'], 'sys')

  Dir.mkdir(dir) unless File.exists?(dir)

  case Config::CONFIG['host_os']
    when /mswin|win32|msdos|cygwin|mingw/i
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
  case Config::CONFIG['host_os']
    when /win32|mswin|dos|cygwin|mingw|linux|sunos|solaris/i
      dir  = File.join(Config::CONFIG['sitelibdir'], 'sys')
      file = File.join(dir, 'proctable.rb')
    else
      dir  = File.join(Config::CONFIG['sitearchdir'], 'sys')
      file = File.join(dir, 'proctable.' + Config::CONFIG['DLEXT'])
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
  t.libs << 'test'
   
  case Config::CONFIG['host_os']
  when /mswin|msdos|cygwin|mingw/i
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

    case Config::CONFIG['host_os']
      when /bsd/i
         spec.files << 'ext/bsd/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/bsd/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_bsd.rb'
         spec.extensions = ['ext/bsd/extconf.rb']
      when /darwin/i
         spec.files << 'ext/darwin/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/darwin/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_darwin.rb'
         spec.extensions = ['ext/darwin/extconf.rb']
      when /hpux/i
         spec.files << 'ext/hpux/sys/proctable.c'
         spec.extra_rdoc_files << 'ext/hpux/sys/proctable.c'
         spec.test_files << 'test/test_sys_proctable_hpux.rb'
         spec.extensions = ['ext/hpux/extconf.rb']
      when /linux/i
         spec.require_paths = ['lib', 'lib/linux']
         spec.files += ['lib/linux/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_linux.rb'
      when /sunos|solaris/i
         spec.require_paths = ['lib', 'lib/sunos']
         spec.files += ['lib/sunos/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_sunos.rb'
      when /mswin|win32|dos|cygwin|mingw/i
         spec.require_paths = ['lib', 'lib/windows']
         spec.files += ['lib/windows/sys/proctable.rb']
         spec.test_files << 'test/test_sys_proctable_windows.rb'
    end

    Gem::Builder.new(spec).build
  end

  desc 'Install the sys-proctable library as a gem'
  task :install => [:create] do
    gem_name = Dir['*.gem'].first
    sh "gem install #{gem_name}"
  end
end

task :default => :test
