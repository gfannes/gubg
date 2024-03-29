require_relative("gubg.build/load")

def cooker(&block)
    require("gubg/build/Cooker")
    c = Gubg::Build::Cooker.new
    c.option("c++.std", 20)
    case Gubg.os()
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
        Gubg.each_submod do |info|
            sh "git checkout #{info[:branch]}"
            sh "git pull --rebase"
        end
    rescue Gubg::MissingSubmoduleError
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
        mode = :release
        c.option(mode)
        # c.option("profile")
        c.option("framework", "OpenGL") if Gubg.os == :macos
        c.generate(:ninja, "/gubg/ut")
        c.ninja()
        args = %w[-d yes -a] << filter
        c.run(args)
        # c.debug(args)
    end
end

desc "Run the ruby unit tests"
task :rtest, [:filter] do |t,args|
    dirs = FileList.new("gubg.*/src").to_a()
    ENV['RUBYLIB'] = ([ENV['RUBYLIB']]+dirs)*':'
    filter = args[:filter] || ""
    FileList.new("gubg.*/test/src/**/*.rb").each do |fn|
        if fn[filter]
            puts("Running tests from '#{fn}'")
            sh "ruby #{fn}"
            puts("Done running tests from '#{fn}'")
        end
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

desc 'Generate clangd file'
task :clangd => :prepare do
    include_paths = []
    include_paths += %w[std io].map{|name|"gubg.#{name}/src"}
    include_paths.map!{|ip|File.realdirpath(ip)}
    File.open('.clangd', 'w') do |fo|
        fo.puts('CompileFlags:')
        fo.puts("    Add: [-std=c++20, #{include_paths.map{|ip|"-I#{ip}"}*', '}]")
    end
    cooker() do |c|
        c.generate(:ninja)
        c.ninja_compdb()
    end
end
