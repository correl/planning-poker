// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"

import { Socket, Presence } from "phoenix"
import { Elm } from "../src/Main.elm"
import uuid4 from "uuid4"

var player_id = uuid4()

var socket = new Socket("/socket", {params: {player_id: player_id}})
socket.connect()

var app = Elm.Main.init({
    node: document.getElementById("elm-main"),
    flags: "player:" + player_id
})

app.ports.joinRoom.subscribe(options => {
    let channel = socket.channel("room:" + options.room, {})
    let presences = {}
    channel.on("presence_state", state => {
        console.log("presence state", state)
        presences = Presence.syncState(presences, state)
        app.ports.gotPresence.send(presences)
    })
    channel.on("presence_diff", diff => {
        console.log("presence diff", diff)
        presences = Presence.syncDiff(presences, diff)
        app.ports.gotPresence.send(presences)
    })
    app.ports.newProfile.subscribe(profile => {
        channel.push("new_profile", { "name": profile.playerName })
    })
    channel.join()
        .receive("ok", resp => {
            console.log("Joined successfully", resp);
        })
        .receive("error", resp => { console.log("Unable to join", resp) })

})
