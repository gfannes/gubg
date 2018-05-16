begin
    require_relative('gubg.build/bootstrap.rb')
rescue LoadError
    sh "git submodule update --init"
    sh "rake uth prepare"
    retry
end
require("gubg/shared")

task :default do
    sh "rake -T"
end

def each_submod(&block)
    gubg_parts = %w[build std io math data algo tools chaiscript tools.pm ui arduino]
    gubg_parts = %w[build std io math data algo ml tools chaiscript tools.pm arduino]
    submods = gubg_parts.map{|n|"gubg.#{n}"}
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
task :build do
    mode = "release"
    # mode = "debug"
    %w[ut tt pa gplot].each do |app|
        sh "cook -g ninja -T c++.std=17 -T #{mode} /#{app}/exe"
        sh "ninja"
        GUBG::publish("#{app}.exe", dst: "bin")
    end
end
task :run => [:prepare, :build]

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
    mode = "release"
    sh "cook -g ninja -T c++.std=17 -T #{mode} /ut/exe"
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

