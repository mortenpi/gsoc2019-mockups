# Copyright 2019 Morten Piibeleht
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or
#substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
using FileWatching

function all_subdirectories(d)
    vcat(d, mapreduce(vcat, walkdir(joinpath(@__DIR__, "scss"))) do (root, dirs, _)
        [joinpath(root, d) for d in dirs]
    end)
end


# Setup
const SASSBUILDER_RUNNING = Ref(false)
const SASSBUILDER_TASKS = Ref(Task[])
const SASSBUILDER_OUTDIR = Ref(@__DIR__)
const SASSBUILDER_LOADPATH = Ref(joinpath(@__DIR__, "scss"))
const SASSBUILDER_FILES = Ref(String[])
push!(SASSBUILDER_FILES[], joinpath(@__DIR__, "scss", "documenter.scss"))
push!(SASSBUILDER_FILES[], joinpath(@__DIR__, "scss", "darkly.scss"))
const SASSBUILDER_WATCHING = Ref(String[])
append!(SASSBUILDER_WATCHING[], all_subdirectories(joinpath(@__DIR__, "scss")))
const SASSBUILDER_DEBUG = Ref(false)


# API
function compile(filepath)
    loadpath = SASSBUILDER_LOADPATH[]
    filename = basename(filepath)
    ofile = replace(filename, r".(scss|sass)$" => ".css")
    opath = joinpath(SASSBUILDER_OUTDIR[], ofile)
    cmd = `sassc -I $(loadpath) $(filepath) $(opath)`
    io = IOBuffer()
    if success(pipeline(cmd, stdout=io, stderr=io))
        @info "Compilation of $(filename) successful"
        if SASSBUILDER_DEBUG[]
            sassoutput = String(take!(io))
            @info """Compiled $(filename) successfully
            Command:

            $(cmd)

            With following stdout + stderr:

            $(sassoutput)
            """
        end
        return true
    else
        sassoutput = String(take!(io))
        @warn """Compilation of $(filename) failed.
        Command:

        $(cmd)

        With following stdout + stderr:

        $(sassoutput)
        """
        return false
    end
end
compile_all() = all(map(compile, SASSBUILDER_FILES[]))

function watch_directory(dir)
    @info "Registering watcher for: $(dir)"
    while true
        (f, reason) = watch_folder(dir, 2)
        if reason.changed
            @info "Change: $(f)" dir
            if endswith(f, ".scss") || endswith(f, ".sass")
                compile_all()
            else
                @info "Ignoring $(f) -- not Sass"
            end
        elseif reason.timedout && !SASSBUILDER_RUNNING[]
            @info "Exiting watcher for $(dir)"
            return
        end
    end
end

function watch_all()
    for d in SASSBUILDER_WATCHING[]
        t = @async watch_directory(d)
        push!(SASSBUILDER_TASKS[], t)
    end
end


# Run
compile_all() # to compile all Sass files by hand

# To automatically compile everything on every change:
SASSBUILDER_RUNNING[] = true; watch_all()

# Debugging
SASSBUILDER_DEBUG[] = true # enable
SASSBUILDER_DEBUG[] = false # disable

# To stop all the watchers:
SASSBUILDER_RUNNING[] = false
