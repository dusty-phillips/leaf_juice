import etch/command
import etch/event
import etch/stdout
import etch/terminal
import gleam/option

pub type LeafJuice(model, msg) {
  LeafJuice(
    init: fn() -> #(model, List(fn() -> msg)),
    update: fn(model, msg) -> #(model, List(fn() -> msg)),
    view: fn(model) -> stdout.Queue,
    map_event: fn(event.Event) -> msg,
  )
}

fn start(app: LeafJuice(model, msg)) -> Nil {
  let #(model, effects) = app.init()

  stdout.execute([
    command.EnterRaw,
    command.EnterAlternateScreen,
    command.Clear(terminal.All),
    command.MoveTo(0, 0),
    command.EnableMouseCapture,
  ])

  event.init_event_server()
  loop(app, model, effects)
}

fn loop(app: LeafJuice(model, msg), model: model, effects: List(fn() -> msg)) {
  let queue = app.view(model)
  stdout.flush(queue)

  let #(next_model, next_effects) =
    handle_input(model, app.map_event, app.update)

  loop(app, next_model, next_effects)
}

fn handle_input(
  model: model,
  map_event: fn(event.Event) -> msg,
  update: fn(model, msg) -> #(model, List(fn() -> msg)),
) -> #(model, List(fn() -> msg)) {
  case event.read() {
    option.Some(Ok(event)) -> update(model, map_event(event))
    option.Some(Error(_)) | option.None -> todo
  }
}

// SPECIFIC APP

pub fn main() {
  let app = LeafJuice(init, update, view, RuntimeEmittedEvent)
  start(app)
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

fn view(model: Model) -> stdout.Queue {
  let queue = stdout.Queue([])
  stdout.queue(queue, [
    command.Clear(terminal.All),
    command.MoveTo(5, 8),
    command.Println(model.last_key),
  ])
}
