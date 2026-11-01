import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.Commons as Commons
import "Strings.js" as Strings

// Island Arrange. Super + A: how to arrange the windows of a screen. The models,
// and where each window would land in them, come from Smart Windows (Hyprland
// config): it writes them to $XDG_RUNTIME_DIR/island-arrange/models.json and calls
//   omarchy-shell io.github.hugorolimf.arrange showFile <that path>
//   { s, mon, r, area: {x, y, w, h}, undo, sel,
//     w: [{a, c, t, main, out, x, y, w, h}],
//     m: [{id, name, note, cur, sug, spots: [{x, y, w, h, i}]}] }
// (screen coordinates of that monitor; i is the window landing in a spot;
// out: left out of the arrangement, staying where it is; r: the same panel
// again after a window was left out or put back).
// This panel shows them: a card per model, drawn with the windows' icons,
// and the highlighted one previewed on the screen itself, the windows gliding
// from where they are to where they would go. A right click on a window
// leaves it out (or puts it back). The answer goes back to Lua:
// windowing_layout_pick(s, k), windowing_layout_undo(s), windowing_layout_cancel(s),
// windowing_layout_exclude(s, address).
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property var t: Strings.forLocale(Qt.locale().name)
  readonly property bool pt: Qt.locale().name.indexOf("pt") === 0
  function modelName(name) { return pt ? name : Strings.modelName(name) }
  function modelNote(note) { return pt ? note : Strings.modelNote(note) }

  property bool active: false
  property int session: 0
  property string monitorName: ""
  property var area: ({ x: 0, y: 0, w: 1, h: 1 })
  property var wins: []
  property var models: []
  property bool canUndo: false
  property int current: 0
  // Off for a moment after showing, so the preview starts where the windows are.
  property bool settled: false
  Timer { id: settle; interval: 40; onTriggered: root.settled = true }

  function show(text) {
    var p
    try { p = JSON.parse(text) } catch (e) { return "bad payload" }
    if (!p.m || p.m.length === 0) return "empty"
    // A window left out or put back: new models, the same kind highlighted.
    if (p.r) {
      if (!active || p.mon !== monitorName) return "stale"
      var was = models[current] ? models[current].id : ""
      session = p.s
      wins = p.w || []
      models = p.m
      canUndo = !!p.undo
      var at = Math.max(0, Math.min(models.length - 1, p.sel || 0))
      for (var j = 0; j < models.length; j++) if (models[j].id === was) at = j
      current = at
      return "refreshed"
    }
    // Super + A again while it is up: the highlighted model.
    if (active && p.mon === monitorName) {
      var keep = models[current] ? models[current].id : ""
      session = p.s
      models = p.m
      var k = p.sel || 0
      for (var i = 0; i < models.length; i++) if (models[i].id === keep) k = i
      apply(k)
      return "applied"
    }
    session = p.s
    monitorName = p.mon || ""
    area = p.area || area
    wins = p.w || []
    models = p.m
    canUndo = !!p.undo
    current = Math.max(0, Math.min(models.length - 1, p.sel || 0))
    settled = false
    active = true
    settle.restart()
    return "ok"
  }

  function lua(call) { Quickshell.execDetached(["hyprctl", "eval", call]) }
  function apply(k) {
    if (!active || !models[k]) return
    active = false
    lua("windowing_layout_pick(" + session + ", " + (k + 1) + ")")
  }
  function undo() {
    if (!active || !canUndo) return
    active = false
    lua("windowing_layout_undo(" + session + ")")
  }
  function cancel() {
    if (!active) return
    active = false
    lua("windowing_layout_cancel(" + session + ")")
  }
  function exclude(address) {
    var a = String(address || "")
    if (!active || !/^0x[0-9a-fA-F]+$/.test(a)) return
    lua("windowing_layout_exclude(" + session + ", \"" + a + "\")")
  }
  readonly property int inCount: {
    var n = 0
    for (var i = 0; i < wins.length; i++) if (!wins[i].out) n++
    return n
  }
  function step(d) { if (models.length > 0) current = (current + d + models.length) % models.length }

  function key(e) {
    var k = e.key
    if (k >= Qt.Key_1 && k <= Qt.Key_9) apply(k - Qt.Key_1)
    else if (k === Qt.Key_0 || k === Qt.Key_Backspace) undo()
    else if (k === Qt.Key_Right || k === Qt.Key_Down || (k === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) step(1)
    else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_Backtab) step(-1)
    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) apply(current)
    else if (k === Qt.Key_Escape) cancel()
    else return
    e.accepted = true
  }

  // Where window i lands in model k.
  function spotFor(k, i) {
    var m = models[k]
    if (!m) return null
    for (var j = 0; j < m.spots.length; j++) if (m.spots[j].i === i) return m.spots[j]
    return null
  }

  function toplevelFor(address) {
    var a = String(address || "").replace(/^0x/, "")
    var list = Hyprland.toplevels.values || []
    for (var i = 0; i < list.length; i++)
      if (String(list[i].address || "").replace(/^0x/, "") === a) return list[i]
    return null
  }

  function iconFor(appId) {
    var id = String(appId || "")
    var e = id ? (DesktopEntries.heuristicLookup(id) || DesktopEntries.byId(id)) : null
    var tries = [e && e.icon ? e.icon : "", id, id.toLowerCase()]
    for (var i = 0; i < tries.length; i++) {
      if (!tries[i]) continue
      var path = Quickshell.iconPath(tries[i], true)
      if (path) return path
    }
    return Quickshell.iconPath("application-x-executable", true)
  }

  readonly property var terminals: ["foot", "kitty", "alacritty", "ghostty", "wezterm", "org.wezfurlong.wezterm", "xterm", "com.mitchellh.ghostty"]
  function appLabel(appId) {
    var id = String(appId || "")
    if (terminals.indexOf(id.toLowerCase()) >= 0) return "Terminal"
    var e = id ? (DesktopEntries.heuristicLookup(id) || DesktopEntries.byId(id)) : null
    return e && e.name ? e.name : id
  }
  // Claude Code puts a glyph before the session name in the window title.
  function cleanTitle(title) {
    var t = String(title || "")
    return /^([✳✻✽✶✢◐-◓⠀-⣿])\s+/.test(t) ? t.replace(/^\S+\s+/, "") : t
  }

  FileView {
    id: reader
    blockLoading: true
    printErrors: false
  }

  IpcHandler {
    target: "io.github.hugorolimf.arrange"
    // The models in a private file (Smart Windows writes it under
    // $XDG_RUNTIME_DIR/island-arrange), so titles never sit in a command line.
    function showFile(path: string): string {
      var p = String(path || "")
      if (p !== Quickshell.env("XDG_RUNTIME_DIR") + "/island-arrange/models.json") return "bad path"
      reader.path = p
      var text = reader.text()
      reader.path = ""
      return root.show(text)
    }
    function hide(): string { root.cancel(); return "ok" }
    function state(): string { return root.active ? "shown " + root.session + " " + root.current + "/" + root.models.length : "hidden" }
  }

  // The look follows anatomy, like Glass Alt+Tab: grey hairlines, mono
  // labels, colour only for a state. Greys come from the theme's menu colours.
  readonly property color ink: Commons.Color.menu.text
  readonly property color paper: Commons.Color.menu.background
  function ink_(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
  function paper_(a) { return Qt.rgba(paper.r, paper.g, paper.b, a) }
  readonly property string sans: "Adwaita Sans"
  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property var ease: [0.32, 0.72, 0, 1, 1, 1]

  // One overlay per screen, mapped only while it shows (it takes the keyboard).
  Variants {
    model: Quickshell.screens
    delegate: PanelWindow {
      id: win
      required property var modelData
      screen: modelData
      readonly property var monitor: Hyprland.monitorFor(modelData)
      readonly property bool shown: root.active && !!monitor && monitor.name === root.monitorName
      visible: shown
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "island-arrange"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore

      onShownChanged: if (shown) { fadeIn.restart(); Qt.callLater(function() { keys.forceActiveFocus() }) }

      Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        NumberAnimation { id: fadeIn; target: stage; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }

        Item {
          id: keys
          focus: true
          Keys.onPressed: function(e) { root.key(e) }
        }

        // The screen dims; a click anywhere but the panel leaves.
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.5) }
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }

        // The preview: every window where the highlighted model puts it.
        Repeater {
          model: win.shown ? root.wins.length : 0
          delegate: ArrangeZone {
            arrange: root
            panelTop: plate.y
          }
        }

        ArrangePlate {
          id: plate
          arrange: root
          screenWidth: win.width
        }
      }
    }
  }

  function open(payloadJson) {}
  function close() {}
}
