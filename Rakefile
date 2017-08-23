$LOAD_PATH.unshift __dir__ + '/src'

def include_test_dir(dir)
    Dir.glob(__dir__ + "/test/#{dir}/*.rb").sort.each{|test_file| require_relative test_file}
end

task :default => :unit

desc "Run all tests"
task :'all-tests' => [:unit, :stat]

desc "Run unit tests"
task :unit do
    include_test_dir 'unit'
end

desc "Run statistical tests (slow)"
task :stat do
    include_test_dir 'stat'
end
