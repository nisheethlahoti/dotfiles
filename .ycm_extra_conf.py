def FlagsForFile( filename, **kwargs ):
	return {
		'flags': [ '-x', 'c++', '-std=gnu++1z', '-Wall',  '-Werror' ],
	}
