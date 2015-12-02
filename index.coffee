#
# MONGO
#

MongoClient = require('mongodb').MongoClient
assert = require 'assert'

url = 'mongodb://localhost:27017/myproject'
global.mongodb = mongodb = null


MongoClient.connect url, (err, db) ->
	assert.equal null, err
	console.log 'Connected correctly to mongo server'

	db.on 'close', ->
		mongodb = null
		console.log 'DB CLOSED'

	global.mongodb = mongodb = db
	return

insertDocuments = (db, cb) ->
	collection = db.collection 'matches'
	collection.insert [
		{ id: 1, date: Date.now(), teamA: { name: 'PHI', score: 0, shots: 0 }, teamB: { name: 'BOS', score: 5, shots: 43 } }
	], (err, result) ->
		assert.equal err, null
		console.log 'data inserted'
		cb result

process.on 'exit', ->
	console.log 'Closing mongodb connection'
	mongodb.close() if mongodb
	mongodb = null

#
# Express
#


app = require('express')()
http = require('http').Server app
io = require('socket.io')(http)

endpoints =
	matches: require './endpoints/matches'
	pairs: require './endpoints/pairs'
	teams: require './endpoints/teams'

socketCount = 0

app.get '/', (req, res) ->
	mongoState = if mongodb? then 'connected' else 'disconnected'
	res.send """
		<strong>Hockey app backend is up and running :)</strong>
		<div>MongoDB state: #{mongoState}</div>
		<div>Amount of connected users: #{socketCount}</div>
	"""

global.getResponseCallback = (socket, endpoint) ->
	(data) ->
		socket.emit 'data',
			endpoint: endpoint
			value: JSON.stringify data

io.on 'connection', (socket) ->
	socketCount++
	console.log 'Socket.io: a client connected'

	socket.on 'data', (msg) ->
		console.log 'Socket.io message: ', msg
		return unless msg?.endpoint and typeof(msg.endpoint) is 'string'

		path = msg.endpoint.split '/'
		path.shift() if path[0].length is 0

		endpoints[path[0]]?[path[1]]? msg.value, getResponseCallback(socket, msg.endpoint), socket

	socket.on 'disconnect', ->
		socketCount--
		console.log 'Socket.io: a client disconnected'

http.listen 3000, ->
	console.log('listening on *:3000');