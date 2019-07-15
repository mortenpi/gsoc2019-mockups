requirejs.config({
  paths: {
    'jquery': 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min',
  }
});

require(['jquery'], function($) {
  $('body').addClass($('#fontclass option:selected').attr('value'));

  $('#borders').click(function(){;
    $('body').toggleClass("borders");
  });

  $('#fontclass').change(function(){
    $('body').attr("class").split(/\s+/).forEach(function(s) {
      if(s.startsWith("font-")) $('body').removeClass(s);
    })
    $('body').addClass($('#fontclass option:selected').attr('value'));
  });
})
