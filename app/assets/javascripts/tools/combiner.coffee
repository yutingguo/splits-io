$ ->
  # Hijack the upload dropzone for our own purposes
  $('#dropzone').removeAttr('id').attr('id', 'ingest-dropzone')

  TIMELINE_COLORS = ['blue', 'purple', 'green', 'red', 'orange', 'yellow']
  nextColor = -1

  window.livesplitTimeInSeconds = (time) ->
    a = time.split(':')
    (+a[0]) * 60 * 60 + (+a[1]) * 60 + (+a[2])

  window.parseXML = (xml) ->
    xml = $($.parseXML(xml.currentTarget.result))
    segments = xml.find 'Segment'
    window.xml = xml

    $('article').remove()

    runTime = 0

    segments.each (i, segment) ->
      console.log segment
      s = $('#split-template').clone()
      s.removeAttr 'id', 'split-template'
      s.addClass window.nextTimelineColor()
      s.find('.title').html($(segment).find('Name')[0])

      splitTime = $($(segment).find('SplitTime').find('RealTime')[0]).html()
      runTime = splitTime # the last split's splitTime will be our runTime

      s.find('.time').html(window.livesplitTimeInSeconds(splitTime)).addClass 'needs-formatting'

      s.width(1 / segments.length * 100 + '%')

      $("#old-timeline").append(s)

    window.formatTimes()

  window.nextTimelineColor = ->
    nextColor = (nextColor + 1) % TIMELINE_COLORS.length
    TIMELINE_COLORS[nextColor]

  window.ingest = (file, options) ->
    if !file?
      $("#droplabel").html "that looks like an empty file :("
      window.isUploading = false
      return
    options = options or bulk: false
    fr = new FileReader()
    fr.onload = window.parseXML
    fr.readAsText(file)

  $("#ingest-dropzone").on "dragenter", (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    $("#dropzone-overlay").fadeTo 125, .9

  $("#ingest-dropzone").on "dragleave", (evt) ->
    $("#dropzone-overlay").fadeOut 125  if event.pageX < 10 or event.pageY < 10 or $(window).width() - event.pageX < 10 or $(window).height - event.pageY < 10

  $("#ingest-dropzone").on "dragover", (evt) ->
    evt.preventDefault()
    evt.stopPropagation()

  $("#ingest-dropzone").on "drop", (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    files = evt.originalEvent.dataTransfer.files
    $("#dropzone-overlay").fadeOut 125
    window.ingest files[0]

  $("#dropzone").click (evt) ->
    $("#dropzone-overlay").fadeOut 125  unless window.isUploading

  $(document).keyup (evt) ->
    $("#dropzone-overlay").fadeOut 125  if not window.isUploading and evt.keyCode is 27
