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

  // lid = Local ID; sid = Server ID
  var commentLidToSidMap = {};
  var commentLocLidToSidMap = {};
  var curFileInfo;
  var commentIdCounter = 0;
  var locationIdCounter = 0;

  // FUNCTIONS

  var deleteComment = function(commentId){
    var locations = $('#comment-'+ commentId).data('locations');
    var i;
    for(i = 0; i < locations.length; i++){
      deleteCommentLocation(commentId, locations[i].lid, true);
    }
  };

  var deleteCommentLocation = function(commentId, locationId, removeComment){
    $('.comment_loc_'+ locationId).each(function(){
      var elm = $(this);
      elm.removeClass('comment_loc_'+locationId);

      removeFromDataArray(elm, 'locationIds', locationId);

      if(removeComment || elm.data('locationIds').length === 0){
        removeFromDataArray(elm, 'commentIds', commentId);
        elm.removeClass('comment_'+ commentId);
        elm.removeClass('selected');
      }
    });

  };

  var hideCommentLocationHighlights = function(){
    $('.comment-location-highlight').removeClass('comment-location-highlight');
  };

  var highlightCommentLocations = function(commentId){
    hideCommentLocationHighlights();
    $('.comment_'+ commentId).addClass('comment-location-highlight');
  };

  var removeFromDataArray = function(elm, key, value){
    var array =  elm.data(key) || []; 
    var index = array.indexOf(value);
    if(index >= 0){
      array.splice(index,1);
      elm.data(key, array);
    }
  };

  var addToElmDataArray = function(elm, key, value){
    var array =  elm.data(key) || []; 
    if(array.indexOf(value) < 0){
      array.push(value);
      elm.data(key, array);
    }
  };

  var markCommentLocations = function(comment){
    var locations = comment.data('locations'), i;
    for(i = 0; i < locations.length; i++){
      if(!locations[i].file_id || locations[i].file_id === curFileInfo.id){
        highlightSelection(locations[i], 'comment_loc_'+ locations[i].lid +
          ' comment_'+ comment.data('lid'), true);

        $('.comment_loc_'+ locations[i].lid).each(function(){
          var elm = $(this);
          addToElmDataArray(elm, 'commentIds', comment.data('lid'));
          addToElmDataArray(elm, 'locationIds', locations[i].lid);
        });
      }
    }
    
  };

  var editComment = function(e){
    var target = $(e.target);
    if(target.data('content') === target.html()){ return; }

    target.addClass('comment-in-edit');
    if(target.data('timeout')){
      clearTimeout(target.data('timeout'));
    }

    // TODO: This needs to actually save the comment changes.
    target.data('timeout', setTimeout(function(){
      target.removeClass('comment-in-edit');
      target.parent().find('.comment-saved').show().fadeOut(2000);
      target.data('content', target.html());
    }, 2000));
  };

  var compareLocations = function(loc1, loc2){
    if(loc1.start_location === loc2.start_location){
      return loc1.start_column - loc2.start_column;
    }
    return loc1.start_location - loc2.start_location;
  }

  var getFirstLocation = function(locations, fileId){
    var sorted = locations.sort(compareLocations);
    var i;
    for(i = 0; i < sorted.length; i++){
      if(sorted[i].file_id === fileId){
        return sorted[i];
      }
    }
  };

  var insertComment = function(comment, container){
    var inserted = false;
    container.children().each(function(i, e){
      var child = $(this);
        // comment.data('start-line'));
      if(child.data('start-line') > comment.data('start-line') ||
          (child.data('start-line') === comment.data('start-line') &&
            child.data('start-column') > comment.data('start-column'))){
        comment.insertBefore(child);
        inserted = true;
        return;
      }
    });
    // If we've reached this point, then the comment should go at the end.
    if(!inserted){
      container.append(comment);
    }
  }

  // Creates a comment with the given locations.
  // @param {array of simple objects} locations A list of locations.
  // @param {string} content The comment content. Defaults to ''.
  // @return The comment that was created.
  var createComment = function(locations, content){
    content = content || '';
    var commentId = commentIdCounter++;
    var firstLocation = getFirstLocation(locations, curFileInfo.id);
    var comment = $('#comment-template').clone();
    comment.attr('id', 'comment-'+ commentId);
    comment.find('.comment-owner').html($('#current-email').html());
    comment.data('start-line', firstLocation.start_line).
            data('start-column', firstLocation.start_column);
    // Find the spot where this comment should be inserted.
    insertComment(comment, $('#comments'));
    // $('#comments').append(comment);
    comment.data('locations', locations);
    var body = comment.find('.comment-body');
    body.html(content).data('content', content);
    body.focus();

    comment.data('lid', commentId);
    markCommentLocations(comment);
    highlightCommentLocations(commentId);
    return comment;
  };

  // Hides all highlighted selections.
  var hideHighlights = function(){
    $('.code .selected').removeClass('selected');
  };

  var normalizeLocation = function(loc){
    var normLoc = {};
    if(loc.start_line < loc.end_line || 
        (loc.start_line === loc.end_line && loc.start_column < loc.end_column)){
      normLoc.start_line    = loc.start_line;
      normLoc.start_column  = loc.start_column;
      normLoc.end_line      = loc.end_line;
      normLoc.end_column    = loc.end_column;
    } else {
      normLoc.start_line   = loc.end_line;
      normLoc.start_column = loc.end_column+1;
      normLoc.end_line     = loc.start_line;
      normLoc.end_column   = loc.start_column;
    }
    return normLoc;
  };

  // Highlights the given comment location. 
  // @param {simple object} loc An object with the fields:
  //    start_line:    The line of code to start on, base 1.
  //    start_column:  The starting column, base 1.
  //    end_line:      The line of code to end on, base 1.
  //    end_column:    The final column to highlight, base 1.
  // @param {string} cssClass The CSS class to add or remove to the selected 
  //                          elements. Defaults to 'selected'.
  // @param {boolean} add Whether the cssClass should be added to or removed
  //                      from the selected elements. Defaults to true.
  var highlightSelection = function(loc, cssClass, add){
    loc = normalizeLocation(loc);
    var i, j;
    cssClass = cssClass || 'selected';
    add = add === undefined ? true : add;
    for(i = loc.start_line; i <= loc.end_line; i++){
      var start = (i === loc.start_line) ? loc.start_column : 1;
      var end = (i === loc.end_line) ? loc.end_column : 
        $('.content-line'+ i).size();
      for(j = start; j <= end; j++){
        if(add){
          $('#'+ i +'_'+ j).addClass(cssClass);
        } else {
          $('#'+ i +'_'+ j).removeClass(cssClass);
        }
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
      lineElm.innerHTML = '<div class="line-wrapper">'+
        '<div class="line-content">'+ lineElm.innerHTML  +
        '</div><div class="line-endcap content-line'+ lineNo +'" '+
        'id="'+ lineNo +'_'+ colNo +'"'+
        // + lineNo + '_endcap"'
        'data-line="'+ lineNo +'" data-col="'+ colNo +
        '">&nbsp;</div></div>';
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
      lid:          locationIdCounter++,
      file_id:      curFileInfo.file_id,
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
    $('#comments').html('');
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
          curFileInfo = data.file;
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

          loadFileComments(data.file.comments);
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

  var loadProjectComments = function(){

  };

  var loadFileComments = function(comments){
    var i, j;
    for(i = 0; i < comments.length; i++){
      //comments[i].lid = commentIdCounter++;
      for(j = 0; j < comments[i].locations.length; j++){
        comments[i].locations[j].lid = locationIdCounter++;
        highlightSelection(comments[i].locations[j]);
      }
      createComment(comments[i].locations, comments[i].content);
    }
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
    var location = getSelectionLocation();
    if(location){
      $('#selection-menu .btn').removeClass('disabled');
      //hideHighlights();
      //highlightSelection(location);
    } else {
      // hideHighlights();
      hideCommentLocationHighlights();
      $('#selection-menu .btn').addClass('disabled');
    }
  });

  $(document).on('click', '#selection-menu .btn', function(e){
    var location = getSelectionLocation();
    highlightSelection(location);
    if(e.target.id === 'add-comment'){
      console.log('Adding comment');
      createComment([location]);
    } else if(e.target.id === 'add-to-comment'){
      console.log('Adding to existing comment');
    } else if(e.target.id === 'add-alt-code'){
      console.log('Adding alternate code');
    }

  });

  $(document).on('click', '.comment-delete', function(e){
    var comment = $(this).parents('.comment');
    hideCommentLocationHighlights();
    deleteComment(comment.data('lid'));
    comment.remove();
    e.preventDefault();
  });

  $(document).on('change', '.comment-body', editComment);
  $(document).on('keyup', '.comment-body', editComment);
  $(document).on('mouseup', '.comment-body', editComment);

  $(document).on('mouseover', '.comment', function(){
    highlightCommentLocations($(this).data('lid'));
  });

  $(document).on('click', '.selected', function(){
    var commentIds = $(this).data('commentIds');
    console.log(commentIds);
    if(commentIds && commentIds.length > 0){
      highlightCommentLocations(commentIds[0]);
      // Find the comment, scroll to it, and focus on it.
      var comment = $('#comment-'+ commentIds[0]);
      $('#comments').scrollTop(comment[0].offsetTop);
      comment.find('.comment-body ').focus();
    }
  });

  // INITIALIZATIONS.
  if(window.location.pathname.match(/^\/projects\/\d+$/)){
    // loadProjectComments();
  }


  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.defaults['quick-code'] = false;

  this.getSelectionLocation = getSelectionLocation;
  this.highlightSelection = highlightSelection;
  return this;
};

var oca;

jQuery(document).ready(function($){
  oca = OCA($);
})

