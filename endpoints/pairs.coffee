assert = require 'assert'

ObjectID = require('mongodb').ObjectID

findPairs = (db, cb) ->
	collection = db.collection 'pairs'
	collection.find({}).toArray (err, pairs) ->
		assert.equal err, null
		cb pairs

insertPair = (db, data, cb) ->
	collection = db.collection 'pairs'
	data.date = Date.now()
	collection.insert [
		data
	], (err, result) ->
		assert.equal err, null
		cb result

removePair = (db, data, cb) ->
	return unless data._id

	removeMatchesByPairId db, data._id, ->
		collection = db.collection 'pairs'
		collection.remove {
			_id: ObjectID data._id
		}, (err, result) ->
			assert.equal err, null
			cb result

removeMatchesByPairId = (db, pairId, cb) ->
	return unless pairId
	collection = db.collection 'matches'
	collection.remove {
		pairId: pairId
	}, (err, result) ->
		assert.equal err, null
		cb result


module.exports =
	list: (data, response) ->
		findPairs mongodb, (pairs) ->
			response pairs

	insert: (data, response, socket) ->
		insertPair mongodb, data, (result) ->
			response result
			findPairs mongodb, (pairs) ->
				getResponseCallback(socket, '/pairs/list')(pairs)

	remove: (data, response, socket) ->
		removePair mongodb, data, (result) ->
			response result
			findPairs mongodb, (pairs) ->
				getResponseCallback(socket, '/pairs/list')(pairs)
				
