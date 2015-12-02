assert = require 'assert'

boston =
	_id: 'boston'
	name: 'Boston'
	team: 'Bruins'
	abbr: 'BOS'
	icon: 'boston.svg'

montreal =
	_id: 'montreal'
	name: 'Montreal'
	team: 'Canadiens'
	abbr: 'MTL'
	icon: 'montreal.svg'

philadelphia =
	_id: 'philadelphia'
	name: 'Philadelphia'
	team: 'Flyers'
	abbr: 'PHI'
	icon: 'philadelphia.svg'

teams = [
	boston
	montreal
	philadelphia
]




module.exports =
	list: (data, response) ->
		response teams