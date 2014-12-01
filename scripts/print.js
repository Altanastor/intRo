var content;

function print_clicked() {
    Shiny.onInputChange("print_clicked", true);
}

Shiny.addCustomMessageHandler("renderFinished",
  function(file) {
    var frame = $('.print_results')
    frame.attr('src', file);
    
    content = frame.contents().find("body").html();
    check_print(frame)
  })

function check_print(frame) {
  if (frame.contents().find("body").html() == content) {
    setTimeout(check_print, 500, frame);
  } else {
    $('.print_results').get(0).contentWindow.print();
    Shiny.onInputChange("print_clicked", false);
  }    
}