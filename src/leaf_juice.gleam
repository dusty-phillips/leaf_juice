import etch/command
import etch/event
import etch/stdout
import etch/terminal
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor

pub type LeafJuice(model, msg) {
  LeafJuice(
    init: fn() -> #(model, List(fn() -> msg)),
    update: fn(model, msg) -> #(model, List(fn() -> msg)),
    view: fn(model) -> List(command.Command),
    map_event: fn(event.Event) -> msg,
  )
}

type AppState(model, msg) {
  AppState(
    app: LeafJuice(model, msg),
    model: model,
    actor: process.Subject(ActorMessage(msg)),
  )
}

type ActorMessage(msg) {
  Event(event.Event)
  AppMsg(msg)
}

pub fn start(
  app: LeafJuice(model, msg),
) -> Result(actor.Started(Nil), actor.StartError) {
  let start_result =
    actor.new_with_initialiser(1000, fn(actor_subject) {
      let #(model, effects) = app.init()

      stdout.execute([
        command.EnterRaw,
        command.EnterAlternateScreen,
        command.Clear(terminal.All),
        command.MoveTo(0, 0),
        command.EnableMouseCapture,
      ])

      event.init_event_server()

      let app_state = AppState(app, model, actor_subject)

      draw(app_state)

      run_effects(actor_subject, effects)

      process.spawn(fn() { handle_input(actor_subject) })

      Ok(actor.initialised(app_state))
    })
    |> actor.on_message(on_message)
    |> actor.start
}

fn on_message(app_state: AppState(model, msg), message: ActorMessage(msg)) {
  let app_message = case message {
    Event(event) -> app_state.app.map_event(event)
    AppMsg(msg) -> msg
  }

  let #(next_model, next_effects) =
    app_state.app.update(app_state.model, app_message)

  let next_state = AppState(..app_state, model: next_model)

  draw(next_state)
  run_effects(app_state.actor, next_effects)

  actor.continue(next_state)
}

fn run_effects(
  actor_subject: process.Subject(ActorMessage(msg)),
  effects: List(fn() -> msg),
) {
  use callback <- list.each(effects)

  process.spawn(fn() {
    let msg = callback()
    process.send(actor_subject, AppMsg(msg))
  })
}

fn handle_input(actor_subject: process.Subject(ActorMessage(msg))) -> Nil {
  case event.read() {
    option.Some(Ok(event)) -> process.send(actor_subject, Event(event))
    option.Some(Error(_)) | option.None ->
      todo as "Not sure what can get us into this state so don't know how to handle it"
  }

  handle_input(actor_subject)
}

fn draw(app_state: AppState(model, msg)) -> Nil {
  stdout.Queue([command.Clear(terminal.All)])
  |> stdout.queue(app_state.app.view(app_state.model))
  |> stdout.flush()

  Nil
}
