require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name     = "machinist"
    gem.summary  = "Fixtures aren't fun. Machinist is."
    gem.email    = "pete@notahat.com"
    gem.homepage = "http://github.com/notahat/machinist"
    gem.authors  = ["Pete Yandell"]
    gem.has_rdoc = false
    gem.add_development_dependency "rspec", ">= 1.2.8"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end


require 'spec/rake/spectask'
desc 'Run the specs.'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Run the specs with rcov.'
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

desc 'Run the specs.'
task :default => :spec
