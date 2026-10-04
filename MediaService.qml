import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Item {
  id: root

  property var shell: null

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: chooseActivePlayer()
  readonly property bool hasMedia: !!(activePlayer && (activePlayer.trackTitle || activePlayer.trackArtist || activePlayer.trackAlbum || activePlayer.trackArtUrl))
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer ? (activePlayer.trackAlbum || "") : ""
  readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
  readonly property string playbackStatus: !activePlayer ? "Stopped" : (activePlayer.isPlaying ? "Playing" : "Paused")
  readonly property string providerName: playerLabel(
    activePlayer,
    activePlayer ? activePlayer.metadata : null,
    activePlayer ? activePlayer.trackArtist : "",
    activePlayer ? activePlayer.trackAlbum : "",
    activePlayer ? activePlayer.trackAlbumArtist : "",
    activePlayer ? activePlayer.trackArtUrl : "")
  readonly property bool durationSupported: !!(activePlayer && activePlayer.lengthSupported)
  readonly property bool positionSupported: !!(activePlayer && activePlayer.positionSupported)
  readonly property real duration: durationSupported ? Math.max(0, Number(activePlayer.length) || 0) : 0
  readonly property real position: positionSupported ? Math.max(0, Number(activePlayer.position) || 0) : 0
  readonly property real progress: duration > 0 ? Math.max(0, Math.min(1, position / duration)) : 0
  readonly property bool canSeek: !!(activePlayer && activePlayer.canSeek && activePlayer.positionSupported && activePlayer.lengthSupported && duration > 0)

  function hasTrackInfo(player) {
    return !!(player && (player.trackTitle || player.trackArtist || player.trackAlbum || player.trackArtUrl))
  }

  function canControlPlayback(player) {
    return !!(player && (player.canTogglePlaying || player.canPlay || player.canPause))
  }

  function chooseActivePlayer() {
    var trackPlayer = null
    var controllablePlayer = null

    for (var i = 0; i < players.length; i++) {
      var player = players[i]
      if (!player) continue

      if (player.isPlaying && hasTrackInfo(player)) return player
      if (!trackPlayer && hasTrackInfo(player)) trackPlayer = player
      if (!controllablePlayer && canControlPlayback(player)) controllablePlayer = player
    }

    return trackPlayer || controllablePlayer || null
  }

  function playerLabel(player, metadata, trackArtist, trackAlbum, trackAlbumArtist, trackArtUrl) {
    if (!player) return "MPRIS"

    metadata = metadata || player.metadata || ({})
    var trackUrls = [
      String(metadata["xesam:url"] || "").toLowerCase(),
      String(metadata["mpris:url"] || "").toLowerCase()
    ]
    var artworkUrl = String(trackArtUrl || metadata["mpris:artUrl"] || "").toLowerCase()
    var album = String(trackAlbum || metadata["xesam:album"] || "").trim()
    var artist = String(trackArtist || metadata["xesam:artist"] || "").trim()
    var albumArtist = String(trackAlbumArtist || metadata["xesam:albumArtist"] || "").trim()
    var identity = String(player.identity || "")
    var desktopEntry = String(player.desktopEntry || "")
    var dbusName = String(player.dbusName || "")
    var combined = (identity + " " + desktopEntry + " " + dbusName).toLowerCase()
    var isChrome = combined.indexOf("chrome") !== -1 || combined.indexOf("chromium") !== -1
    var isYouTubeMusicUrl = false
    var isYouTubeUrl = false

    for (var i = 0; i < trackUrls.length; i++) {
      var url = trackUrls[i]
      if (url.indexOf("music.youtube.com") !== -1 || url.indexOf("youtube.com/music") !== -1)
        isYouTubeMusicUrl = true
      else if (url.indexOf("youtube.com/") !== -1 || url.indexOf("youtu.be/") !== -1)
        isYouTubeUrl = true
    }

    if (combined.indexOf("youtube music") !== -1
        || combined.indexOf("ytmusic") !== -1
        || isYouTubeMusicUrl
        || (isChrome && artworkUrl.indexOf("googleusercontent.com") !== -1)
        || (isChrome && album !== "" && (artist !== "" || albumArtist !== "")))
      return "YouTube Music"

    if (isYouTubeUrl || artworkUrl.indexOf("ytimg.com/") !== -1)
      return "YouTube"

    if (identity) return identity
    if (desktopEntry) return desktopEntry
    if (dbusName.indexOf("org.mpris.MediaPlayer2.") === 0)
      return dbusName.slice("org.mpris.MediaPlayer2.".length).replace(/\.instance[0-9]+$/, "")
    return dbusName || "Media player"
  }

  function formatTime(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var minutes = Math.floor(value / 60)
    var remainder = value % 60
    return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
  }

  function togglePlaying() {
    var player = activePlayer
    if (!player) return false

    if (player.isPlaying && player.canPause) {
      player.pause()
      return true
    }
    if (!player.isPlaying && player.canPlay) {
      player.play()
      return true
    }
    if (player.canTogglePlaying) {
      player.togglePlaying()
      return true
    }
    return false
  }

  function previous() {
    if (!activePlayer || !activePlayer.canGoPrevious) return false
    activePlayer.previous()
    return true
  }

  function next() {
    if (!activePlayer || !activePlayer.canGoNext) return false
    activePlayer.next()
    return true
  }

  function seekToRatio(ratio) {
    if (!canSeek) return false
    var clamped = Math.max(0, Math.min(1, Number(ratio) || 0))
    activePlayer.position = clamped * duration
    return true
  }

  function toggleShuffle() {
    if (!activePlayer || !activePlayer.canControl || !activePlayer.shuffleSupported) return false
    activePlayer.shuffle = !activePlayer.shuffle
    return true
  }

  function cycleRepeat() {
    if (!activePlayer || !activePlayer.canControl || !activePlayer.loopSupported) return false

    if (activePlayer.loopState === MprisLoopState.None)
      activePlayer.loopState = MprisLoopState.Playlist
    else if (activePlayer.loopState === MprisLoopState.Playlist)
      activePlayer.loopState = MprisLoopState.Track
    else
      activePlayer.loopState = MprisLoopState.None

    return true
  }

  Timer {
    interval: 1000
    repeat: true
    running: !!root.activePlayer && root.activePlayer.isPlaying

    onTriggered: {
      if (root.activePlayer && root.activePlayer.positionSupported)
        root.activePlayer.positionChanged()
    }
  }
}
