module.exports = ->
	@initConfig
		#pkg: grunt.file.readJSON('package.json')
		coffee:
			build:
				expand: true
				cwd: 'src'
				src: [ '**/*.coffee' ]
				dest: 'tmp'
				ext: '.js'
		clean: ["tmp", "build"]
		meta:
			shebang: '#!/usr/bin/env node'
		concat:
		  # Prepend the node shebang line
			executables:
				options:
					banner: '<%= meta.shebang %>\n\n'
				src: ['./tmp/index.js'] # .tmp = directory where coffee compiled into
				dest: './build/index.js'


	@loadNpmTasks 'grunt-contrib-coffee'
	@loadNpmTasks 'grunt-contrib-concat'
	@loadNpmTasks 'grunt-contrib-clean'

	@registerTask 'default', ['coffee','concat']