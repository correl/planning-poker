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
var room_id  = uuid4()

var socket = new Socket("/socket", {params: {player_id: player_id}})
socket.connect()

var app = Elm.Main.init({
    node: document.getElementById("elm-main"),
    flags: {
        player: player_id,
        room: room_id,
        width: window.innerWidth,
        height: window.innerHeight
    }
})

app.ports.joinRoom.subscribe(options => {
    let channel = socket.channel("room:" + options.room, {})

    // Presence events
    channel.on("presence_state", app.ports.gotPresenceState.send)
    channel.on("presence_diff", app.ports.gotPresenceDiff.send)

    // Incoming room events
    channel.on("vote", app.ports.gotVote.send)
    channel.on("reset", app.ports.gotReset.send)
    channel.on("reveal", app.ports.gotReveal.send)

    // Outgoing room events
    app.ports.roomActions.subscribe(action => {
        channel.push(action.type, action.data)
    })

    channel.join()
        .receive("ok", resp => {
            console.log("Joined successfully", resp);
        })
        .receive("error", resp => { console.log("Unable to join", resp) })

})
