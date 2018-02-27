'use strict';

/* FUNCTIONS CALLED BY RUBY */

function deselectAllTools() {
  $('.tool').removeClass('active');
}

function selectTool(id) {
  $('#' + id).addClass('active');
}

function buttonClicked(id) {
  sketchup.buttonClicked(id);
}

$(function () {
  sketchup.documentReady();
  $('button').click(function (event) {
    return buttonClicked(event.currentTarget.id);
  });
});