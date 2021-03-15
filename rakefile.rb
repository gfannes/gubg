begin
    require_relative('gubg.build/bootstrap.rb')
rescue LoadError
    sh "git submodule update --init"
    sh "rake uth prepare"
    retry
end
require("gubg/shared")

require("mkmf")
ninja_exe = find_executable("ninja")
case GUBG::os
when :windows
    if !ninja_exe
        ninja_exe = "#{ENV["gubg"]}/bin/ninja"
        puts "ninja could not be found, using local version from #{ninja_exe}"
    end
    if !find_executable("cl")
        puts "Could not find the msvc compiler \"cl\", trying to load it myself"
        begin
            require("gubg/msvc")
            GUBG::MSVC::load_compiler(:x64)
            if !find_executable("cl")
                puts "WARING: Could not find the msvc compiler \"cl\":"
                puts "* [must] Install Microsoft Visual Studio 2017"
                puts "* [optional] Run \"C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvars32.bat\" or other bat file to load it"
                # raise "stop"
            end
        rescue LoadError
            puts "WARNING: Could not load gubg/msvc, run \"rake uth prepare\""
        end
    end
end

task :default do
    sh "rake -T"
end

def each_submod(&block)
    gubg_parts = %w[build std io math data algo tools chaiscript tools.pm ui arduino]
    gubg_parts = %w[build std io math data algo ml tools chaiscript tools.pm arduino ui]
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
[:clean, :proper, :prepare, :run, :update].each do |name|
    desc "Mass task: #{name}"
    task name do
        run_mass_task.call(name)
    end
end
task :clean do
    rm_rf ".cook"
    %w[dxf log a out pdb exe lib resp].each do |ext|
        rm_f FileList.new "*.#{ext}"
    end
end
task :proper => :clean do
    rm_rf "extern"
end

def cooker(&block)
    require("gubg/build/Cooker")
    c = GUBG::Build::Cooker.new
    case GUBG::os
    when :windows then c.option("c++.std", 17)
    else c.option("c++.std", 17) end
    block.yield(c)
end

desc "Build and publish the different targets"
task :build, [:mode] do |t,args|
    default_mode = "release"
    # default_mode = "debug"
    mode = args[:mode]||default_mode
    %w[time_track pa pit pigr gplot chai sedes].each do |app|
        cooker do |c|
            c.option(mode)
            c.output("./")
            c.generate(:ninja, "/#{app}/exe")
            c.ninja
        end
        exe_fn = "#{app}.exe"
        exe_fn << ".exe" if GUBG::os == :windows
        GUBG::publish(exe_fn, dst: "bin"){|fn|fn.gsub(/\.exe$/, "")}
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
    cooker do |c|
        mode = "debug"
        # mode = "release"
        c.option(mode)
        # c.option("profile")
        c.generate(:ninja, "/gubg/ut")
        c.ninja
        args = %w[-d yes -a] << filter
        c.run(args)
        # c.debug(args)
    end
end

desc "Run the python unit tests"
task :ptest, [:filter] do |t,args|
    filter = args[:filter] || ""
    FileList.new("gubg.*/test/src/**/*.py").each do |fn|
        if fn[filter]
            puts(fn)
            sh "pytest -s #{fn}"
        end
    end
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

namespace :pit do
  desc "manual test"
  task :manual, [:uri] => :build do |t,args|
    uri = args[:uri] || ""
    uri = "-u #{uri}" unless uri.empty?
    sh "pit -v -r resources.pit -p -f sprint:sprint.pit -f pit:pit.pit -f tt:gubg.tools.pm/tt.pit #{uri} -o test.tsv"
  end

  desc "bulk tests"
  task :test => :build do
    test_cases = [1, 2, 3, 4]
    test_cases.each do |tc|
      base = "gubg.tools.pm/src/app/test/pit"
      Dir.chdir(File.join(base, tc.to_s)) do
        case tc
        when 1
          sh "pit -v -f wbs.pit -d . "
          sh "pit -v -f wbs.pit -d 10.0 -p -o plan.tsv -u product"
        when 2
          sh "pit -f wbs.pit -r r.pit -p"
        when 3
          sh "pit -f wbs.pit"
        when 4
          sh "pit -f wbs.pit"
        end
      end
    end
  end
end

namespace :sedes do
  desc "End to end tests"
  task :ee => :build do
    test_cases = (0...3).to_a
    test_cases.each do |tc|
      base = "gubg.io/test/ee/sedes"
      Dir.chdir(GUBG.mkdir(base, tc)) do
        case tc
        when 0
          sh "sedes -h"
        when 1
          sh "sedes" do |ok,res|
            raise "Should fail without arguments" if ok
          end
        when 2
          sh "sedes -i abc.naft -o abc.hpp"
          sh "cat abc.hpp"
          cooker = GUBG::Build::Cooker.new
          cooker.option("c++.std", 17).generate(:ninja, "app").ninja()

          %w[empty optional array].each do |what|
            hr_fn = {a: "hr.#{what}.a.txt", b: "hr.#{what}.b.txt"}
            naft_fn = {a: "naft.#{what}.a.txt", b: "naft.#{what}.b.txt"}
            cooker.run("create", what, "hr.write", hr_fn[:a], "naft.write", naft_fn[:a])
            cooker.run("naft.read", naft_fn[:a], "hr.write", hr_fn[:b], "naft.write", naft_fn[:b])
          end
        end
      end
    end
  end
end

namespace :autoq do
    desc "End to end tests"
    task :ee => :build do
        test_cases = (0...2).to_a
        test_cases.each do |tc|
            base = "gubg.tools/test/ee/autoq"
            Dir.chdir(GUBG.mkdir(base, tc)) do
                case tc
                when 0
                    sh "autoq -h"
                when 1
                    sh "autoq system system.ssv target target.ssv population 100 iteration 200"
                end
            end
        end
    end
end
