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
    submods = %w[build std io math data algo tools chaiscript tools.pm ui arduino].map{|n|"gubg.#{n}"}
    GUBG::each_submod(submods, &block)
end
def each_js(&block)
    submods = %w[nodejs].map{|n|"gubg.#{n}"}
    GUBG::each_submod(submods, &block)
end

task :clean do
    each_submod{sh 'rake clean'}
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
task :diff do
    each_submod{sh 'git diff'}
    sh 'git diff'
end
task :status do
    each_submod{sh 'git status'}
    sh 'git status'
end
task :commit, :msg do |task, args|
    msg = args[:msg]
    raise('You have to specify the commit message as "rake commit["<commit message>"]"') unless msg
    each_submod do
        if !`git status --porcelain`.empty?
            sh "git commit -am \"#{msg}\""
            sh "git pull --rebase"
            sh "git push"
        end
    end
    if !`git status --porcelain`.empty?
        sh "git commit -am \"#{msg}\""
        sh "git pull --rebase"
        sh "git push"
    end
end
task :uth do
    updated = false
    begin
        each_submod do
            sh 'git checkout master'
            sh 'git pull --rebase'
        end
    rescue GUBG::MissingSubmoduleError
        raise if updated
        sh 'git submodule update --init'
        updated = true
        retry
    end
end
