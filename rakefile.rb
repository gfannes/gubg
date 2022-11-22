require_relative("gubg.build/load")

def cooker(&block)
    require("gubg/build/Cooker")
    c = Gubg::Build::Cooker.new
    c.option("c++.std", 17)
    case GUBG.os()
    when :linux
    when :macos
        c.option("target", "x86_64-apple-macos10.15")
    when :windows
    end
    block.yield(c)
end

desc "Update submodules to the HEAD of their branch"
task :uth do
    updated = false
    begin
        GUBG.each_submod do |info|
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
        mode = :debug
        # mode = :release
        c.option(mode)
        # c.option("profile")
        c.option("framework", "OpenGL") if GUBG.os == :macos
        c.generate(:ninja, "/gubg/ut")
        c.ninja()
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

task :default do
    sh "rake -T"
end

desc "Clean all modules"
task :clean => :"gubg:clean"

desc "Prepare all modules"
task :prepare => :"gubg:prepare"

desc "Install all modules"
task :install => :"gubg:install"
