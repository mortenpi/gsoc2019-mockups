requirejs.config({
    paths: {
      'jquery': 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.1/jquery.min',
      'jqueryui': 'https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.0/jquery-ui.min',
      'katex': 'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.2/katex.min',
      'katex-auto-render': 'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.2/contrib/auto-render.min',
      //'webfontloader': 'https://cdn.jsdelivr.net/npm/webfontloader@1.6.28/webfontloader',
      'bootstrap': 'https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/js/bootstrap.min',
      'headroom': 'https://cdnjs.cloudflare.com/ajax/libs/headroom/0.9.4/headroom.min',
      'headroom-jquery': 'https://cdnjs.cloudflare.com/ajax/libs/headroom/0.9.4/jQuery.headroom.min',
    },
    shim: {
      'katex': {
        //deps: ['webfontloader'],
      },
      'katex-auto-render': {
        deps: ['katex'],
        //export: 'renderMathInElement',
      },
      'headroom': {
        export: 'Headroom',
      },
      'headroom-jquery': {
        deps: ['headroom', 'jquery'],
      },
    }
});

requirejs(["jquery", "katex", "katex-auto-render"], function($, katex, renderMathInElement) {
  $(document).ready(function() {
    renderMathInElement(
      document.body,
      {
        delimiters: [
          {left: "$", right: "$", display: false},
          {left: "\\[", right: "\\]", display: true},
          {left: "$$", right: "$$", display: true},
        ],
      }
    );
  })
  // window.WebFontConfig = {
  //   custom: {
  //     families: ['KaTeX_AMS', 'KaTeX_Caligraphic:n4,n7', 'KaTeX_Fraktur:n4,n7',
  //       'KaTeX_Main:n4,n7,i4,i7', 'KaTeX_Math:i4,i7', 'KaTeX_Script',
  //       'KaTeX_SansSerif:n4,n7,i4', 'KaTeX_Size1', 'KaTeX_Size2', 'KaTeX_Size3',
  //       'KaTeX_Size4', 'KaTeX_Typewriter'],
  //   },
  // };
  console.log("KaTeX loaded?")
});

requirejs(['jquery'], function($) {
  // Resizes the package name / sitename in the sidebar if it is too wide.
  // Inspired by: https://github.com/davatron5000/FitText.js
  $(document).ready(function() {
    // console.log($("#pagetitle-overflow-box"));
    // console.log($("#pagetitle-overflow-box").width());
    // window.fitText($("#pagetitle-overflow-box"));
    function resize() {
      var L = parseInt($("#pagetitle-overflow-box").css('max-width'), 10);
      var L0 = $("#pagetitle-overflow-box").width();
      if(L0 > L) {
        var h0 = parseInt($("#pagetitle-overflow-box").css('font-size'), 10);
        $("#pagetitle-overflow-box").css('font-size', L * h0 / L0);
        // TODO: make sure it survives resizes?
      }
    }

    // call once and then register events
    resize();
    $(window).resize(resize);
    $(window).on('orientationchange', resize);
  });
});


require(['jquery', 'headroom', 'headroom-jquery'], function($, Headroom) {
    window.Headroom = Headroom;
    $(document).ready(function() {
        var sidebar = $("#sidebar");
        $("nav.toc li.current a.toctext").click(function() {
            navtoc.toggleClass('show');
        });
        $("#menu-button").click(function(ev) {
            ev.preventDefault();
            sidebar.toggleClass('show');
            if (sidebar.hasClass('show')) {
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
        $('#pageheader').headroom({"tolerance": {"up": 10, "down": 10}});
    })
})

requirejs(['jquery', 'devtools'], function($, dev) {
  $(document).ready(function() {
    var devbox = dev.appendWidget($('body'));
    devbox.registerThemeLink(document.getElementById('themecss'));
  });
  $(document).keypress(function(ev) {
    if(ev.ctrlKey && ev.charCode == 25) {
      $('jldebug-devtools').toggle();
    }
  });
});
