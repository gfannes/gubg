namespace :submodule do
    task :update do
        sh 'git submodule update --init'
    end
end

#Bootstrapping: if we cannot load the local gubg.build/shared.rb, we have to --init and update the git submodules
begin
    require('./gubg.build/shared.rb')
rescue LoadError
    Rake::Task['submodule:update'].invoke
    retry
end

def each_submod(&block)
    submods = %w[build std io tools tools.pm ui nodejs].map{|n|"gubg.#{n}"}
    GUBG::each_submod(submods, &block)
end

task :declare do
    each_submod{sh 'rake declare'}
end
task :define => :declare do
    each_submod{sh 'rake define'}
end
task :test => :define do
    each_submod{sh 'rake test'}
end
task :uth do
    each_submod do
        sh 'git checkout master'
        sh 'git pull --rebase'
    end
end
