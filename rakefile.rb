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
    gubg_parts = %w[build std io math data algo tools chaiscript tools.pm ui arduino]
    gubg_parts = %w[build std io math data algo tools chaiscript tools.pm]
    submods = gubg_parts.map{|n|"gubg.#{n}"} + %w[cook]
    GUBG::each_submod(submods: submods, &block)
end
def each_js(&block)
    submods = %w[nodejs].map{|n|"gubg.#{n}"}
    GUBG::each_submod(submods: submods, &block)
end

#Mass tasks
run_mass_task = ->(name){
    each_submod do |info|
        sh("rake #{name}") unless `rake -W #{name}`.empty?
    end
}
[:clean, :prepare, :run, :update].each do |name|
    desc "Mass task: #{name}"
    task name do
        run_mass_task.call(name)
    end
end
task :clean do
    rm_rf ".cook"
    %w[dxf log a out].each do |ext|
        rm_f FileList.new "*.#{ext}"
    end
end

desc "Build and publish the different targets"
task :run => :prepare do
    run_mass_task.call(:run)

    mode = "release"
    # mode = "debug"
    # %w[cook tt pa gplot ut].each do |app|
    %w[ut tt pa gplot].each do |app|
        # %w[cook].each do |app|
        sh "cook.exe -c #{mode} /#{app}/exe"
        sh "ninja"
        GUBG::publish("#{app}.exe", dst: "bin")
    end
end

namespace :cook do
    desc "Install cook from the cook directory"
    task :install do
        Dir.chdir("cook") do
            sh "git submodule update --init --recursive"
            sh "rake install[../bin]"
        end
    end
end

desc "Update submodules to the HEAD of their branch"
task :uth do
    updated = false
    begin
        each_submod do |info|
            sh "git checkout #{info[:branch]}"
            sh "git pull --rebase"
        end
    rescue GUBG::MissingSubmoduleError
        raise if updated
        sh "git submodule update --ini"
        updated = true
        retry
    end
end

desc "Build and run the unit tests"
task :test, [:filter] do |t,args|
    filter = (args[:filter] || "ut").split(":").map{|e|"[#{e}]"}*""
    mode = "debug"
    sh "cook.exe -c #{mode} /ut/exe"
    sh "ninja"
    sh "./ut.exe -d yes -a #{filter}"
end

desc "git diff"
task :diff do
    each_submod{sh 'git diff'}
    sh 'git diff'
end
desc "git status"
task :status do
    each_submod{sh 'git status'}
    sh 'git status'
end
desc "git commit"
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
desc "git push"
task :push do
    each_submod{sh 'git push'}
    sh 'git push'
end

