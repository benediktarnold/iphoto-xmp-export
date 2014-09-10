sqlite3 = require('sqlite3').verbose()
exif = require 'exiftool'
fs = require 'fs'
parseArgs = require 'minimist'
path = require 'path'
async = require 'async'
exec = require('child_process').execFile

args = require('minimist')(process.argv.slice(2) )

if args.faces
	console.log "faces"

if args.keywords
	console.log "keywords"



exifCreateDate = (path, callback) ->
	fs.readFile path, (err, data) ->
		if err
			throw err
		else
		exif.metadata data, ['-CreateDate'], callback

extractFaces = (library, faces)-> 
	(fullpath, cb) ->
		file = path.basename(fullpath)
		exifCreateDate fullpath, (err, data) ->
			library.all "select RKMaster.uuid, strftime('%Y:%m:%d %H:%M:%S',fileCreationDate,'unixepoch','31 years','localtime') as CreateDate, RKMaster.fileName from RKMaster where RKMAster.originalFileName =? and RKMaster.fileisReference=0", [file], (err2, masters) ->
				selectedExif = masters.filter (result) -> result.CreateDate == data.createDate
				master = selectedExif[0]
				if master
					library.all "select RKKeyword.name from RKKeyword join RKKeywordForVersion on RKKeyword.modelId=RKKeywordForVersion.keywordId join RKVersion on RKKeywordForVersion.versionId=RKVErsion.modelId where RKVersion.masterUuid=?",[master.uuid], (err5,keywords)->
						faces.all "select RKFaceName.name, RKDetectedFace.masterUuid from RKFaceName INNER JOIN RKDetectedFace  USING (faceKey) WHERE RKDetectedFace.masterUuid=?", [master.uuid], (err3, faces) ->
							#console.log(err5, keywords, master)
							keywordNames = keywords.map (keyword) -> keyword.name
							names = faces.map (face) -> "People|#{face.name}"
							combined = keywordNames.concat names
							if combined.length > 0
								exifArgs = combined.map (keyword)-> "-XMP:HierarchicalSubject=#{keyword}"
								
								xmpFile = fullpath.split(".")[0]+".xmp"
								exifArgs.push xmpFile
								exec("exiftool",exifArgs,cb)
							else
								cb null
				else 
					cb null

withFacesAndLibrary= (bothDBReady)->
	flow =
		library: (callback)->
			library = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Library.apdb', sqlite3.OPEN_READONLY, ->
				callback null,library
		faces: (callback)->
			faces = new sqlite3.Database '/Users/ben/Desktop/Database/apdb/Faces.db', sqlite3.OPEN_READONLY, ->
				callback null,faces
	async.parallel flow, bothDBReady

withFacesAndLibrary (err,results)->
	library = results.library
	faces = results.faces
	#console.log library, faces

	files = args._

	async.eachLimit files, 5, extractFaces(library,faces), (err)->
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
