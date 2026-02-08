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
    init: fn() -> #(model, List(Effect(msg))),
    update: fn(model, msg) -> #(model, List(Effect(msg))),
    view: fn(model) -> List(command.Command),
    map_event: fn(event.Event) -> msg,
    exit: process.Subject(Nil),
  )
}

pub type Effect(msg) {
  Effect(fn() -> msg)
  Exit
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
  Shutdown
}

pub fn start(
  app: LeafJuice(model, msg),
) -> Result(actor.Started(Nil), actor.StartError) {
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
  case message {
    Event(event) -> {
      event
      |> app_state.app.map_event
      |> do_update(app_state, _)
      |> actor.continue
    }
    AppMsg(msg) -> app_state |> do_update(msg) |> actor.continue
    Shutdown -> {
      process.send(app_state.app.exit, Nil)
      actor.stop()
    }
  }
}

fn run_effects(
  actor_subject: process.Subject(ActorMessage(msg)),
  effects: List(Effect(msg)),
) -> Nil {
  use effect <- list.each(effects)

  case effect {
    Effect(callback) -> {
      process.spawn(fn() {
        let msg = callback()
        process.send(actor_subject, AppMsg(msg))
      })
      Nil
    }

    Exit -> {
      restore_term()
      process.send(actor_subject, Shutdown)
    }
  }
}

fn handle_input(actor_subject: process.Subject(ActorMessage(msg))) -> Nil {
  case event.read() {
    option.Some(Ok(event)) -> process.send(actor_subject, Event(event))
    option.Some(Error(_)) | option.None ->
      todo as "Not sure what can get us into this state so don't know how to handle it"
  }

  handle_input(actor_subject)
}

fn do_update(app_state: AppState(model, msg), msg: msg) -> AppState(model, msg) {
  let #(next_model, next_effects) = app_state.app.update(app_state.model, msg)

  let next_state = AppState(..app_state, model: next_model)

  draw(next_state)
  run_effects(app_state.actor, next_effects)

  next_state
}

fn draw(app_state: AppState(model, msg)) -> Nil {
  stdout.Queue([command.Clear(terminal.All)])
  |> stdout.queue(app_state.app.view(app_state.model))
  |> stdout.flush()

  Nil
}

fn restore_term() -> Nil {
  stdout.execute([
    command.DisableMouseCapture,
    command.LeaveAlternateScreen,
  ])
}
