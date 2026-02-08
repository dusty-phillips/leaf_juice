import etch/command
import etch/event
import etch/stdout
import etch/terminal
import gleam/option

pub type LeafJuice(model, msg) {
  LeafJuice(
    init: fn() -> #(model, List(fn() -> msg)),
    update: fn(model, msg) -> #(model, List(fn() -> msg)),
    view: fn(model) -> List(command.Command),
    map_event: fn(event.Event) -> msg,
  )
}

pub fn start(app: LeafJuice(model, msg)) -> Nil {
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
  let queue = stdout.Queue([command.Clear(terminal.All)])
  stdout.queue(queue, app.view(model))
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
