// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require jquery
//= require best_in_place
//= require jquery-ui
//= require best_in_place.jquery-ui

//= require bootstrap-datepicker
//= require bootstrap-datepicker/core
//= require jquery.purr
//= require best_in_place.purr
//= require bootstrap-sprockets

//= require_tree .


$(document).ready(function() {
  /* Activating Best In Place */
  jQuery(".best_in_place").best_in_place();


  $("input.datepicker").each(function(input) {
  $(this).datepicker({
    dateFormat: "dd.mm.yy",
    altField: $(this).next()
  })

  // If you use i18n-js you can set the locale like that
  //$(this).datepicker("option", $.datepicker.regional[I18n.currentLocale()]);
})



  
});


$('#uploadForm input').change(function(){
 $(this).parent().ajaxSubmit({
  beforeSubmit: function(a,f,o) {
   o.dataType = 'json';
  },
  complete: function(XMLHttpRequest, textStatus) {
   // XMLHttpRequest.responseText will contain the URL of the uploaded image.
   // Put it in an image element you create, or do with it what you will.
   // For example, if you have an image elemtn with id "my_image", then
   $('#bill').attr('src', XMLHttpRequest.responseText);
   // Will set that image tag to display the uploaded image.
  },
 });
});


