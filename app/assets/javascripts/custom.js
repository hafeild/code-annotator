jQuery(document).ready(function($) {


  // Listen for a row to be clicked on. A td element must specifically be 
  // clicked (not a child element) to trigger the page load. For example, see
  // the project listing -- the td with the trash can does not cause the row's
  // href to be loaded.
  $(".clickable-row").click(function(event) {
    if(event.target.tagName === "TD"){
      window.document.location = $(this).data("href");
    }
  });

  
});