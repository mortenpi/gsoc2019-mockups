module JSDeps
using JSON

struct JSRemoteLibrary
    name :: String
    url :: String
    # The following become part of the shim
    deps :: Union{Nothing, Vector{String}}
    exports :: Union{Nothing, String}
end

function shimdict(lib::JSRemoteLibrary)
    isnothing(lib.deps) && isnothing(lib.exports) && return nothing
    shim = Dict{Symbol,Any}()
    if !isnothing(lib.deps)
        shim[:deps] = lib.deps
    end
    if !isnothing(lib.exports)
        shim[:exports] = lib.exports
    end
    return shim
end

struct JSSnippet
    deps :: Vector{String}
    args :: Vector{String}
    js :: String
end

macro js_str(s)
    return s
end

struct RequireJS
    libraries :: Dict{String, JSRemoteLibrary}
    snippets :: Vector{JSSnippet}

    RequireJS() = new(Dict(), [])
end

function shimdict(r::RequireJS)
    shim = Dict{String,Any}()
    for (name, lib) in r.libraries
        @assert name == lib.name
        libshim = shimdict(lib)
        if !isnothing(libshim)
            shim[name] = libshim
        end
    end
    return shim
end

function Base.push!(r::RequireJS, lib::JSRemoteLibrary)
    if lib.name in keys(r.libraries)
        error("Library already added.")
    end
    r.libraries[lib.name] = lib
end

Base.push!(r::RequireJS, s::JSSnippet) = push!(r.snippets, s)

function verify(r::RequireJS)
    for s in r.snippets
        for dep in s.deps
            dep in keys(r.libraries) || error("$(dep) missing from libraries")
        end
    end
end

function writejs(filename::AbstractString, r::RequireJS)
    open(filename, "w") do io
        writejs(io, r)
    end
end

function writejs(io::IO, r::RequireJS)
    write(io, """
    // Generated by Documenter.jl
    requirejs.config({
      paths: {
    """)
    for (name, lib) in r.libraries
        url = endswith(lib.url, ".js") ? replace(lib.url, r"\.js$" => "") : lib.url
        write(io, """
            '$(lib.name)': '$(url)',
        """) # FIXME: escape bad characters
    end
    write(io, """
      },
    """)

    shim = shimdict(r)
    if !isempty(shim)
        write(io, "  shim: ")
        JSON.print(io, shim, 2) # FIXME: escape JS properly
        write(io, ",\n")
    end


    write(io, """
    });
    """)

    for s in r.snippets
        args = join(s.args, ", ") # FIXME: escapes
        deps = join(("\'$(d)\'" for d in s.deps), ", ") # FIXME: escapes
        write(io, """
        require([$(deps)], function($(args)) {
        $(s.js)
        })
        """)
    end
end

"""
    read_js_snippet(filename::AbstractString) -> JSSnippet
    read_js_snippet(io::IO) -> JSSnippet

Parses a JS snippet file into a [`JSSnippet`](@ref) object.
"""
function read_js_snippet end

read_js_snippet(filename::AbstractString; kwargs...) = open(filename, "r") do io
    read_js_snippet(io; kwargs...)
end

function read_js_snippet(io::IO)
    libraries = String[]
    arguments = String[]
    lineno = 1
    while true
        pos = position(io)
        line = readline(io)
        m = match(r"^//\s*([a-z]+):(.*)$", line)
        if m === nothing
            seek(io, pos) # undo the last readline() call
            break
        end
        if m[1] == "libraries"
            libraries = strip.(split(m[2], ","))
            if any(s -> match(r"^[a-z-_]+$", s) === nothing, libraries)
                error("Unable to parse a library declaration '$(line)' on line $(lineno)")
            end
        elseif m[1] == "arguments"
            arguments = strip.(split(m[2], ","))
        end
        lineno += 1
    end
    snippet = String(read(io))
    JSAPI.JSSnippet(libraries, arguments, snippet)
end

# struct JSSnippetParseError
#     key :: String
#     line :: String
#     lineno :: Integer
# end
#
# function Base.showerror(io::IO, err::JSSnippetParseError)
#     println(io, "JSSnippetParseError: bad '$(err.key)' declaration on line $(err.lineno)")
#     println(io, "  attempted to parse: '$(err.line)'")
# end

end
