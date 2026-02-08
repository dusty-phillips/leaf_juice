import etch/command
import etch/event
import gleam/erlang/process
import leaf_juice

pub fn main() {
  let app = leaf_juice.LeafJuice(init, update, view, RuntimeEmittedEvent)
  let assert Ok(_) = leaf_juice.start(app)
  process.sleep(10_000)
}

type Model {
  Model(last_key: String)
}

type Msg {
  RuntimeEmittedEvent(event.Event)
}

fn init() -> #(Model, List(fn() -> Msg)) {
  #(Model("None"), [])
}

fn update(model: Model, msg: Msg) -> #(Model, List(fn() -> Msg)) {
  case msg {
    RuntimeEmittedEvent(event.Key(key_event)) -> #(
      Model(event.to_string(key_event.code)),
      [],
    )
    RuntimeEmittedEvent(_) -> #(model, [])
  }
}

fn view(model: Model) -> List(command.Command) {
  [
    command.MoveTo(0, 0),
    command.Println(model.last_key),
  ]
}
