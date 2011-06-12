require 'rubygems'
require 'bundler'
begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
	# gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
	gem.name = "isc-nmsg-ffi"
	gem.homepage = "http://github.com/chrislee35/isc-nmsg-ffi"
	gem.license = "MIT"
	gem.summary = %Q{FFI extention on ISC's NMSG format}
	gem.description = %Q{The NMSG format is an efficient encoding of typed, structured data
		into payloads which are packed into containers which can be
		transmitted over the network or stored to disk. Each payload is
		associated with a specific message schema. Modules implementing a
		certain message schema along with functionality to convert between
		binary and presentation formats can be loaded at runtime by
		libnmsg. nmsgtool provides a command line interface to control the
		transmission, storage, creation, and conversion of NMSG payloads.}
		gem.email = "rubygems@chrislee.dhs.org"
		gem.authors = ["Chris Lee"]
		# Include your dependencies below. Runtime dependencies are required when using your gem,
		# and development dependencies are only needed for development (ie running rake tasks, tests, etc)
		gem.add_runtime_dependency 'ffi', '>= 1.0.9'
	end
	Jeweler::RubygemsDotOrgTasks.new

	require 'rake/testtask'
	Rake::TestTask.new(:test) do |test|
		test.libs << 'lib' << 'test'
		test.pattern = 'test/**/test_*.rb'
		test.verbose = true
	end

	require 'rcov/rcovtask'
	Rcov::RcovTask.new do |test|
		test.libs << 'test'
		test.pattern = 'test/**/test_*.rb'
		test.verbose = true
	end

	task :default => :test

	require 'rake/rdoctask'
	Rake::RDocTask.new do |rdoc|
		version = File.exist?('VERSION') ? File.read('VERSION') : ""

		rdoc.rdoc_dir = 'rdoc'
		rdoc.title = "isc-nmsg-ffi #{version}"
		rdoc.rdoc_files.include('README*')
		rdoc.rdoc_files.include('lib/**/*.rb')
	end
