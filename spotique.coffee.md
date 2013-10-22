# Spotique

A minimal Meteor app for adding songs to a queue, with support for [Spotify's Play Button](https://developer.spotify.com/technologies/widgets/spotify-play-button/) when adding valid Spotify song URIs. 

---

Set the root scope.

	root = global ? window

Define collections and public methods.

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

Check if `text` is a valid Spotify URI on the form: `spotify:track:{22 chars, A-z, 0-9}`.

	Meteor.isSpotifyURI = (text) ->
		result = text.match(/spotify:track:([A-Za-z0-9]{22})/)
		result[1] if result?

Transform `text` to "song title" form: `this is a song -> This Is A Song`.

	Meteor.songify = (text) ->
		text.split(" ").map((word) -> word[0].toUpperCase() + word.substr(1).toLowerCase()).join(" ")

## Templates

	if Meteor.isClient

Sort by natural reversed order.

		Template.queue.suggestions = ->
			Suggestions.find({}, sort: {created_at: -1}).fetch()

		Template.queue.error = ->
			Session.get 'error'

		Template.suggestion.isSpotifyURI = (text) ->
			Meteor.isSpotifyURI(text)?

## Events

		Template.suggestion.events
			"click .mark-played": (evt, template) ->
				$(template.find(".mark-played")).attr("disabled", true)
				suggestion = Suggestions.findOne("_id._str": template.firstNode.id)

				if suggestion?
					suggestion.played = true
					$(template.firstNode).addClass("played")

Clear queue on click.

		Template.add.events
			"click #clear-queue": (evt, template) ->
				evt.preventDefault()
				Meteor.call "clearQueue"

Enable/disable submit button depending on if there is text in the input field.

			"input #suggestion": (evt, template) ->
				$input = $(template.firstNode)
				$input.nextAll("input").attr("disabled", not $input.val().length > 0)

Submit when hitting 'enter'.

			"keydown": (evt, template) ->
				switch evt.which
					when 13 then $(template.find("#submit")).trigger "click"

On submit, add the suggestion.

			"click #submit": (evt, template) ->
				value = $("#suggestion").val()
				$("#suggestion").val("").focus()
				$(template.find("#submit")).attr("disabled", true)

				Meteor.call "addSuggestion", value, (err, item) ->
					unless err?
						Session.set 'error', null
					else
						Session.set 'error', "Couldn't insert suggestion"

