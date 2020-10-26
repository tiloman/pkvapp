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
//= require jquery3
//= require jquery_ujs
//= require jquery-ui
//= require popper

//= require bootstrap-sprockets

//= require best_in_place
//= require best_in_place.jquery-ui


//= require jquery.purr
//= require best_in_place.purr
//= require select2
//= require select2_locale_de


//= require moment
//= require fullcalendar
//= require fullcalendar/locale-all

//= require_tree .



function operationsCalendar() {
  var options = {
    events: '/operations.json',
    eventColor: '#016973',
    themeSystem: 'standard',
    defaultView: 'month',
    locale: 'de',
    fixedWeekCount: true,

    header: {
      left: 'prev,next today',
      center: 'title',
      right: 'month,listWeek'
      }
     };

  return $('#calendar').fullCalendar(options);
};

function clearCalendar() {
  $('#calendar').fullCalendar('delete');
  $('#calendar').html('');
};

$(document).on('turbolinks:load', operationsCalendar);
$(document).on('turbolinks:before-cache', clearCalendar)


document.addEventListener("turbolinks:load", function() {

  /* Activating Best In Place */
  $(".best_in_place").best_in_place();


//   $("input.datepicker").each(function(input) {
//   $(this).datepicker({
//     dateFormat: "dd.mm.yy",
//     altField: $(this).next()
//   })
//
//
//   // If you use i18n-js you can set the locale like that
//   //$(this).datepicker("option", $.datepicker.regional[I18n.currentLocale()]);
// })

$( ".select2_form" ).select2({
    theme: "bootstrap"
});


});












document.addEventListener("turbolinks:load", function() {
  $("body").on("change", ".ajax-input", function() {
    Rails.fire(this.form, "submit");
  });



  $('.best_in_place').bind("ajax:success", function () {
    $(this).closest('tr').effect('highlight');
    update_values();
    }
  );

  function update_values(){
    var operation_id = window.location.pathname.split('/')[2];
    var difference = $('#insurance_difference').html();
    difference = parseInt(difference.replace(/,/g,''))

    var insurance_ratio = $('#insurance_ratio').html();
    var insurance_payback = $('#best_in_place_operation_'+ operation_id + '_insurance_payback').html();
    insurance_payback = parseInt(insurance_payback.replace(/,/g,''))
    var assistance_ratio = $('#assistance_ratio').html();
    var assistance_payback = $('#best_in_place_operation_'+ operation_id + '_assistance_payback').html();
    assistance_payback = parseInt(assistance_payback.replace(/,/g,''))
    var value = $('#best_in_place_operation_'+ operation_id + '_value').html();
    value = parseInt(value.replace(/,/g,''))


    $('#insurance_difference').html((Math.round((insurance_payback - (value * (insurance_ratio)))/100 * 100) / 100).toFixed(2));
    $('#insurance_calculated').html((Math.round(value * (insurance_ratio/100)).toFixed(2)));
    $('#assistance_difference').html((Math.round((assistance_payback - (value * (assistance_ratio)))/100 * 100) / 100).toFixed(2));
    $('#assistance_calculated').html((Math.round(value * (assistance_ratio/100)).toFixed(2)));
  }


  function numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }



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



});
