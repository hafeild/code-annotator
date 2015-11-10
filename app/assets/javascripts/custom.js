jQuery(document).ready(function($) {
  // CONSTANTS / GLOBAL VARIABLES
  const FILES_API = '/api/files/';
  const KNOWN_FILE_EXTENSIONS = {
    as3:  'as3',
    sh:   'bash',
    cf:   'coldfusion',
    cs:   'csharp',
    cpp:  'cpp',
    h:    'cpp',
    hpp:  'cpp',
    c:    'cpp',
    cc:   'cpp',
    cxx:  'cpp',
    hxx:  'cpp',
    css:  'css',
    scss: 'css',
    dpk:  'delphi',
    diff: 'diff',
    patch:'patch',
    erl:  'erlang',
    gy:   'groovy',
    gsh:  'groovy',
    gvy:  'groovy',
    groovy:'groovy',
    js:   'javascript',
    json: 'javascript',
    java: 'java',
    jfx:  'javafx',
    pl:   'perl',
    php:  'php',
    txt:  'text',
    ps:   'powershell',
    py:   'python',
    rb:   'ruby',
    erb:  'ruby',
    scala:'scala',
    sql:  'sql',
    vb:   'vb',
    vbnet:'vb',
    xml:  'xml',
    html: 'xml',
    xhtml:'xml'
  };

  // Lifted from Mustache 
  // (https://github.com/janl/mustache.js/blob/master/mustache.js)
  const ENTITY_MAP = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': '&quot;',
    "'": '&#39;',
    "/": '&#x2F;'
  };

  var curFileInfo;


  // FUNCTIONS

  // Escapes an HTML string.
  // Lifted from Mustache 
  // (https://github.com/janl/mustache.js/blob/master/mustache.js)
  // @param {string} html The HTML string to escape.
  // @return The escaped HTML string.
  function escapeHtml(html) {
    return String(html).replace(/[&<>"'\/]/g, function (s) {
      return ENTITY_MAP[s];
    });
  }

  // Extracts the extension from a file name.
  // @param {string} filename The name of the file.
  // @return The extension (last .XXX) or undefined if no extension is found.
  var extractExtension = function(filename){
    var parts = filename.split('.');
    if(parts.length > 1){
      return parts[parts.length-1];
    }
    return undefined;
  };

  // Figures out the highlighter class for the given file.
  // @param {string} filename The name of the file.
  // @return The highlighter class corresponding to the extension; defaults to
  //         the plain text highligher if no extension is found, or no 
  //         corresponding highlighter is found.
  var getHighlighterClass = function(filename){
    var extension = extractExtension(filename);
    var returnClass = 'brush: '+ 
      KNOWN_FILE_EXTENSIONS[extension] || KNOWN_FILE_EXTENSIONS['txt'];;
    if(extension === 'erb' || extension === 'rb'){
      returnClass += "; html-script: true";
    }
    return returnClass;
  };

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
            '<pre class="'+ getHighlighterClass(data.file.name) +'">\n'+
                escapeHtml(data.file.content) + 
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

