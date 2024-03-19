set_languages("c++20")
add_rules("mode.release") -- Enable with `xmake f -m release`
add_rules("mode.debug")   -- Enable with `xmake f -m debug`

-- The gubg modules with their interdependencies and external include folders
function each_module(cb)
  cb({name = "gubg.std", deps = {}, includes = {}})
  cb({name = "gubg.io", deps = {}, includes = {"gubg.io/extern/json/single_include", "gubg.io/extern/termcolor/include"}})
  cb({name = "gubg.algo", deps = {"gubg.io", "gubg.math"}, includes = {}})
  cb({name = "gubg.math", deps = {}, includes = {}})
  cb({name = "gubg.data", deps = {"gubg.io"}, includes = {}})
  cb({name = "gubg.ml", deps = {"gubg.io", "gubg.math"}, includes = {}})
  cb({name = "gubg.ui", deps = {}, includes = {"gubg.ui/extern/oof"}})
end

-- All headers together to avoid cyclic dependencies
target("gubg.headers")
  set_kind("headeronly")
  each_module(function(na)
    add_includedirs(na.name.."/src", {public=true})
  end)

-- A static library per module
each_module(function (na)
  target(na.name)
    set_kind("static")
    add_files(na.name.."/src/gubg/**.cpp")
    add_deps("gubg.headers")
    for _, inc in ipairs(na.includes) do
      add_includedirs(inc, {public=true})
    end
    for _, dep in ipairs(na.deps) do
      add_deps(dep)
    end
end)

-- A unit test application per module
each_module(function (na)
  target(na.name..".ut")
    set_kind("binary")
    add_includedirs("gubg.std/extern/catch2/single_include/catch2")
    add_files("gubg.std/src/catch_runner.cpp")
    add_files(na.name.."/test/src/**/*_tests.cpp")
    add_includedirs(na.name.."/test/src")
    add_deps(na.name)
    for _, dep in ipairs(na.deps) do
      add_deps(dep)
    end
    before_run(function (target)
      print(string.format("Running UT '%s'", na.name))
    end)
end)


-- Applications from gubg.tools.pm
function each_app(cb)
  cb({name = "org", deps = {"gubg.std", "gubg.io"}})
  cb({name = "time_track", deps = {"gubg.std", "gubg.io"}})
end

each_app(function (na)
  target(na.name)
    set_kind("binary")
    local base = "gubg.tools.pm/src/"
    add_files(base..na.name.."/**.cpp")
    add_includedirs(base)
    for _, dep in ipairs(na.deps) do
      add_deps(dep)
    end
end)
