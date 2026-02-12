import etch/event
import etch/terminal
import gleam/erlang/process
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
  Model(last_key: String, width: Int, height: Int)
}

type Msg {
  RuntimeEmittedEvent(event.Event)
}

fn init() -> #(Model, List(leaf_juice.Effect(Msg))) {
  let #(width, height) = terminal.window_size()
  #(Model(last_key: "None", width:, height:), [])
}

fn update(model: Model, msg: Msg) -> #(Model, List(leaf_juice.Effect(Msg))) {
  case msg {
    RuntimeEmittedEvent(event.Key(event.KeyEvent(code: event.Char("q"), ..))) -> #(
      model,
      [leaf_juice.Exit],
    )
    RuntimeEmittedEvent(event.Key(key_event)) -> #(
      Model(..model, last_key: event.to_string(key_event.code)),
      [],
    )
    RuntimeEmittedEvent(event.Resize(width, height)) -> #(
      Model(..model, width:, height:),
      [],
    )
    RuntimeEmittedEvent(_) -> #(model, [])
  }
}

fn view(model: Model) -> ui.Node {
  ui.OutlinedBox(
    ui.Grid([ui.Cells(3), ui.Cells(5), ui.Auto], [ui.Cells(20), ui.Auto], [
      ui.GridCell(ui.OutlinedBox(ui.Text("1")), rows: #(0, 0), columns: #(0, 0)),
      ui.GridCell(ui.OutlinedBox(ui.Text("2")), rows: #(1, 2), columns: #(0, 0)),
      ui.GridCell(ui.OutlinedBox(ui.Text("3")), rows: #(0, 0), columns: #(1, 1)),
      ui.GridCell(ui.OutlinedBox(ui.Text("4")), rows: #(1, 1), columns: #(1, 1)),
      ui.GridCell(
        ui.OutlinedBox(ui.Text(model.last_key)),
        rows: #(2, 2),
        columns: #(1, 1),
      ),
    ]),
  )
}
