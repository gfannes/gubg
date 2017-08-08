namespace :submodule do
    task :update do
        sh 'git submodule update --init'
    end
end

#Bootstrapping: if we cannot load the local gubg.build/shared.rb, we have to --init and update the git submodules
begin
    require_relative('gubg.build/shared.rb')
rescue LoadError
    Rake::Task['submodule:update'].invoke
    retry
end

require("./cook/load.rb")

task :default do
    sh "rake -T"
end

def each_submod(&block)
    submods = %w[build std io math data algo tools chaiscript tools.pm ui arduino].map{|n|"gubg.#{n}"} + %w[cook]
    GUBG::each_submod(submods: submods, &block)
end
def each_js(&block)
    submods = %w[nodejs].map{|n|"gubg.#{n}"}
    GUBG::each_submod(submods: submods, &block)
end

task :clean do
    each_submod{sh 'rake clean'}
end
task :declare do
    # each_submod{sh 'rake declare'}
end
task :define => :declare do
    mode = "release"
    # mode = "debug"
    %w[cook tt pa gplot ut].each do |app|
        sh "cook.exe -c #{mode} #{app}#exe"
        GUBG::publish("#{app}.exe", dst: "bin")
    end
    # each_submod{sh 'rake define'}
end
task :test, [:filter] => [:define] do |t,args|
    filter = (args[:filter] || "ut").split(":").map{|e|"[#{e}]"}*""
    sh "./ut.exe -d yes -a #{filter}"
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
