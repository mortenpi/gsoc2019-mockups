using Pkg, Revise; Pkg.activate("bulma"; shared=true);
using Documenter
using Documenter.Utilities.JSDependencies: JSDependencies, RemoteLibrary

const jslibraries = [
    RemoteLibrary("jquery", "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.1/jquery.min.js"),
    RemoteLibrary("jqueryui", "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.0/jquery-ui.min.js"),
    RemoteLibrary("headroom", "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.9.4/headroom.min.js"),
    RemoteLibrary(
        "headroom-jquery",
        "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.9.4/jQuery.headroom.min.js",
        deps = ["jquery", "headroom"],
    ),
    # FIXME: upgrade KaTeX to v0.11.0
    RemoteLibrary("katex", "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.2/katex.min.js"),
    RemoteLibrary(
        "katex-auto-render",
        "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.2/contrib/auto-render.min.js",
        deps = ["katex"],
    ),
    RemoteLibrary("highlight", "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.8/highlight.min.js"),
    RemoteLibrary(
        "highlight-julia",
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.8/languages/julia.min.js",
        deps = ["highlight"],
    ),
    RemoteLibrary(
        "highlight-julia-repl",
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.8/languages/julia-repl.min",
        deps = ["highlight"],
    ),
]

function loadsnippet(name)
    snippetfile = joinpath(Documenter.Writers.HTMLWriter.ASSETS, "js", "$(name).js")
    isfile(snippetfile) || error("No such file: $(snippetfile)")
    JSDependencies.parse_snippet(snippetfile)
end

r = let r = JSDependencies.RequireJS(libraries)
    push!(r, loadsnippet("headroom"))
    push!(r, loadsnippet("highlight"))
    push!(r, loadsnippet("katex"))
    push!(r, loadsnippet("settings"))
    push!(r, loadsnippet("sidebar"))
    push!(r, loadsnippet("themes"))
    push!(r, loadsnippet("versions"))
    return r
end

let
    JSDependencies.verify(r)
    println("="^80)
    JSDependencies.writejs(stdout, r)

    p = joinpath(dirname(pathof(Documenter)), "../docs/build/assets/documenter.js")
    JSDependencies.writejs(p, r)
end



# 'lunr': 'https://cdnjs.cloudflare.com/ajax/libs/lunr.js/2.3.5/lunr.min',
# 'lodash': 'https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.11/lodash.min'
push!(r, JSAPI.JSLibrary(
    "lunr",
    "https://cdnjs.cloudflare.com/ajax/libs/lunr.js/2.3.5/lunr.min.js",
    nothing, nothing
))

push!(r, JSAPI.JSLibrary(
    "lodash",
    "https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.11/lodash.min.js",
    nothing, nothing
))

push!(r, JSAPI.JSSnippet(["jquery"], ["\$"],
    JSAPI.js"""
    $(document).ready(function() {
        var version_selector = $("#version-selector");

        // add the current version to the selector based on siteinfo.js, but only if the selector is empty
        if (typeof DOCUMENTER_CURRENT_VERSION !== 'undefined' && $('#version-selector > option').length == 0) {
            var option = $("<option value='#' selected='selected'>" + DOCUMENTER_CURRENT_VERSION + "</option>");
            version_selector.append(option);
        }

        if (typeof DOC_VERSIONS !== 'undefined') {
            var existing_versions = $('#version-selector > option');
            var existing_versions_texts = existing_versions.map(function(i,x){return x.text});
            DOC_VERSIONS.forEach(function(each) {
                var version_url = documenterBaseURL + "/../" + each;
                var existing_id = $.inArray(each, existing_versions_texts);
                // if not already in the version selector, add it as a new option,
                // otherwise update the old option with the URL and enable it
                if (existing_id == -1) {
                    var option = $("<option value='" + version_url + "'>" + each + "</option>");
                    version_selector.append(option);
                } else {
                    var option = existing_versions[existing_id];
                    option.value = version_url;
                    option.disabled = false;
                }
            });
        }

        // only show the version selector if the selector has been populated
        if ($('#version-selector > option').length > 0) {
            version_selector.css("visibility", "visible");
        }

        // Scroll the navigation bar to the currently selected menu item
        $("nav.toc > ul").get(0).scrollTop = $(".current").get(0).offsetTop - $("nav.toc > ul").get(0).offsetTop;
    })
    """
))

