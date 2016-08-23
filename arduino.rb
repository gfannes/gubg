require(File.join(ENV['gubg'], 'shared'))
require('gubg/build/Executable')
include GUBG

task :clean do
    rm_rf '.cache'
end

task :default => :clean do
    sh "rake define"
    blink = Build::Executable.new('blink', arch: :uno)
    blink.add_sources('blink.cpp')
    blink.add_library_path(shared_dir('lib'))
    # blink.add_library('arduino-core')
    blink.build
end
