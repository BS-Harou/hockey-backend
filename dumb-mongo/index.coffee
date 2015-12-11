fs = require 'fs'
EventEmitter = require('events').EventEmitter
_ = require 'underscore'

WRITE_TIMEOUT = 100 # ms

MongoClient =
	_databases: []
	connect: (url, cb) ->
		fs.open url, 'r+', (err, fd) =>
			if err
				cb err
				return

			MongoClient._databases.push new Database fd, cb
			return

class Database extends EventEmitter

	data: null
	fd: null
	writeTimeout: null
	writeCallbacks: null

	constructor: (@fd, cb) ->
		@_readData cb
		@writeCallbacks = []

	close: ->
		fs.close @fd, =>
			@emit 'close'

	collection: (name) ->
		@data.collections[name] = [] unless Array.isArray @data.collections[name]
		new Collection name, @

	_readData: (cb) ->
		fs.readFile @fd, 'utf8', (err, data) =>
			if err
				console.log 'WRITE ERROR: ', err 
				return

			try	@data = JSON.parse data

			unless @data
				@data =
					collections: {}
					indicies: {}

			cb null, @ if cb

	_writeData: (cb) ->
		@writeCallbacks.push cb if cb
		unless @writeTimeout
			setTimeout @_actualWriteData, WRITE_TIMEOUT

	_actualWriteData: =>
		@writeTimeout = null
		data = JSON.stringify @data
		fs.truncate @fd, 0, (err) =>
			if err
				console.log 'WRITE ERROR: ', err
				wcb err for wcb in @writeCallbacks
				@writeCallbacks = []
				return
			fs.writeFile @fd, data, 'utf8', (err, data) =>
				console.log 'WRITE ERROR: ', err if err
				wcb err, { ok: !err } for wcb in @writeCallbacks
				@writeCallbacks = []
				return

class Collection extends EventEmitter

	name: null
	dataSource: null

	constructor: (@name, @dataSource) ->

	###*
		@param {!Array.<!Object>|!Object} data
	###
	insert: (data, cb)  ->
		data = [data] unless Array.isArray data
		for row in data
			row['_id'] = String(Math.random()) unless row['_id']
			@dataSource.data.collections[@name].push row 
		@dataSource._writeData cb

	###*
		@param {!Object} query
	###
	find: (query, cb) ->
		result = _.where @dataSource.data.collections[@name], query
		cb null, result if cb

		{
			toArray: (_cb) ->
				_cb null, result if _cb
		}

	###*
		@param {!Object} query
	###
	remove: (query, cb) ->
		result = _.where @dataSource.data.collections[@name], query
		@dataSource.data.collections[@name] = _.without @dataSource.data.collections[@name], result
		@dataSource._writeData()
		cb null, result  if cb



module.exports =
	MongoClient: MongoClient
	ObjectID: (str) -> str