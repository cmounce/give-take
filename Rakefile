$LOAD_PATH.unshift __dir__ + '/src'

def include_test_dir(dir)
    Dir.glob(__dir__ + "/test/#{dir}/*.rb").sort.each{|test_file| require_relative test_file}
end

task :default => :'all-test'
task :'all-test' => [:unit, :stat]

task :test => :unit
task :unit do
    include_test_dir 'unit'
end

task :stat do
    include_test_dir 'stat'
end