function highlightjs(languages = String[])
    hljs_version = "9.15.5"
    libraries = [JSAPI.JSLibrary(
        "highlight",
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(hljs_version)/highlight.min.js",
        nothing, nothing
    )]
    prepend!(languages, ["julia", "julia-repl"])
    for language in languages
        push!(libraries, JSAPI.JSLibrary(
            "highlight-$(language)",
            "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(hljs_version)/languages/$(language).min.js",
            ["highlight"], nothing
        ))
    end
    snippet = JSAPI.JSSnippet(
        vcat(["jquery", "highlight"], ["highlight-$(language)" for language in languages]),
        ["\$", "hljs"],
        JSAPI.js"""
        $(document).ready(function() {
            hljs.initHighlighting();
        })
        """
    )
    (libraries, [snippet])
end

let (libs, snippets) = highlightjs(["yaml"])
    map(x -> push!(r, x), libs)
    map(x -> push!(r, x), snippets)
end

const MathJaxDefaultConfig = Dict(
    :tex2jax => Dict(
        "inlineMath" => [["\$","\$"], ["\\(","\\)"]],
        "processEscapes" => true
    ),
    :config => ["MMLorHTML.js"],
    :jax => [
        "input/TeX",
        "output/HTML-CSS",
        "output/NativeMML"
    ],
    :extensions => [
        "MathMenu.js",
        "MathZoom.js",
        "TeX/AMSmath.js",
        "TeX/AMSsymbols.js",
        "TeX/autobold.js",
        "TeX/autoload-all.js"
    ],
    :TeX => Dict(:equationNumbers => Dict(:autoNumber => "AMS"))
)

function mathjax(config::Dict = MathJaxDefaultConfig)
    config_json = JSON.json(config, 2) # FIXME: JS escapes
    js = """
    MathJax.Hub.Config($(config_json));
    """
    snippet = JSAPI.JSSnippet(["mathjax"], ["MathJax"], js)
    library = JSAPI.JSLibrary(
        "mathjax",
        "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML",
        nothing, "MathJax"
    )
    ([library], [snippet])
end
let (libs, snippets) = mathjax()
    map(x -> push!(r, x), libs)
    map(x -> push!(r, x), snippets)
end

push!(r, JSAPI.JSSnippet(["jquery", "headroom"], ["\$", "Headroom"],
    JSAPI.js"""
    $(document).ready(function() {
        var navtoc = $("nav.toc");
        $("nav.toc li.current a.toctext").click(function() {
            navtoc.toggleClass('show');
        });
        $("article > header div#topbar a.fa-bars").click(function(ev) {
            ev.preventDefault();
            navtoc.toggleClass('show');
            if (navtoc.hasClass('show')) {
                var title = $("article > header div#topbar span").text();
                $("nav.toc ul li a:contains('" + title + "')").focus();
            }
        });
        $("article#docs").bind('click', function(ev) {
            if ($(ev.target).is('div#topbar a.fa-bars')) {
                return;
            }
            if (navtoc.hasClass('show')) {
                navtoc.removeClass('show');
            }
        });
        if ($("article > header div#topbar").css('display') == 'block') {
            var headroom = new Headroom(document.querySelector("article > header div#topbar"), {"tolerance": {"up": 10, "down": 10}});
            headroom.init();
        }
    })
    """
))

let
    JSAPI.verify(r)
    println("="^80)
    JSAPI.writejs(stdout, r)
    JSAPI.writejs("docs/build/assets/documenter.js", r)
end

push!(r, JSAPI.JSSnippet(["jquery", "lunr", "lodash"], ["\$", "lunr"],
    String(read("search.js"))
))
JSAPI.writejs("docs/build/assets/documenter-search.js", r)

let b = IOBuffer()
    write(b, JSAPI.js"""
    // libraries: jquery, xyz
    // args: $
    /// libraries: j_query*
    $(document).ready(function() {
        hljs.initHighlighting();
    })
    """)
    seek(b, 0)
    read_js_snippet(b)
end

Base.:(==)(library::JSAPI.JSLibrary, s::AbstractString) = (library.name == s)
Base.:(==)(s::AbstractString, library::JSAPI.JSLibrary) = (library == s)



# macro jssnippet(name::Symbol)
#     name_str = String(name)
#     quote
#         $(esc(name)) = load_js_snippet($name_str)
#     end
# end
#
# @jssnippet headroom
# @jssnippet highlight
# @jssnippet katex
# @jssnippet settings
# @jssnippet sidebar
# @jssnippet themes
# @jssnippet versions
