assert = require 'assert'

ObjectID = require('mongodb').ObjectID

findMatches = (db, cb) ->
	collection = db.collection 'matches'
	collection.find({}).toArray (err, matches) ->
		assert.equal err, null
		cb matches

insertMatch = (db, data, cb) ->
	collection = db.collection 'matches'
	data.date = Date.now()
	collection.insert [
		data
	], (err, result) ->
		assert.equal err, null
		console.log 'data inserted'
		cb result

removeMatch = (db, data, cb) ->
	return unless data._id
	collection = db.collection 'matches'
	collection.remove {
		_id: ObjectID data._id
	}, (err, result) ->
		assert.equal err, null
		cb result



module.exports =
	list: (data, response) ->
		findMatches mongodb, (matches) ->
			response matches

	insert: (data, response, socket) ->
		insertMatch mongodb, data, (result) ->
			response result
			findMatches mongodb, (matches) ->
				getResponseCallback(socket, '/matches/list')(matches)

	remove: (data, response, socket) ->
		console.log 'Remove match: ' + data?._id
		removeMatch mongodb, data, (result) ->
			response result
			findMatches mongodb, (matches) ->
				getResponseCallback(socket, '/matches/list')(matches)
				
