using Sass

function compile(name)
    src = joinpath(@__DIR__, "scss", "$(name).scss")
    dst = joinpath(@__DIR__, "$(name).css")
    isfile(src) || error("$name not at $src")
    Sass.compile_file(src, dst)
end


compile("documenter")
compile("darkly")
