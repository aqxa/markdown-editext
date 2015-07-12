
clipboard = require 'clipboard'
fs = require 'fs'
path = require 'path'

module.exports =

  activate: ->
    @imageDirName = 'image'
    @imageExtension = '.png'
    @baseDir = atom.workspace.getActivePaneItem().buffer.file.getParent().path
    @imageDir = path.join @baseDir, @imageDirName
    if not fs.existsSync(@imageDir) then fs.mkdirSync(@imageDir)

    atom.commands.add 'atom-text-editor',
      'markdown:grab': => @grab()
      'markdown:clean-grab': => @cleanGrab()

  cleanGrab: ->
    if not fs.existsSync @imageDir
      return

    images = fs.readdirSync @imageDir
    availableImages = []

    clean = =>
      for image in images
        if availableImages.indexOf(image) is -1
          fs.unlink path.join(@imageDir, image)

      if fs.readdirSync(@imageDir).length is 0
        fs.rmdir @imageDir

    options =
      paths: [ atom.project.relativizePath(@baseDir)[1] ]
      onPathsSearched: clean

    imageGrammerRegex = /!\[.*?\]\(image\/(.*?)\.png\)/
    imageRegex = /image\/([^)]*)/
    atom.workspace.scan imageGrammerRegex, options, (file) ->
      for match in file.matches
        image = imageRegex.exec(match.matchText)[1]
        availableImages.push image

  grab: ->
    image = clipboard.readImage()
    if image.isEmpty() then return

    dateStr = new Date().toISOString()
    imageFilename = dateStr.replace(/T|\..+|-|:/g, '') + @imageExtension
    imageFullpath = path.join @imageDir, imageFilename

    fs.writeFile imageFullpath, image.toPng(), (err) =>
      if err
        throw err
    selection = atom.workspace.getActivePaneItem().getLastSelection()
    selection.insertText "![图](#{@imageDirName}/#{imageFilename})"
