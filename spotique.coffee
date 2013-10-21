root = global ? window

root.Suggestions = new Meteor.Collection "suggestions", idGeneration: "MONGO"

Meteor.methods
	clearQueue: ->
		Suggestions.remove({})

	addSuggestion: (text) ->
		text = Meteor.songify(text) unless Meteor.isSpotifyURI(text)

		Suggestions.insert
			value: text
			created_at: new Date().getTime()
			played: false

Meteor.isSpotifyURI = (text) ->
	result = text.match(/spotify:track:([A-Za-z0-9]{22})/)
	result[1] if result?

Meteor.songify = (text) ->
	text.split(" ").map((word) -> word[0].toUpperCase() + word.substr(1).toLowerCase()).join(" ")


if Meteor.isClient

	Template.queue.suggestions = ->
		Suggestions.find({}, sort: {created_at: -1}).fetch()

	Template.queue.error = ->
		Session.get 'error'

	Template.suggestion.isSpotifyURI = (text) ->
		Meteor.isSpotifyURI(text)?

	Template.suggestion.events
		"click .mark-played": (evt, template) ->
			$(template.find(".mark-played")).attr("disabled", true)
			suggestion = Suggestions.findOne("_id._str": template.firstNode.id)

			if suggestion?
				suggestion.played = true
				$(template.firstNode).addClass("played")

	Template.add.events
		"click #clear-queue": (evt, template) ->
			evt.preventDefault()
			Meteor.call "clearQueue"

		"input #suggestion": (evt, template) ->
			$input = $(template.firstNode)
			$input.nextAll("input").attr("disabled", not $input.val().length > 0)

		"keydown": (evt, template) ->
			switch evt.which
				when 13 then $(template.find("#submit")).trigger "click"

		"click #submit": (evt, template) ->
			value = $("#suggestion").val()
			$("#suggestion").val("").focus()
			$(template.find("#submit")).attr("disabled", true)

			Meteor.call "addSuggestion", value, (err, item) ->
				unless err?
					Session.set 'error', null
				else
					Session.set 'error', "Couldn't insert suggestion"

