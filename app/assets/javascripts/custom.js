jQuery(document).ready(function($) {
  // CONSTANTS / GLOBAL VARIABLES
  const FILES_API = '/api/files/';

  var curFileInfo;


  // FUNCTIONS

  // Remove the leading # on a hash.
  // @param [string] hash The hash.
  // @return The hash with leading # removed.
  var stripHash = function(hash){
    return hash.replace( /^#/, "" );
  };

  // Fetch the content of the select file.
  // @param [int] fileId The id of the file to load.
  var displayFile = function(fileId){
    $('#file-display').html('Loading file '+ fileId +'...');

    // Convert the id to an integer (just in case someones putting something
    // funny into the hash).
    fileId = parseInt(fileId)

    // Fetch the file.
    $.ajax(FILES_API+fileId, {
      success: function(data, status){
        if(data.error){
          $('.page-header').html('ERROR');
          $('#file-display').html(data.error);
        } else {
          curFileInfo = data;
          $('.page-header').html(data.file.name);
          $('#file-display');
          $('#file-display').html(
            '<pre class="brush: python">\n'+
                data.file.content + 
            '\n</pre>'
          );
          SyntaxHighlighter.highlight();
          // setTimeout(10, SyntaxHighlighter.highlight);

        }
      },
      error: function(req, status, error){
          $('.page-header').html('ERROR');
          $('#file-display').html(error);
      }
    });
  };


  // LISTENERS

  // Listen for a row to be clicked on. A td element must specifically be 
  // clicked (not a child element) to trigger the page load. For example, see
  // the project listing -- the td with the trash can does not cause the row's
  // href to be loaded.
  $('.clickable-row').click(function(event) {
    if(event.target.tagName === 'TD'){
      window.document.location = $(this).data('href');
    }
  });


  // Collapses/expands directories in the file listings.
  $(document).on('click', '.directory-name', function(){
    var elm = $(this), parent = elm.parent();

    if(parent.data('expand-state') === 'expanded'){
      parent.find('.directory').hide();
      elm.find('.collapsed').show();
      elm.find('.expanded').hide();
      parent.data('expand-state', 'collapsed');
    } else {
      parent.find('.directory').show();
      elm.find('.collapsed').hide();
      elm.find('.expanded').show();
      parent.data('expand-state', 'expanded');
    }
  });

  // Detects when a file's content needs loading.
  if($('#file-display').size() == 1){
    // Check if the initial url contain a hash.
    if(location.hash){
      displayFile(stripHash(location.hash));
    }

    // Wait for any changes to the location hash.
    $(window).on('hashchange', function(){
      displayFile(stripHash(location.hash));
    });
  }

});

