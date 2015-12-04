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
    submods = %w[build std io tools tools.pm ui].map{|n|"gubg.#{n}"}
    submods.each do |sm|
        Dir.chdir(sm) do
            raise("There is no rakefile present here: run a \"git submodule update --init\" to initialize and clone it") unless File.exist?('rakefile.rb')
            puts(">>>>>>>>> #{sm}")
            yield(sm)
            puts("<<<<<<<<< #{sm}\n\n")
        end
    end
end

task :declare do
    each_submod{sh 'rake declare'}
end
task :define => :declare do
    each_submod{sh 'rake define'}
end
task :uth do
    each_submod do
        sh 'git checkout master'
        sh 'git pull --rebase'
    end
end
