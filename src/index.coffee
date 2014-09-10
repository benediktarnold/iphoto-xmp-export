sqlite3 = require('sqlite3').verbose()
exif = require 'exiftool'
fs = require 'fs'
parseArgs = require 'minimist'
path = require 'path'
async = require 'async'
next = require 'nextflow'

args = require('minimist')(process.argv.slice(2) )



createDate = (path, callback) ->
	fs.readFile path, (err, data) ->
		if err
			throw err
		else
		exif.metadata data, ['-CreateDate'], callback

outputKeywords = (library, faces, fullpath, cb) ->
	file = path.basename(fullpath)
	createDate fullpath, (err, data) ->
		library.all "select RKMaster.uuid, strftime('%Y:%m:%d %H:%M:%S',fileCreationDate,'unixepoch','31 years','localtime') as CreateDate, RKMaster.fileName from RKMaster where RKMAster.originalFileName =? and RKMaster.fileisReference=0;", [file], (err2, masters) ->
			selectedExif = masters.filter (result) -> result.CreateDate == data.createDate
			#console.log(selectedExif)
			faces.all "select RKFaceName.name, RKDetectedFace.masterUuid from RKFaceName INNER JOIN RKDetectedFace  USING (faceKey) WHERE RKDetectedFace.masterUuid=?", [selectedExif[0].uuid], (err3, faces) ->
				names = faces.map (face) -> face.name
				nameString = names.join ", "
				console.log "\"#{fullpath}\";\"#{nameString}\""
				cb null


flow =
	library: (callback)->
		library = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Library.apdb', sqlite3.OPEN_READONLY, ->
			callback null,library
	faces: (callback)->
		faces = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Faces.db', sqlite3.OPEN_READONLY, ->
			callback null,faces

async.parallel flow, (err,results)->
	library = results.library
	faces = results.faces
	#console.log library, faces

	extractKeywords = (file,cb)->
		outputKeywords library, faces, file, cb

	files = args._
	#console.log(files)
		
	#extractKeywords file for file in files

	async.eachLimit files, 5, extractKeywords, (err)->
    	if err
    		console.err err

	library.close
	faces.close

###
library = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Library.apdb', sqlite3.OPEN_READONLY, ->
	faces = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Faces.db', sqlite3.OPEN_READONLY, ->

		extractKeywords = (file)->
			outputKeywords library, faces, file

		files = require('minimist')(process.argv.slice(2) )._
		console.log(files)
		
		extractKeywords file for file in files

		library.close
		faces.close
###
