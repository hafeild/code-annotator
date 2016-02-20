var CodeAnnotator = function($){
  // CONSTANTS / GLOBAL VARIABLES
  const PROJECT_ID = $('#project-id').data('project-id');
  const FILES_API = '/api/projects/'+ PROJECT_ID +'/files/'; //'/api/files/';
  const PROJECT_API = '/api/projects/'+ PROJECT_ID;
  const COMMENT_API = PROJECT_API +'/comments';
  const MAX_PROJECT_SIZE_BYTES = 1024*1024; // 1MB.
  const MAX_PROJECT_SIZE_MB = MAX_PROJECT_SIZE_BYTES/1024/1024;
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
  var commentLocLidToCommentLidMap = {};
  var curFileInfo;
  var commentLidCounter = 0;
  var locationLidCounter = 0;
  var locationLidLastSelected = -1;
  var locationIndexLastSelected = 0;
  var locationToAddToComment;
  var altcodeLidToSidMap = {};
  var altcodeLookup = {};
  var altcodeLidCounter = 0;
  var selectedDirectory;

  // FUNCTIONS

  /**
   * Displays an error message.
   *
   * @param {string} message The message to display.
   */
  var displayError = function(message){
    var errorElm = $('#alert-danger-template').clone().attr('id', '').
      appendTo('#alerts');
    errorElm.find('.alert-message').html(message);
  }

  /**
   * Removes a project from the server.
   *
   * @param {int} projectId The id of the project to remove.
   * @param {function} onSuccess A function to call after successfully removing
   *                             the project.
   */
  var deleteProject = function(projectId, onSuccess){
    $.ajax('/api/projects/'+ projectId, {
      method: 'POST',
      data: {
        _method: 'delete'
      },
      success: function(data){
        if(data.error){
          displayError('There was an error removing this project: '+data.error);
          return;
        }

        onSuccess(data);
      },
      error: function(xhr, status, error){
        displayError('There was an error removing this project. '+ error);
      }
    });
  };

  /**
   * Deletes a comment from the UI and the server.
   *
   * @param {string} commentLid The local id of the comment to remove.
   */
  var deleteComment = function(commentLid){
    var commentElm = $('#comment-'+ commentLid);
    var locations = commentElm.data('locations');
    var commentId = commentLidToSidMap[commentLid];

    if(commentElm.data('deletedFromServer')) return;

    $.ajax('/api/comments/'+ commentId,{
      method: 'POST',
      data: {
        _method: 'delete'
      },
      success: function(data){
        if(data.error){
          displayError('There was an error deleting the comment: '+ data.error);
          return;
        }

        // Mark the commented as deleted from the server.
        commentElm.data('deletedFromServer', true);

        while(locations.length > 0){
          removeCommentLocationFromUI(commentLid, locations[0].lid, true);
        }

      },
      error: function(xhr, status, error){
        displayError('There was an error deleting the comment. '+ error);
      }
    });
  };

  /**
   * Removes a comment location from the UI and the server.
   *
   * @param {string} commentLid The local id of the comment.
   * @param {string} locationLid The local id of the location to remove.
   * @param {boolean} removeComment A flag indicating whether all locations for
   *                  the given comment are to be removed (assists in some
   *                  corner cases).
   */
  var deleteCommentLocation = function(commentLid, locationLid, removeComment){
    $.ajax('/api/comment_locations/'+ commentLocLidToSidMap[locationLid], {
      method: 'POST',
      data: {
        _method: 'delete'
      },
      success: function(data){
        if(data.error){
          displayError('There was an error removing the comment location: '+
            data.error);
          return;
        }

        removeCommentLocationFromUI(commentLid, locationLid, removeComment);

      },
      error: function(xhr, status, error){
        displayError('There was an error removing the comment location. '+
          error);
      }
    });
  };

  /**
   * Removes a comment location from the UI.
   *
   * @param {string} commentLid The local id of the comment.
   * @param {string} locationLid The local id of the location to remove.
   * @param {boolean} removeComment A flag indicating whether all locations for
   *                  the given comment are to be removed (assists in some
   *                  corner cases).
   */
  var removeCommentLocationFromUI = function(commentLid, locationLid, removeComment){
    // Get rid of the 'remove' icon next to the comment location.
    hideCommentLocationHighlights();
    $('#remove-'+ locationLid).remove();

    // Remove information about this comment location from each of the
    // character elements in the location.
    $('.comment_loc_'+ locationLid).each(function(){
      var elm = $(this);
      elm.removeClass('comment_loc_'+locationLid);

      removeFromDataArray(elm, 'locationLids', locationLid);

      if(removeComment || elm.data('locationLids').length === 0){
        removeFromDataArray(elm, 'commentLids', commentLid);
        elm.removeClass('comment_'+ commentLid);
      }
      if(elm.data('locationLids').length === 0){
        elm.removeClass('selected');
      }
    });

    // Remove the comment location from the comment itself.
    var comment = $('#comment-'+ commentLid),
        locations = comment.data('locations'),
        i, curLocation;

    if(locations){
      for(i = 0; i < locations.length; i++){
        curLocation = locations[i];
        if(locations[i].lid === locationLid){
          locations.splice(i,1);
          break;
        }
      }

      // Determine if we need to decrement comments.
      if(getCommentLocationCountInFile(locations, curLocation.file_id) === 0){
        incrementBadgeCount('comment-count', -1, curLocation.file_id);
      }

    }

    // Check if the comment needs to be removed because there are no more
    // locations associated with it.
    if(commentLidToSidMap[commentLid] !== undefined &&
        locations && locations.length === 0){

      deleteComment(commentLid);
      comment.remove();

    // Check if the comment needs to be removed from the list of file
    // comments because there are no more locations in this file associated
    // with it. We only do this if we're not removing all comment locations.
    } else if(!removeComment && commentLidToSidMap[commentLid] !== undefined &&
        locations && locations.length > 0 && 
        getCommentLocationCountInFile(locations) === 0){

      comment.remove();
      delete commentLidToSidMap[commentLid];
    }
  }


  /**
   * Counts the number of locations for the given comment are associated with
   * the currently displayed file.
   *
   * @param {array of simple objects} locations The list of locations to check.
   * @param {int} fileId The id of the file to count locations in. Defaults to
   *                     the current file id.
   * @return The number of comment locations in the given file.
   */
  var getCommentLocationCountInFile = function(locations, fileId){
    // var locations = $('#comment-'+ commentLid).data('locations') || [];
    locations = locations || [];
    var i, locationsInCurrentFile = 0;
    fileId = fileId || curFileInfo.id;

    for(i = 0; i < locations.length; i++){
      if(locations[i].file_id === undefined || 
          locations[i].file_id === fileId){
        locationsInCurrentFile++;
      }
    }
    return locationsInCurrentFile;
  }

  /**
   * Hides all comment location highlights.
   */
  var hideCommentLocationHighlights = function(){
    $('.comment-location-highlight').removeClass('comment-location-highlight');
  };

  /**
   * Hides all comment locations.
   *
   * @param {string} commentLid The local id of the comment whose locations
   *                            should be hidden.
   */
  var highlightCommentLocations = function(commentLid){
    hideCommentLocationHighlights();
    hideRemoveLocationButtons();  
    $('.comment_'+ commentLid).addClass('comment-location-highlight');
  };

  /**
   * Removes a value from an array stored with key in the data of elm.
   *
   * @param {jQuery Elm} elm The element whose data will be modified.
   * @param {string} key The key that the array is stored under.
   * @param {anything} value The value to remove from the array. 
   */
  var removeFromDataArray = function(elm, key, value){
    var array =  elm.data(key) || []; 
    var index = array.indexOf(value);
    if(index >= 0){
      array.splice(index,1);
      elm.data(key, array);
    }
  };

  /**
   * Adds a value to an array stored with key in the data of elm.
   *
   * @param {jQuery Elm} elm The element whose data will be modified.
   * @param {string} key The key that the array is stored under.
   * @param {anything} value The value to add to the array. 
   */
  var addToElmDataArray = function(elm, key, value){
    var array =  elm.data(key) || []; 
    if(array.indexOf(value) < 0){
      array.push(value);
      elm.data(key, array);
    }
  };

  /**
   * Goes through the given comment locations, finds the corresponding
   * characters in the displayed code, and adds information to each character to
   * link it to that location and the comment.
   *
   * @param {int} commentLid The local id of the comment.
   * @param {array of simple objects} locations The comment locations to mark.
   */
  var markCommentLocations = function(commentLid, locations){
    for(i = 0; i < locations.length; i++){
      if(locations[i].file_id === undefined || 
          locations[i].file_id === curFileInfo.id){

        // Attach a remove button to the selection.
        var closeElm = $('<span>').attr('id', 'remove-'+ locations[i].lid).
          addClass('location-removal-button').
          html('<span class="glyphicon glyphicon-remove-circle"></span>').
          data('lid', locations[i].lid);
        $('#'+ locations[i].start_line +'_'+ locations[i].start_column).
          append(closeElm);

        highlightSelection(locations[i], 'comment_loc_'+ locations[i].lid +
          ' comment_'+ commentLid, true);

        $('.comment_loc_'+ locations[i].lid).each(function(){
          var elm = $(this);
          addToElmDataArray(elm, 'commentLids', commentLid);
          addToElmDataArray(elm, 'locationLids', locations[i].lid);
        });
      }
    }
  };

  /**
   * Edits a comment and sends any changes to the server to be saved.
   */
  var editComment = function(e){
    var target = $(e.target);
    var commentElm = target.parents('.comment');
    var origContent = target.data('content');
    var newContent = target.html();
    if(origContent === newContent || target.parents('.disabled').length > 0){ 
      return; 
    }


    target.addClass('comment-in-edit');
    if(target.data('timeout')){
      clearTimeout(target.data('timeout'));
    }

    // Save the comment changes.
    target.data('timeout', setTimeout(function(){

      $.ajax('/api/comments/'+ commentLidToSidMap[commentElm.data('lid')], {
        method: 'POST',
        data: {
          _method: 'patch',
          comment: {
            content: newContent
          }
        },
        success: function(data){
          if(data.error){
            displayError('There was an error updating your comment: '+ 
              data.error);
            return;
          }
          target.removeClass('comment-in-edit');
          target.parent().find('.comment-saved').show().fadeOut(2000);
          target.data('content', newContent);
        },
        error: function(xhr, status, error){
          displayError('There was an error updating your comment. '+ error);
        }
      })
    }, 2000));
  };

  /**
   * A comparison of two locations; when used with sort, this will cause
   * locations with earlier (lower) starting lines and columns to come first.
   * 
   * @param {simple object} loc1 A location.
   * @param {simple object} loc2 A location.
   * @return -1 if loc1 comes before loc2, 0 if they're the same, and 1 if loc1
   *         comes after loc2.
   */
  var compareLocations = function(loc1, loc2){
    if(loc1.start_location === loc2.start_location){
      return loc1.start_column - loc2.start_column;
    }
    return loc1.start_location - loc2.start_location;
  }

  /**
   * Retrieves the first location in the list of locations that is for the
   * given file.
   *
   * @param {array of simple objects} locations The list of locations.
   * @param {string} fileId Only locations matching this id will be returned.
   * @return The first location that matches the given file, if any.
   */
  var getFirstLocation = function(locations, fileId){
    var sorted = locations.sort(compareLocations);
    var i;
    for(i = 0; i < sorted.length; i++){
      if(sorted[i].file_id === fileId){
        return sorted[i];
      }
    }
  };

  /**
   * Inserts a comment into the given container.
   *
   * @param {jQuery Elm} comment The comment element to add to the container.
   * @param {jQuery Elm} container The element to add the comment to.
   */
  var insertComment = function(commentElm, container){
    var inserted = false;
    container.children().each(function(i, e){
      var child = $(this);
      if(inserted || child === commentElm){ return; }
      if(child.data('start-line') > commentElm.data('start-line') ||
          (child.data('start-line') === commentElm.data('start-line') &&
            child.data('start-column') > commentElm.data('start-column'))){

        commentElm.insertBefore(child);
        inserted = true;
        return;
      }
    });

    // If we've reached this point without inserting, then the comment should 
    // go at the end.
    if(!inserted){
      container.append(commentElm);
    }
  }

  /**
   * Adds a list of locations to the given comment.
   *
   * @param {int} commentLid The local id of the comment.
   * @param {array of simple objects} locations The comment locations to add.
   * @param {boolean} save Whether the comment locations should be saved to the
   *                       server; default = false.
   */
  var addCommentLocationsToComment = function(commentLid, locations, save){
    var commentElm = $('#comment-'+ commentLid),
        startingLocationChanged = false, 
        i,
        origLocations;

    // Add the new locations to the comment.
    origLocations = commentElm.data('locations') || [];
    commentElm.data('locations', origLocations.concat(locations));

    for(i = 0; i < locations.length; i++){
      commentLocLidToCommentLidMap[locations[i].lid] = commentLid;

      var startLine = commentElm.data('start-line');
      var startColumn = commentElm.data('start-column');
      if(startLine === undefined || startLine > locations[i].start_line ||
          (startLine === locations[i].start_line && 
           startColumn > locations[i].start_column)){

        // So we know where the first comment location is.
        commentElm.data('start-line', locations[i].start_line).
                data('start-column', locations[i].start_column);

        startingLocationChanged = true;
      }
    }

    // (Re-)Insert the comment into the comment list if the start-line/
    // start-column changed.
    if(startingLocationChanged){
      insertComment(commentElm, $('#comments'));
    }

    // Highlight all the comments.
    markCommentLocations(commentLid, locations);
    highlightCommentLocations(commentLid);

    // Save the locations to the server if requested.
    if(save){
      saveCommentLocations(commentLid, locations);
    }
  };

  /**
   * Increments the annotation count badge for the current file based on a
   * counter class.
   *
   * @param {string} counterClass The class of the counter to increment. E.g., 
   *                              'comment-count', 'altcode-count', etc.
   * @param {int} amount The amount to increment the comment count by. Defaults
   *                     to 1; can be set to a negative number to decrement.
   * @param {int} fileId The id of the file whose counter should be adjusted.
   *                     Defaults to the current file id.
   */
  var incrementBadgeCount = function(counterClass, amount, fileId){
      amount = (amount === undefined) ? 1 : amount;
      fileId = (fileId === undefined) ? curFileInfo.id : fileId;
      var badgeCounterElm = $('#file-'+ fileId).
        find('.'+counterClass +' .badge');
      badgeCounterElm.html(parseInt(badgeCounterElm.text())+amount);
  };

  /**
   * Creates a comment with the given locations.
   * @param {array of simple objects} locations A list of locations.
   * @param {string} content The comment content. Defaults to ''.
   * @param {boolean} isNew Whether the comment is new, and therefore needs to
   *                        be saved to the server.
   * @param {simple object} serverComment The comment from the server, if 
   *                                      available.
   * @return The comment that was created.
   */
  var createComment = function(locations, content, isNew, serverComment){
    content = content || '';
    var commentLid = commentLidCounter++;

    // Add local ids to each of the locations if they don't already have one.
    var i;
    for(i = 0; i < locations.length; i++){
      if(locations[i].lid === undefined){
        locations[i].lid = locationLidCounter++;
      }
      commentLocLidToCommentLidMap[locations[i].lid] = commentLid;
    }

    // var firstLocation = getFirstLocation(locations, curFileInfo.id);

    var comment = $('#comment-template').clone();
    comment.attr('id', 'comment-'+ commentLid);
    comment.appendTo('#comments');

    // Comments loaded from the server will include a creator_email. New
    // comments should use the current user's email.
    if(serverComment){
      comment.find('.comment-owner').html(serverComment.creator_email);
    } else {
      comment.find('.comment-owner').html($('#current-email').html());
    }

    // Store the comment content so we know when it's changed; give focus to
    // it so the user can edit straight away.
    var body = comment.find('.comment-body');
    body.html(content).data('content', content);

    // Set lid and mark all comment locations.
    comment.data('lid', commentLid);

    // Add comment locations.
    addCommentLocationsToComment(commentLid, locations, false);

    // If new, we need to save the comment to the server.
    if(isNew){
      saveComment(commentLid, content, locations);
      incrementBadgeCount('comment-count');
    }

    // Set the real id if the server comment is available.
    if(serverComment){
      commentLidToSidMap[commentLid] = serverComment.id;
    }

    // So this comment has the focus.
    body.focus();

    return comment;
  };

  /**
   * Saves a comment to the server.
   *
   * @param {int} commentLid The local id of the comment to save.
   * @param {string} content The content of the comment to save.
   * @param {array of simple objects} locations The list of locations to save
   *                                            for this comment.
   */
  var saveComment = function(commentLid, content, locations){
    $.ajax(COMMENT_API, {
      method: 'POST',
      data: {
        comment: {
          content: content
        }
      },
      success: function(data){
        if(data.error){
          displayError('There was an error saving your comment: '+ data.error);
          return;
        }

        commentLidToSidMap[commentLid] = data.id;

        // Save location.
        saveCommentLocations(commentLid, locations);
      },
      error: function(xhr, status, error){
        displayError('There was an error saving your comment. '+ error);
      }
    });
  }

  /**
   * Saves a list of comment locations to the server.
   *
   * @param {int} commentLid The local id of the comment to which the locations
   *                         belong.
   * @param {array of simple objects} locations The locations to save.
   */
  var saveCommentLocations = function(commentLid, locations){
    var i;
    for(i = 0; i < locations.length; i++){
      $.ajax('/api/comments/'+ commentLidToSidMap[commentLid] +'/locations', {
        method: 'POST',
        data: {
          comment_location: locations[i]
        },
        success: (function(index){ return function(data){
          if(data.error){
            displayError('There was an error saving the location of your '+
              'comment: '+ data.error);
            return;
          }
          commentLocLidToSidMap[locations[index].lid] = data.id;
        }})(i),
        error: function(xhr, status, error){
          displayError('There was an error saving the location of your '+
            'comment. '+ error);
        }
      });
    }
  };

  /**
   * Hides all highlighted selections.
   */
  var hideHighlights = function(){
    $('.code .selected').removeClass('selected');
  };

  /**
   * Normalizes a comment location; this is necessary because text selections
   * where the user drags the mouse from the bottom/right to top/left will have
   * the start and end information backwards from selections made from the
   * top/left to bottom/right.
   *
   * @param {simple object} loc The location to normalize. This is modified
   *                            in place.
   * @return The normalized location.
   */
  var normalizeLocation = function(loc){
    var unNormLoc = {
      start_line:   loc.start_line,
      start_column: loc.start_column,
      end_line:     loc.end_line,
      end_column:   loc.end_column
    };

    if(loc.start_line > loc.end_line || 
        (loc.start_line === loc.end_line && loc.start_column > loc.end_column)){
      loc.start_line   = unNormLoc.end_line;
      loc.start_column = unNormLoc.end_column;
      loc.end_line     = unNormLoc.start_line;
      loc.end_column   = unNormLoc.start_column;
    }
    return loc;
  };

  /**
   * Highlights the given comment location. 
   *
   * @param {simple object} loc An object with the fields:
   *    start_line:    The line of code to start on, base 1.
   *    start_column:  The starting column, base 1.
   *    end_line:      The line of code to end on, base 1.
   *    end_column:    The final column to highlight, base 1.
   * @param {string} cssClass The CSS class to add or remove to the selected 
   *                          elements. Defaults to 'selected'.
   * @param {boolean} add Whether the cssClass should be added to or removed
   *                      from the selected elements. Defaults to true.
   */
  var highlightSelection = function(loc, cssClass, add){
    cssClass = cssClass || 'selected';
    add = add === undefined ? true : add;

    // Add column ids to the characters in each line in this location if
    // they haven't already been added.
    var lines = [], i;
    for(i = loc.start_line; i <= loc.end_line; i++){
      var lineElm = $('#file-display .code .line.number'+i)[0];
      if(lineElm) lines.push(lineElm);
    }
    addColumnsToHighlightedCode(lines);

    applyToCodeRange(loc, function(charElm){
      if(add){
        charElm.addClass(cssClass);
      } else {
        charElm.removeClass(cssClass);
      }
    });
  };

  /**
   * Modifies the displayed file content to make highlighting easier.
   *
   * @param {Array of DOM Elmements} lines The SyntaxHighlighter code lines
   *                                       to mark up. Only adds columns if
   *                                       the 'processed' data field isn't set.
   */
  var addColumnsToHighlightedCode = function(lines){
    // $(contentElm).find('.line').each(function(i,lineElm){
    $.each(lines, function(i, lineElm){

      var lineElmJQ = $(lineElm);
      if(lineElmJQ.data('processed')) return;
      lineElmJQ.data('processed', true);

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

  /**
   * Determines the line and column offset for a text selection.
   *
   * @param {HTML Node} node The selected node.
   * @param {int} offset The offset of the selected node.
   * @return {simple object} The line and column of the selection.
   */
  var getSelectionOffsets = function(node, offset){
    var parentJQ = $(node.parentNode);

    // Check if the node has already been highlighted (since that will give
    // us an exact line/col). This returns immediately.
    if(parentJQ.hasClass('highlightable')){

      return {
        line: parseInt(parentJQ.data('line')),
        col:  parseInt(parentJQ.data('col'))
      };
    }

    // Otherwise, we'll have to calculate the offset the hard way.
    var shElm = node.parentNode;
    var lineElm = $(shElm).parents('.line')[0];

    if(!lineElm) return {line: -1, col: -1};

    var lineNumber = parseInt(lineElm.className.split(/\s+/)[1].substr(6));
    var colNumber = 1;
    var children = lineElm.childNodes;
    var i;

    // Calculate the column.
    for(i = 0; i < children.length && children[i] != shElm; i++){
      if(children[i].nodeType == 3){
        colNumber += children[i].nodeValue.length;
      } else {
        colNumber += children[i].innerText.length;
      }
    }
    colNumber += offset;

    return {line: lineNumber, col: colNumber};
  };

  /**
   * Calculates the line and column offsets for the current selection.
   *
   * @return {simple object} The starting column
   */
  var getSelectionLocation = function(){
    var selection = window.getSelection();

    if(!selection || selection.isCollapsed){
      return false;
    }

    var startLocInfo = getSelectionOffsets(selection.anchorNode, 
      selection.anchorOffset);
    var endLocInfo = getSelectionOffsets(selection.focusNode, 
      selection.focusOffset);

    var location = normalizeLocation({
      file_id:          curFileInfo.id,
      start_line:       startLocInfo.line,
      start_column:     startLocInfo.col, 
      end_line:         endLocInfo.line,
      end_column:       endLocInfo.col
    });

    if(locationIsValid(location)){
      return location;
    }

    return false;
  };

  /**
   * Escapes an HTML string.
   * Lifted from Mustache 
   * (https: *github.com/janl/mustache.js/blob/master/mustache.js)
   *
   * @param {string} html The HTML string to escape.
   * @return The escaped HTML string.
   */
  var escapeHtml = function(html) {
    return String(html).replace(/[&<>"'\/]/g, function (s) {
      return ENTITY_MAP[s];
    });
  };

  /**
   * Extracts the extension from a file name.
   *
   * @param {string} filename The name of the file.
   * @return The extension (last .XXX) or undefined if no extension is found.
   */
  var extractExtension = function(filename){
    var parts = filename.split('.');
    if(parts.length > 1){
      return parts[parts.length-1];
    }
    return undefined;
  };

  /**
   * Figures out the highlighter class for the given file.
   *
   * @param {string} filename The name of the file.
   * @return The highlighter class corresponding to the extension; defaults to
   *         the plain text highligher if no extension is found, or no 
   *         corresponding highlighter is found.
   */
  var getHighlighterClass = function(filename){
    var extension = extractExtension(filename);
    var returnClass = 'brush: '+ 
      (KNOWN_FILE_EXTENSIONS[extension] || KNOWN_FILE_EXTENSIONS['txt']);
    if(extension === 'erb' || extension === 'php'){
      returnClass += "; html-script: true";
    }
    return returnClass;
  };

  /**
   * Remove the leading # on a hash.
   *
   * @param [string] hash The hash.
   * @return The hash with leading # removed.
   */
  var stripHash = function(hash){
    return hash.replace( /^#/, "" );
  };

  /**
   * Fetch the content of the select file.
   *
   * @param [int] fileId The id of the file to load.
   */
  var displayFile = function(fileId){
    $('#comments').html('');
    $('.loaded').removeClass('loaded');
    $('[data-file-id='+fileId+']').addClass('loaded');

    $('#file-display').html('Loading file '+ fileId +'...');

    // Convert the id to an integer (just in case someones putting something
    // funny into the hash).
    fileId = parseInt(fileId)

    // Fetch the file.
    $.ajax(FILES_API+fileId, {
      success: function(data, status){
        if(data.error){
          $('.page-header').html('ERROR');
          displayError('There was an error retrieving this file: '+ data.error);
          // $('#file-display').html(data.error);
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
          // addColumnsToHighlightedCode($('#file-display .code')[0])

          loadFileComments(data.file.comments);
          loadFileAltcode(data.file.altcode);
        }
      },
      error: function(req, status, error){
        displayError('There was an error retrieving this file. '+ error);
      }
    });
  };

  /**
   * Toggles the sidebar and file contents area.
   */
  var toggleFileView = function(){
    $('.sidebar').toggleClass('sidebar-collapse');
    $('.main').toggleClass('main-collapse');
  }

  /**
   * Loads project comments from the server and includes them in the given
   * element.
   *
   * @param {jQuery element} elm The element to add the comments to.
   */
  var loadProjectComments = function(elm){
    elm.html('');
    $.ajax(COMMENT_API, {
      method: 'GET',
      success: function(data){
        if(data.error){
          displayError('There was an error retrieving the project comments: '+
            data.error);
          return;
        }

        var i;
        for(i = 0; i < data.comments.length; i++){
          var comment = $('#comment-template').clone().attr('id', '').
            data('id', data.comments[i].id).addClass('disabled');
          comment.find('.comment-owner').html(data.comments[i].creator_email);
          comment.find('.comment-body').html(data.comments[i].content).
            attr('contenteditable', false);
          comment.find('.comment-delete').remove();
          comment.data('server-comment', data.comments[i]);
          elm.append(comment);
        }

        elm.css({maxHeight: ($(window).height()-300)+'px'});
        elm.parents('.modal').modal('handleUpdate');

      },
      error: function(xhr, status, error){
        displayError('There was an error retrieving the project comments. '+
          error);
      }
    })
  };

  /**
   * Loads all the comments in.
   *
   * @param {array of simple objects} comments The comments to add.
   */
  var loadFileComments = function(comments){
    var i, j;
    commentLocLidToCommentLidMap = {};
    commentLidToSidMap = {};
    commentLocLidToCommentLidMap = {}
    commentLidCounter = 0;
    locationLidCounter = 0;

    for(i = 0; i < comments.length; i++){
      //comments[i].lid = commentLidCounter++;
      for(j = 0; j < comments[i].locations.length; j++){
        comments[i].locations[j].lid = locationLidCounter++;
        commentLocLidToSidMap[comments[i].locations[j].lid] = 
          comments[i].locations[j].id;

        // Only highlight if this comment is for the current file.
        if(comments[i].locations[j].file_id === curFileInfo.id){
          normalizeLocation(comments[i].locations[j]);
          highlightSelection(comments[i].locations[j]);
        }
      }
      var commentElm = createComment(
        comments[i].locations, comments[i].content, false, comments[i]);
      commentElm.find('.comment-body').blur();
    }
  };

  /**
   * Loads all of the given altcode. Also takes care of assigning lids to each
   * one and entering them in the global altcode lookups.
   *
   * @param {array of simple objects} altcode The altcode to add.
   */
  var loadFileAltcode = function(altcode){
    var i;
    altcodeLidToSidMap = {};
    altcodeLookup = {};
    altcodeLidCounter = 0;

    for (i = 0; i < altcode.length; i++) {
      // Add lid and take care of some book keeping.
      altcode[i].lid = altcodeLidCounter++;
      altcodeLidToSidMap[altcode[i].lid] = altcode[i].id;
      altcodeLookup[altcode[i].lid] = altcode[i];

      // Add the altcode to the UI.
      addAltCode(altcode[i]);
    };
  };

  /**
   * Hides all remove location buttons.
   */
  var hideRemoveLocationButtons = function(){
    $('.location-removal-button.shown').removeClass('shown');
  };

  /**
   * Checks if the given location is valid, that is, the starting and ending
   * points are numbers greater than 0.
   *
   * @param {simple object} location The location to verify.
   * @return True if the location is valid, false otherwise.
   */
  var locationIsValid = function(location){
    return location.start_line > 0 && location.start_column > 0 &&
        location.end_line > 0 && location.end_column > 0;
  };

  /**
   * Returns the size of the given list of files.
   *
   * @param {array of Files} files The list of files.
   * @return {int} The total size of the list of files.
   */
  var getFileSizes = function(files){
    var i, totalSize = 0;
    for(i = 0; i < files.length; i++){
      totalSize += files[i].size;
    }
    return totalSize;
  }

  /**
   * Creates the highlighted version of the given code.
   *
   * @param {string} code The code to highlight.
   * @param {string} brush (Optional) The SyntaxHighlighter class to attached.
   *                       Defaults to the brush class for the current loaded
   *                       file based on its extension.
   * @return The SyntaxHighter highlighted lines of the code with line number
   *         an index classes removed.
   */
  var syntaxHighlightCodeString = function(code, brushClass){
    brushClass = brushClass || getHighlighterClass(curFileInfo.name);

    var codePre = $('<pre>');
    $('#code-to-highlight').html('').append(codePre);
    codePre.attr('class', brushClass).html(escapeHtml(code));

    SyntaxHighlighter.highlight(undefined, codePre[0]);

    var highlightedCode = $('#code-to-highlight .code .line').clone().
      attr('id', '');
    highlightedCode.attr('class', 'line');

    return highlightedCode;
  };

  /**
   * Applies the given function to each character in the given range of
   * characters in the code.
   *
   * @param {simple object} loc A map with four fields: start_line,
   *                            end_line, start_column, end_column.
   * @param {function} fnc The function to invoke for each character. Should
   *                       take one arg: a jQuery instance of the character.
   */
  var applyToCodeRange = function(loc, fnc){
    var i, j;
    for(i = loc.start_line; i <= loc.end_line; i++){
      var start = (i === loc.start_line) ? loc.start_column : 1;
      var end = (i === loc.end_line) ? loc.end_column : 
        $('.content-line'+ i).size();

      for(j = start; j <= end; j++){
        fnc($('#'+ i +'_'+ j));
      }
    }
  };

  /**
   * Adds in a block of alternative code at the given line.
   *
   * @param {simple object} altcode An altcode object that contains the fields:
   *                                lid, start_line, start_column, end_line, 
   *                                end_column, content, creator_email.
   */
  var addAltCode = function(altcode){
    var i, contentLineElms, gutterEndElm, codeEndElm, endLine;

    // This will help us get around situations where altcode ends at the
    // beginning of a line.
    endLine = altcode.end_line;
    if(altcode.end_line != altcode.start_line && altcode.end_column === 0) {
      endLine--;
    }

    // Highlight the content.
    contentLineElms = syntaxHighlightCodeString(altcode.content);

    // The line under which the altcode will appear.
    gutterEndElm = $('#file-display .gutter .line.number'+ endLine);
    codeEndElm = $('#file-display .code .line.number'+ endLine);


    // The gutter lines (each line has a "alternate" symbol).
    for(i = 0; i < contentLineElms.length; i++){
      var newGutterElm = $('<div>').addClass(
        'altcode altcode-gutter line altcode-'+ altcode.lid);
      newGutterElm.html('&nbsp;<span class="glyph-wrapper">'+
        '<span class="glyphicon glyphicon-random"></span></span>');
      newGutterElm.insertAfter(gutterEndElm);

      // Add a remove and edit button if this is the first line (which is the
      // last to be added).
      if(i === contentLineElms.length-1){
        var closeElm = $('<span>').attr('id', 'altcode-remove-'+ altcode.lid).
          addClass('altcode-removal-button').
          html('<span class="glyphicon glyphicon-remove-circle"></span>').
          data('lid', altcode.lid);
        var editElm = $('<span>').attr('id', 'altcode-edit-'+ altcode.lid).
          addClass('altcode-edit-button').
          html('<span class="glyphicon glyphicon-pencil"></span>').
          data('lid', altcode.lid);

        newGutterElm.find('.glyph-wrapper span').replaceWith(closeElm);
        editElm.insertAfter(closeElm);
      }

    }

    // Add the content.
    $(contentLineElms).addClass(
      'altcode altcode-content altcode-'+ altcode.lid).
      insertAfter(codeEndElm);

    // Add strikeouts to the replaced code.
    highlightSelection(altcode, 'altcode altcode-strikeout altcode-'+ 
        altcode.lid);
  };

   /**
    * Removes the altcode specified, or all altcode if no altcode is specified.
    *
    * @param {array of ints} altcodeLids (OPTIONAL) A list of altcode local ids.
    *                                    If not present, all altcode is removed.
    * @param {boolean} deleteFromServer (OPTIONAL) If true, each altcode in
    *                                   altcodeLids will be removed. This only 
    *                                   works when altcodeLids is present.
    */
  var removeAltCode = function(altcodeLids, deleteFromServer){
    // If no altcode lids are given, this is easy -- remove all altcode.
    if(altcodeLids === undefined || altcodeLids.length === 0){

      // Remove the gutter and altcode content.
      $('.altcode-content,.altcode-gutter').remove();

      // Remove altcode classes from all other characters.
      $('.code .altcode').each(function(i,e){
        var i, classes = this.classList;

        // Remove any classes with an altcode prefix.
        for(i = 0; i < classes.length; i++){
          if(classes[i].match(/^altcode/)){
            $(this).removeClass(classes[i]);
            i--;
          }
        }
      });
    // Remove only altcode associated with the provided ids.
    } else {
      var i, j, lid;
      for(i = 0; i < altcodeLids.length; i++){
        lid = altcodeLids[i];

        // Remove the gutter and altcode content.
        $('.altcode-content.altcode-'+ lid +',.altcode-gutter.altcode-'+ lid).
          remove();

        // We need to be careful about removing the strikeouts, since more than
        // one altcode may be attached to each character.
        $('.altcode-'+lid).each(function(){
          var classes, isOnlyAltcode = true;

          $(this).removeClass('altcode-'+ lid);


          // Check if any other altcodes are attached to this element.
          classes = this.classList;
          for(j = 0; j < classes.length; j++){
            if(classes[j].match(/^altcode-\d/)){
              isOnlyAltcode = false;
              break;
            }
          }

          // Remove the altcode/altcode-strikeout classes if this is the only
          // one altcode associated with this element.
          if(isOnlyAltcode){
            $(this).removeClass('altcode altcode-strikeout');
          }
        });

        if(deleteFromServer){
          $.ajax('/api/altcode/'+ altcodeLidToSidMap[lid], {
            method: 'POST',
            data: {
              _method: 'delete'
            },
            success: function(data){
              if(data.error){
                displayError('There was an error removing the altcode. '+ 
                  data.error);
                return;
              }

              incrementBadgeCount('altcode-count', -1);
            },
            error: function(xhr, status, error){
              displayError('There was an error removing the altcode. '+ error);
            }
          });
        }
      }
    }
  };

  /**
   * Creates a new altcode.
   *
   * @param {simple object} altcodeInfo The altcode information to be sent to
   *                                    the server: lid, content, start_line, 
   *                                    start_column, end_line, end_column. The 
   *                                    file_id will be added before upload; the
   *                                    id field will be added after hearing
   *                                    back. 
   */
  var createAltCode = function(altcodeInfo){
    $.ajax(PROJECT_API +'/altcode', {
      method: 'POST',
      data: {
        altcode: {
          content: altcodeInfo.content,
          start_line: altcodeInfo.start_line,
          start_column: altcodeInfo.start_column,
          end_line: altcodeInfo.end_line,
          end_column: altcodeInfo.end_column,
          file_id: curFileInfo.id
        }
      },
      success: function(data){
        if(data.error){
          displayError('There was an error saving your altcode: '+ data.error);
          return;
        }

        altcodeInfo.id = data.id;
        altcodeInfo.creator_email = $('#current-email').text();
        altcodeInfo.file_id = curFileInfo.id;
        addAltCode(altcodeInfo, true);
        altcodeLidToSidMap[altcodeInfo.lid] = data.id;
        altcodeLookup[altcodeInfo.lid] = altcodeInfo;
        incrementBadgeCount('altcode-count');
      },
      error: function(xhr, status, error){
        displayError('There was an error saving your altcode. '+ error);
      }
    });
  };

  /**
   * Updates altcode.
   *
   * @param {simple object} altcodeInfo The altcode information to be sent to
   *                                    the server: id, content, start_line, 
   *                                    start_column, end_line, end_column, 
   *                                    file_id.
   */
  var updateAltCode = function(altcodeInfo){
    $.ajax('/api/altcode/'+ altcodeInfo.id, {
      method: 'POST',
      data: {
        _method: 'patch',
        altcode: {
          content:      altcodeInfo.content,
          start_line:   altcodeInfo.start_line,
          start_column: altcodeInfo.start_column,
          end_line:     altcodeInfo.end_line,
          end_column:   altcodeInfo.end_column,
          file_id:      altcodeInfo.file_id
        }
      },
      success: function(data){
        if(data.error){
          displayError('There was an error updating your altcode: '+data.error);
          return;
        }

        removeAltCode([altcodeInfo.lid]);
        addAltCode(altcodeInfo);
      },
      error: function(xhr, status, error){
        displayError('There was an error updating your altcode. '+ error);
      }
    });
  }

  /**
   * Adds an altcode editing dialog and returns the instance.
   *
   * @param {string} content (Optional) The initial content of the editor.
   */
  var createAltCodeEditor = function(content){
    content = content || '';
    var altcodeElm = $('#altcode-template').clone().attr('id', '');
    altcodeElm.appendTo('#file-display');
    altcodeElm.css('top', $('#file-display').scrollTop()+50+'px');
    altcodeElm.draggable({
      handle: ".panel-heading"
    });
    altcodeElm.find('.altcode-editor').focus().val(content);
    return altcodeElm;
  }

  // LISTENERS

  // For the "Projects listing" view.
  // Listen for a row to be clicked on. A td element must specifically be 
  // clicked (not a child element) to trigger the page load. For example, see
  // the project listing -- the td with the trash can does not cause the row's
  // href to be loaded.
  $(document).on('click', '.clickable-row', function(event) {
    if(event.target.tagName === 'TD' && !$(event.target).hasClass('trash')){
      window.document.location = $(this).data('href');
    }
  });


  // Collapses/expands directories in the file listings.
  $(document).on('click', '.directory-name', function(event){
    var elm = $(this), parent = elm.parent();

    if(event.target.tagName === 'INPUT'){
      // Check all elements below.
      if(event.target.checked){
        elm.closest('.directory-entry').find('input.file-select').
          prop('checked', true);
      } else {
        elm.closest('.directory-entry').find('input.file-select').
          prop('checked', false);
      }
      return;
    }

    if(parent.data('expand-state') === 'expanded'){
      parent.children('.directory').hide();
      elm.children('.collapsed').show();
      elm.children('.expanded').hide();
      parent.data('expand-state', 'collapsed');
    } else {
      parent.children('.directory').show();
      elm.children('.collapsed').hide();
      elm.children('.expanded').show();
      parent.data('expand-state', 'expanded');
    }
  });

  // Detects when a file's content needs loading.
  if($('#file-display').size() == 1){
    var processHash = function(){
      if(location.hash && stripHash(location.hash) !== ''){
        displayFile(stripHash(location.hash));
      } else {
        $('#file-display').html('');
        $('#comments').html('');
      }
    }

    // Check if the initial url contain a hash.
    processHash();

    // Wait for any changes to the location hash.
    $(window).on('hashchange', function(){
      processHash();
      if($('.main').hasClass('main-collapse')){
        toggleFileView();
      }
    });
  }

  // Handles toggling the file listing sidebar.
  $(document).on('click', '.sidebar-toggle', function(){
    toggleFileView();
  })

  // $(document).on('mouseup', '#file-and-annotations', function(){
  //   hideCommentLocationHighlights();
  //   $('#selection-menu .btn').addClass('disabled');
  //   hideRemoveLocationButtons();
  // });

  // Listens for file content to be selected and then highlights it.
  // $(document).on('mouseup', '.code .container', function(){
  $(document).on('mouseup', '#file-display', function(){
    var location = getSelectionLocation();
    if(locationIsValid(location)){
      $('#selection-menu .btn').removeClass('disabled');
    } else if(!$(this).hasClass('comment-location-highlight')) {
      hideCommentLocationHighlights();
      $('#selection-menu .btn').addClass('disabled');
      hideRemoveLocationButtons();
    }
  });

  // Handles clicks on file operation buttons.
  $(document).on('click', '#file-ops .btn', function(e){
    if($(this).hasClass('disabled')){ return; }

    if(e.target.id === 'delete-project'){
        // Remove the project.
        deleteProject(PROJECT_ID, function(data){
          window.document.location = '/projects';
        });
    }

  });

  // Handles clicks on comment editing buttons.
  $(document).on('click', '#selection-menu .btn', function(e){
    if($(this).hasClass('disabled')){ return; }

    var location = getSelectionLocation();
    if(!locationIsValid(location)){ return; }

    // Add to comment.
    if(e.target.id === 'add-comment'){
      location.lid = locationLidCounter++,
      highlightSelection(location);
      createComment([location], '', true);

    // Add to existing comment.
    } else if(e.target.id === 'add-to-comment'){
      location.lid = locationLidCounter++,
      // highlightSelection(location);
      loadProjectComments($('#all-project-comments'))
      locationToAddToComment = location;

    // Add alternative code.
    } else if(e.target.id === 'add-alt-code'){
      highlightSelection(location, 'select-altcode');

      createAltCodeEditor().data('altcodeInfo', location);
    }

  });

  // Handles comment deletions.
  $(document).on('click', '.comment-delete', function(e){
    var comment = $(this).parents('.comment');
    hideCommentLocationHighlights();
    deleteComment(comment.data('lid'));
    e.preventDefault();
  });

  // Listens for changes to comment content.
  $(document).on('change', '.comment-body', editComment);
  $(document).on('keyup', '.comment-body', editComment);
  $(document).on('mouseup', '.comment-body', editComment);

  // Highlights comment locations when hovering over a comment.
  $(document).on('mouseover', '.comment', function(){
    if($(this).parents('.disabled').length > 0){ return; }

    hideCommentLocationHighlights();
    highlightCommentLocations($(this).data('lid'));
  });

  // Handles focusing on a comment when a comment location is clicked.
  $(document).on('click', '.selected', function(){
    var commentLocationElm = $(this);
    var commentLids = commentLocationElm.data('commentLids');
    var locationLids = commentLocationElm.data('locationLids');

    // Show the location-removal button.
    if(locationLids && locationLids.length > 0){
      var i = 0, commentLid;
      if(
          locationIndexLastSelected < locationLids.length &&
          locationLids[locationIndexLastSelected] == locationLidLastSelected){
        i = (locationIndexLastSelected + 1) % locationLids.length;
      }

      commentLid = commentLocLidToCommentLidMap[locationLids[i]];
      highlightCommentLocations(commentLid);
      var comment = $('#comment-'+ commentLid);
      $('#comments').scrollTop(comment[0].offsetTop);
      comment.find('.comment-body ').focus();

      hideRemoveLocationButtons();
      $('#remove-'+ locationLids[i]).addClass('shown');

      locationIndexLastSelected = i;
      locationLidLastSelected = locationLids[i];
    }
  });

  // Changes the style of comments when they have focus.
  $(document).on('focus', '.comment-body', function(){
    if($(this).parents('.disabled').length > 0){ return; }
    $(this).parents('.comment').addClass('panel-primary');
  });

  // Changes the style of comments when they loose focus.
  $(document).on('blur', '.comment-body', function(){
    if($(this).parents('.disabled').length > 0){ return; }
    $(this).parents('.comment').removeClass('panel-primary');
  });

  // Listen for comment location removal buttons to be pressed.
  $(document).on('click', '.location-removal-button', function(){
    var lid = $(this).data('lid');
    deleteCommentLocation(commentLocLidToCommentLidMap[lid], lid, false);
  });

  $(document).on('mouseover', '#project-comments-modal .comment', function(){
    $(this).addClass('panel-primary');
  });

  $(document).on('mouseout', '#project-comments-modal .comment', function(){
    $(this).removeClass('panel-primary');
  });

  $(document).on('click', '#project-comments-modal .comment', function(){
    var tmpComment = $(this),
        id = tmpComment.data('id'),
        lid, tmpLid,
        location = locationToAddToComment;

    if(!locationIsValid(location)){ return; }

    highlightSelection(location);

    // Check if we're adding to a comment that already exists.
    for(tmpLid in commentLidToSidMap){
      if(commentLidToSidMap[tmpLid] === id){
        lid = tmpLid;
        break;
      }
    }

    if(lid >= 0){
      addCommentLocationsToComment(lid, [location], true);

    } else {
      var newComment = createComment(
        tmpComment.data('server-comment').locations.concat([location]), 
        tmpComment.find('.comment-body').html(), false, 
        tmpComment.data('server-comment'));
      lid = newComment.data('lid');
      saveCommentLocations(lid, [location]);
      incrementBadgeCount('comment-count');
    }

    $('#project-comments-modal').modal('hide');
    $('#comment-'+ lid).find('.comment-body').focus();
    locationToAddToComment = undefined;
  });

  // Listen for project files to be selected.
  $(document).on('change', '.file-upload-selection', function(){
    var uploadSize = getFileSizes(this.files);
    if(this.files.length > 0 && uploadSize <= MAX_PROJECT_SIZE_BYTES){
      // $('.file-upload-submit').attr('disabled', false);
    } else {
      if(uploadSize > MAX_PROJECT_SIZE_BYTES){
        alert('Upload file size too large! Uploads must be less than '+
          MAX_PROJECT_SIZE_MB +'MB and not exceed the project limit (also '+
          MAX_PROJECT_SIZE_MB + 'MB).');
      }
      // $('.file-upload-submit').attr('disabled', true);
    }
  });

  // Listen for files to be submitted.
  $(document).on('click', '#add-files-container .file-upload-submit', function(e){
    // Check that the user has entered at least one file.
    if($('#add-files-container .file-upload-selection')[0].files.length === 0){
      alert("Please select at least one file to upload.");
      e.preventDefault();
      return false;
    } else {
      $('#directory_id').val(selectedDirectory);
      $('#add-files-container form').submit();
    }
  });

  // Listen for batch project submission.
  $(document).on('click', '#batch-project-upload .project-upload-submit', function(e){
    var files = $('#batch-project-upload .file-upload-selection')[0].files;

    // Make sure they've entered exactly one zip file.
    if(files.length !== 1 || files[0].name.match(/\.zip$/) === null){
      alert("Please select one zip file to upload.");
      e.preventDefault();
      return false;
    }
    $('#batch-project-upload form').submit();  
  });

  // Listen for single project submission.
  $(document).on('click', '#single-project-upload .project-upload-submit', function(e){
    var files = $('#single-project-upload .file-upload-selection')[0].files;

    // Make sure they've entered exactly one or more files.
    if(files.length === 0){
      alert("Please select one or more files to upload.");

    // Make sure they've entered a project name.
    } else if($('#single-project-upload .project-name-input').val().length 
        === 0) {
      alert("Please enter a name for the project.");

    // Otherwise, we're good to go.
    } else {
      $('#single-project-upload form').submit();
    }

    e.preventDefault();
    return false;
  });


  // Listen for clicks on the 'add project' button.
  // $(document).on('click', '#add-project', function(){
  $(document).on('submit', '#add-project-form', function(e){
    var elm = $(this), newProjectInput = $('#new-project-name');

    // Verify the user entered a project name.
    if(newProjectInput.val().length == 0){ return; }

    var projectName = newProjectInput.val();

    // Create project and add an entry once we've heard back from
    // the server.
    $.ajax('/api/projects', {
      method: 'POST',
      data: {
        project: {name: projectName}
      },
      success: function(data){

        if(data.error){
          displayError('There was an error creating the new project: '+ 
            data.error);
          return;
        }

        // Add project to the list.
        var i, project;
        for(i = 0; i < data.projects.length; i++){
          project = data.projects[i];
          var newEntry = $('#entry-template').clone();
          newEntry.attr('id', project.id);
          newEntry.attr('data-href', 
            window.location.origin +'/projects/'+ project.id);
          newEntry.find('.name').html(projectName);
          newEntry.find('.date').html(project.created_on);
          newEntry.find('.email').html(project.creator_email);

          newEntry.insertAfter(elm.parents('tr'));
        }
      },
      error: function(xhr, status, error){
        displayError('There was an error creating the new project. '+ error);
      }
    });
    
    e.preventDefault();
  });

  // After sorting, be sure that the new project form row is at the top.
  if($('.authored-projects').length > 0){
    $('.authored-projects')[0].addEventListener('Sortable.sorted', function(){
      $('#add-project-row').prependTo($(this).find('tbody'));
    });
  }

  // Listen for projects to be deleted.
  $(document).on('click', '.project-trash', function(e){
    var entryElm = $(this).parents('.project');
    var projectId = entryElm.attr('id');

    // Remove the project.
    deleteProject(projectId, function(data){
      // Remove the project from the list.
      entryElm.remove();
    });

    e.preventDefault();
  });

  // Listen for new permissions to be added.
  $(document).on('submit', '#add-permission-form', function(e){
    var email = $('#new-permission-email').val();
    if(email === ''){ return; }

    $.ajax('/api/projects/'+ PROJECT_ID +'/permissions', {
      method: 'POST',
      data: {
        permissions: {
          user_email: email,
          can_view: true,
          can_author: false,
          can_annotate: false
        }
      },
      success: function(data){
        if(data.error){
          displayError('There was an error adding permissions for '+ email +
            ': '+ data.error);
          return;
        }

        $('#new-permission-email').val('');

        var newPermission = $('#new-permission-template').clone().attr('id','');
        newPermission.data('permission-id', data.permissions.id);
        newPermission.find('.permission-email').
          html(data.permissions.user_email);
        newPermission.find('.permission-options').val('view');
        newPermission.prependTo($('#permissions-table'));
      },
      error: function(xhr, status, error){
        displayError('There was an error adding permissions for '+ email +'. '+
          error);
      }
    });

    e.preventDefault();
  });

  // Listen for existing permissions to be edited.
  $(document).on('change', '.permission-options', function(e){
    var accessLevel = $(this).val(),
        can_author = can_view = can_annotate = false,
        row = $(this).parents('tr'),
        permissionId = row.data('permission-id'),
        email = row.find('.permission-email').html();

    if(accessLevel === 'author'){
      can_author = can_view = can_annotate = true;
    } else if(accessLevel === 'annotate'){
      can_annotate = can_view = true;
    } else {
      can_view = true;
    }

    $.ajax('/api/permissions/'+ permissionId, {
      method: 'POST',
      data: {
        _method: 'patch',
        permissions: {
          can_view: can_view,
          can_author: can_author,
          can_annotate: can_annotate
        }
      },
      success: function(data){
        if(data.error){
          displayError('There was an error updating permissions for '+ email +
            ': '+ data.error);
          return;
        }
      },
      error: function(xhr, status, error){
        displayError('There was an error updating permissions for '+ email+'. '+
          error);
      }
    });

  });

  // Listen for existing permissions to be deleted.
  $(document).on('click', '.permission-trash', function(e){
    var row = $(this).parents('tr'),
        permissionId = row.data('permission-id'),
        email = row.find('.permission-email').html();

    $.ajax('/api/permissions/'+ permissionId, {
      method: 'POST',
      data: {
        _method: 'delete'
      },
      success: function(data){
        if(data.error){
          displayError('There was an error removing permissions for '+ email +
            ': '+ data.error);
          return;
        }

        // Remove row.
        row.remove();
      },
      error: function(xhr, status, error){
        displayError('There was an error removing permissions for '+email +'. '+
          error);
      }
    });
  });

  // Listen for clicks on alt code.
  $(document).on('click', '.altcode-gutter,.altcode-content', function(){
    var elm = $(this), classes = this.classList, i, lidClass;

    // Remove old highlights.
    $('.altcode-selected').removeClass('altcode-selected');

    // Extract lid from classes.
    for(i = 0; i < classes.length; i++){
      if(classes[i].match(/^altcode-\d/)){
        lidClass = classes[i];
        break;
      }
    }

    // Add new highlights.
    if(lidClass){
      $('.'+ lidClass).addClass('altcode-selected');
    }

  });

  // Listen for the altcode removal button to be clicked and remove the
  // associated altcode.
  $(document).on('click', '.altcode-removal-button', function(){
    var lid = $(this).data('lid');
    removeAltCode([lid], true);
  });

  // Listen for clicks on the altcode edit button.
  $(document).on('click', '.altcode-edit-button', function(){
    var altcodeInfo = altcodeLookup[$(this).data('lid')];
    createAltCodeEditor(altcodeInfo.content).data('altcodeInfo', altcodeInfo);
  });  

  // Listen for clicks on the save/cancel buttons in the altcode editor.
  $(document).on('click', '.altcode-container .btn', function(){
    var btnElm = $(this);
    var altcodeElm = btnElm.parents('.altcode-container');

    // Remove any selections made for the altcode editor.
    $('.select-altcode').removeClass('select-altcode');

    // Destroy the editor on cancel.
    if(btnElm.hasClass('cancel')){
     altcodeElm.remove();

    // Create or edit an altcode instance.
    } else if(btnElm.hasClass('save')){
      var altcodeInfo = altcodeElm.data('altcodeInfo');

      altcodeInfo.content = altcodeElm.find('.altcode-editor').val();

      // Check if there is a lid; if not, assign one.
      if(altcodeInfo.lid === undefined){
        altcodeInfo.lid = altcodeLidCounter++;
        createAltCode(altcodeInfo);
        altcodeElm.remove();


      // Otherwise, update the existing one.
      } else {
        updateAltCode(altcodeInfo);
        altcodeElm.remove();
      }
    }
  });

  // Listen for the 'Remove files' button to be pressed.
  $(document).on('click', '.toggle-file-removal', function(){
    $('.remove-file-indicator').toggle();
  });

  // List for file removals.
  $(document).on('click', '.remove-file', function(){
    var entryElm = $(this).closest('.entry');
    var fileId = entryElm.data('file-id');

    $.ajax('/api/files/'+ fileId, {
      method: 'POST',
      data: {
        _method: 'delete'
      },
      success: function(data){
        if(data.error){
          displayError('There was an error deleting the file/directory: '+ 
            data.error);
          return;
        }

        entryElm.remove();

        if(curFileInfo && curFileInfo.id === fileId){
          window.location.hash = '';
        }
      },
      error: function(xhr, status, error){
        displayError('There was an error deleting the file/directory. '+ error);
      }
    });
  });

  // Listen for "add file/directory".
  $(document).on('click', '.add-file-or-directory', function(e){
    selectedDirectory = $(this).closest('.directory-entry').data('file-id');
    e.preventDefault();
    return false;
  });


  // Listen for "add directory" form to be submitted.
  $(document).on('submit', '#add-directory-form', function(e){
    e.preventDefault();

    var textBox = $(this).find('#new-directory-name');
    var parentDirectoryId = selectedDirectory;
    var directoryName = textBox.val();


    if(directoryName === '') return;

    $.ajax(PROJECT_API +'/files', {
      method: 'POST',
      data: {
        // directory_id is the id of the parent directory.
        directory: {name: directoryName, directory_id: parentDirectoryId}
      },
      success: function(data){
        if(data.error){
          displayError('There was an error creating the directory: '+ 
            data.error);
          return;
        }

        var newDirElm = $('#directory-template').clone().attr('id', 
          'directory-'+ data.id);
        $('#directory-'+ parentDirectoryId).children('.directory').
          prepend(newDirElm);
        newDirElm.data('file-id', data.id);
        newDirElm.find('.directory-name-placeholder').html(directoryName);

        textBox.val('');
      },
      error: function(xhr, status, error){
        displayError('There was an error creating the directory. '+ error);
      }
    });

    $('#upload-files').modal('hide');

  });


  // Listen for text boxes to be selected, then highlight all of the contained
  // text.
  $(document).on('focus', 'input', function(e){
    this.select();
  });

  // One settings page, listen for edits.
  $(document).on('click', '.settings .edit', function(e){
    var infoBlockElm = $(this).parents('.info-block');
    infoBlockElm.find('.current-info').hide();
    infoBlockElm.find('form').show();

    e.preventDefault();
    return false;
  });

  // Wait for the 'Download' button to be pressed.
  $(document).on('click', '.toggle-file-download', function(e){
    var targetElm = $(this);
    $('.file-select').toggle();
  });

  // Listen for the "Download files" button to be clicked.
  $(document).on('click', '.download-files', function(){

    // Gather the ids of all the files/directories to download.
    var ids = [];
    $('input.file-select:checked').each(function(i,elm){
      elm = $(elm);
      ids.push(elm.closest('.entry').data('file-id'));
    });

    // Add them to the form.
    $('#file_ids').val(ids.join(','));

    // Submit the form.
    $('#file-download-form').submit();
  });

  // Listen for batch uploading.
  $(document).on('change', '#batch-checkbox', function(){
    $("#batch-project-upload").toggle();
    $("#single-project-upload").toggle();    
  });



  // INITIALIZATIONS.

  $('.hidden').removeClass('hidden').hide();

  if(window.location.pathname.match(/^\/projects\/\d+$/)){
    // loadProjectComments();
  }

  if($('#project_file_files').val()){
    $('#file-upload-submit').prop('disabled', false);
  }

  // Make tables labeled as sortable, sortable.
  Sortable.init();
  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.defaults['quick-code'] = false;

  this.getSelectionLocation = getSelectionLocation;
  this.highlightSelection = highlightSelection;
  this.displayError = displayError;
  this.addAltCode = addAltCode;
  this.removeAltCode = removeAltCode;
  this.syntaxHighlightCodeString = syntaxHighlightCodeString;
  return this;
};

var codeAnnotator;

jQuery(document).ready(function($){
  codeAnnotator = CodeAnnotator($);
})

