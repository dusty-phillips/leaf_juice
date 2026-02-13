import etch/event
import etch/terminal
import gleam/erlang/process
import gleam/int
import leaf_juice
import leaf_juice/ui

pub fn main() {
  let exit = process.new_subject()
  let app = leaf_juice.LeafJuice(init, update, view, RuntimeEmittedEvent, exit)
  let assert Ok(_) = leaf_juice.start(app)

  process.receive_forever(exit)
  echo "bye"
}

type Model {
  Model(last_key: String, width: Int, height: Int, focused: Focus)
}

type Focus {
  FocusNone
  FocusOne
  FocusTwo
  FocusLastKey
}

fn next_focus(focus: Focus) -> Focus {
  case focus {
    FocusNone -> FocusOne
    FocusOne -> FocusTwo
    FocusTwo -> FocusLastKey
    FocusLastKey -> FocusOne
  }
}

type Msg {
  RuntimeEmittedEvent(event.Event)
}

fn init() -> #(Model, List(leaf_juice.Effect(Msg))) {
  let #(width, height) = terminal.window_size()
  #(Model(last_key: "None", width:, height:, focused: FocusNone), [])
}

fn update(model: Model, msg: Msg) -> #(Model, List(leaf_juice.Effect(Msg))) {
  case msg {
    RuntimeEmittedEvent(event.Key(event.KeyEvent(code: event.Char("q"), ..))) -> #(
      model,
      [leaf_juice.Exit],
    )

    RuntimeEmittedEvent(event.Key(event.KeyEvent(code: event.Char("\t"), ..))) -> #(
      Model(..model, focused: next_focus(model.focused)),
      [],
    )

    RuntimeEmittedEvent(event.Key(event.KeyEvent(code: event.Char("\u{1b}"), ..))) -> #(
      Model(..model, focused: FocusNone),
      [],
    )

    RuntimeEmittedEvent(event.Key(key_event)) -> #(
      Model(..model, last_key: event.to_string(key_event.code)),
      [],
    )

    RuntimeEmittedEvent(event.Resize(width, height)) -> #(
      Model(..model, width:, height:),
      [],
    )
  }
}

fn view(model: Model) -> ui.Node {
  ui.OutlinedBox(
    ui.Grid([ui.Cells(6), ui.Cells(7), ui.Auto], [ui.Cells(20), ui.Auto], [
      ui.GridCell(
        ui.OutlinedBox(ui.Button("1", is_focused: model.focused == FocusOne)),
        rows: #(0, 0),
        columns: #(0, 0),
      ),
      ui.GridCell(
        ui.Button("2", is_focused: model.focused == FocusTwo),
        rows: #(1, 2),
        columns: #(0, 0),
      ),
      ui.GridCell(
        ui.OutlinedBox(ui.Text(
          int.to_string(model.width) <> ", " <> int.to_string(model.height),
        )),
        rows: #(0, 0),
        columns: #(1, 1),
      ),
      ui.GridCell(ui.OutlinedBox(ui.Text("4")), rows: #(1, 1), columns: #(1, 1)),
      ui.GridCell(
        ui.Button(model.last_key, is_focused: model.focused == FocusLastKey),
        rows: #(2, 2),
        columns: #(1, 1),
      ),
    ]),
  )
}
