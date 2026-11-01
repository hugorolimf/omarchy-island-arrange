.pragma library

// The panel's texts, Portuguese or English by system language. Smart Windows sends
// the models' names and notes in Portuguese; these turn them into English.

var pt = {
  arrange: "ORGANIZAR", window: "JANELA", windows: "JANELAS", out: "DE FORA",
  apply: "APLICA", choose: "ESCOLHE", undo: "DESFAZ", leave: "SAI",
  suggested: "SUGERIDO", current: "ATUAL",
  rightLeaveOut: "BOTÃO DIREITO · DEIXA DE FORA", rightBack: "BOTÃO DIREITO · VOLTA",
  leftOut: "FICA DE FORA", inUse: "EM USO"
}

var en = {
  arrange: "ARRANGE", window: "WINDOW", windows: "WINDOWS", out: "LEFT OUT",
  apply: "APPLY", choose: "CHOOSE", undo: "UNDO", leave: "LEAVE",
  suggested: "SUGGESTED", current: "CURRENT",
  rightLeaveOut: "RIGHT CLICK · LEAVE OUT", rightBack: "RIGHT CLICK · BRING BACK",
  leftOut: "LEFT OUT", inUse: "IN USE"
}

var names = {
  "Tela toda": "Full screen", "Centro": "Centre", "Lado a lado": "Side by side",
  "Principal": "Main", "Em cima e embaixo": "Top and bottom", "Três colunas": "Three columns",
  "Principal + 2": "Main + 2", "Centro largo": "Wide centre", "Principal em cima": "Main on top",
  "Grade": "Grid", "Quatro colunas": "Four columns", "Principal + 3": "Main + 3",
  "Três e duas": "Three and two", "Principal + grade": "Main + grid", "Cinco colunas": "Five columns",
  "Seis colunas": "Six columns", "Duas fileiras": "Two rows"
}

var words = [
  ["MAXIMIZA", "MAXIMIZES"], ["NO MEIO", "CENTRED"], ["EMPILHADAS", "STACKED"],
  ["EMBAIXO", "BELOW"], ["CADA", "EACH"], ["CENTRO", "CENTRE"]
]

function forLocale(name) { return String(name || "").indexOf("pt") === 0 ? pt : en }
function modelName(name) { return names[name] || name }
function modelNote(note) {
  var text = String(note || "")
  for (var i = 0; i < words.length; i++) text = text.split(words[i][0]).join(words[i][1])
  return text
}
