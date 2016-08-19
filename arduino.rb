require(File.join(ENV['gubg'], 'shared'))
require('gubg/build/Executable')
include GUBG

blink = Build::Executable.new('blink', arch: :uno)
blink.add_sources('blink.cpp')

task :default do
    sh "rake declare"
    blink.build
end
