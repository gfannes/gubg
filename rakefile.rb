def each_submod(&block)
    submods = %w[build std tools ui].map{|n|"gubg.#{n}"}
    submods.each do |sm|
        Dir.chdir(sm) do
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
