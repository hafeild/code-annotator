var OCA = function($){
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

  // Hides all highlighted selections.
  var hideHighlights = function(){
    $('.code .selected').removeClass('selected');
  };

  // Highlights the given comment location. 
  // @param {simple object} loc An object with the fields:
  //    start_line:    The line of code to start on, base 1.
  //    start_column:  The starting column, base 1.
  //    end_line:      The line of code to end on, base 1.
  //    end_column:    The final column to highlight, base 1.
  var highlightSelection = function(loc){
    var i, j;
    for(i = loc.start_line; i <= loc.end_line; i++){
      var start = (i === loc.start_line) ? loc.start_column : 1;
      var end = (i === loc.end_line) ? loc.end_column : 
        $('.content-line'+ i).size();
      console.log('Line '+ i +': '+ start +' to '+ end);
      for(j = start; j <= end; j++){
        $('#'+ i +'_'+ j).addClass('selected');
        // Highlight the endcap if the selection spans to lines below.
        // if(i !== loc.end_line){
        //   $('#'+ i +'_endcap').addClass('selected');
        // }
      }
    }
  };

  // Modifies the displayed file content to make highlighting easier.
  // @param {DOM Elmement} contentElm The element containing the file content.
  //                                  This should already be processed by 
  //                                  SyntaxHighlighter.
  var addColumnsToHighlightedCode = function(contentElm){
    $(contentElm).find('.line').each(function(i,lineElm){
      var children = lineElm.childNodes;
      var i, colNo = 1;
      var lineNo = parseInt(lineElm.className.split(/\s+/)[1].substr(6));
      for(i = 0; i < children.length; i++){
        if(children[i].nodeType === 3){
          var j, newHTML = '';
          for(j = 0; j < children[i].nodeValue.length; j++){
            newHTML += '<span id="'+ lineNo +'_'+ colNo+'" class="content-line'+
              lineNo +' col'+ colNo +' highlightable" data-col='+ colNo +
              '" data-line="'+ lineNo +'">'+ 
              children[i].nodeValue[j] +'</span>';
            colNo++;
          }
          $(children[i]).replaceWith(newHTML);
        } else {
          var j, newHTML = '';
          for(j = 0; j < children[i].innerText.length; j++){
            newHTML += '<span id="'+ lineNo +'_'+ colNo +
              '" class="content-line'+ lineNo   +
              ' col'+ colNo +' highlightable" data-line="'+ lineNo +
              '" data-col="'+ colNo +'">'+ children[i].innerText[j] +
              '</span>';
            colNo++;
          }
          children[i].innerHTML = newHTML;
        }
      }
      lineElm.innerHTML = '<table class="line-wrapper"><tr>'+
        '<td class="line-content">'+ lineElm.innerHTML  +
        '</td><td class="line-endcap content-line'+ lineNo +'" '+
        'id="'+ lineNo +'_'+ colNo +'"'+
        // + lineNo + '_endcap"'
        'data-line="'+ lineNo +'" data-col="'+ colNo +
        '">&nbsp;</td></tr></table>';
    });
  };

  // Determines the line and column offset for a text selection.
  // @param {HTML Node} node The selected node.
  // @param {int} offset The offset of the selected node.
  // @return {simple object} The line and column of the selection.
  var getSelectionOffsets = function(node, offset){
    var parentJQ = $(node.parentNode);
    return {
      line: parseInt(parentJQ.data('line')),
      col:  parseInt(parentJQ.data('col'))
    };
    // var shElm = node.parentNode;
    // var lineElm = $(shElm).parents('.line')[0];
    // var lineNumber = parseInt(lineElm.className.split(/\s+/)[1].substr(6));
    // var colNumber = 1;
    // var children = lineElm.childNodes;
    // var i;

    // // Calculate the column.
    // for(i = 0; i < children.length && children[i] != shElm; i++){
    //   if(children[i].nodeType == 3){
    //     colNumber += children[i].nodeValue.length;
    //   } else {
    //     colNumber += children[i].innerText.length;
    //   }
    // }
    // colNumber += offset;

    // return {line: lineNumber, col: colNumber};
  };

  // Calculates the line and column offsets for the current selection.
  // @return {simple object} The starting column
  var getSelectionLocation = function(){
    var selection = window.getSelection();
    if(!selection || selection.isCollapsed){
      return false;
    }

    var startLocInfo = getSelectionOffsets(selection.anchorNode, 
      selection.anchorOffset);
    var endLocInfo = getSelectionOffsets(selection.extentNode, 
      selection.extentOffset);
    return {
      start_line:   startLocInfo.line,
      start_column: startLocInfo.col, 
      end_line:     endLocInfo.line,
      end_column:   endLocInfo.col
    };
  };

  // Escapes an HTML string.
  // Lifted from Mustache 
  // (https://github.com/janl/mustache.js/blob/master/mustache.js)
  // @param {string} html The HTML string to escape.
  // @return The escaped HTML string.
  var escapeHtml = function(html) {
    return String(html).replace(/[&<>"'\/]/g, function (s) {
      return ENTITY_MAP[s];
    });
  };

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
      (KNOWN_FILE_EXTENSIONS[extension] || KNOWN_FILE_EXTENSIONS['txt']);
    if(extension === 'erb' || extension === 'php'){
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

          addColumnsToHighlightedCode($('#file-display .code')[0])
        }
      },
      error: function(req, status, error){
          $('.page-header').html('ERROR');
          $('#file-display').html(error);
      }
    });
  };

  // Toggles the sidebar and file contents area.
  var toggleFileView = function(){
    $('.sidebar').toggleClass('sidebar-collapse');
    $('.main').toggleClass('main-collapse');
  }

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
      if($('.main').hasClass('main-collapse')){
        toggleFileView();
      }
    });
  }

  $(document).on('click', '.sidebar-toggle', function(){
    toggleFileView();
  })

  // Listens for file content to be selected and then highlights it.
  $(document).on('mouseup', '.code .container', function(){
    console.log('Selection made!');
    var location = getSelectionLocation();
    console.log(location);
    if(location){
      hideHighlights();
      highlightSelection(location);
    }
  });

  // INITIALIZATIONS.

  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.defaults['quick-code'] = false;

  this.getSelectionLocation = getSelectionLocation;
  this.highlightSelection = highlightSelection;
  return this;
};

var oca;

jQuery(document).ready(function($){
  console.log('Hello!');
  oca = OCA($);
  console.log(oca);
})

