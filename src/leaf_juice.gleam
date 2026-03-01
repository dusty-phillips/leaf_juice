import etch/command
import etch/event
import etch/stdout
import etch/terminal
import gleam/erlang/process
import gleam/function
import gleam/list
import gleam/option
import gleam/otp/actor
import leaf_juice/ui

pub type LeafJuice(model, msg) {
  LeafJuice(
    init: fn() -> #(model, List(Effect(msg))),
    update: fn(model, msg) -> #(model, List(Effect(msg))),
    view: fn(model) -> ui.Node(msg),
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
    mouse_callbacks: List(ui.MouseCallback(msg)),
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

    terminal.enter_raw()

    stdout.execute([
      command.EnterAlternateScreen,
      command.Clear(terminal.All),
      command.HideCursor,
      command.MoveTo(0, 0),
      command.PushKeyboardEnhancementFlags([
        event.DisambiguateEscapeCode,
        event.ReportEventTypes,
        event.ReportAlternateKeys,
        event.ReportAllKeysAsEscapeCode,
        event.ReportAssociatedText,
      ]),
      command.EnableMouseCapture,
    ])

    event.init_event_server()

    let app_state = AppState(app, model, actor_subject, mouse_callbacks: [])

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
      case event {
        event.Mouse(
          event.MouseEvent(kind: event.Up(event.Left), ..) as mouse_event,
        ) -> on_mouse_up(app_state, mouse_event)
        _ -> Nil
      }

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

fn on_mouse_up(app_state: AppState(model, msg), event: event.MouseEvent) -> Nil {
  let event.MouseEvent(row:, column:, ..) = event

  let match =
    list.find(app_state.mouse_callbacks, fn(callback) {
      let ui.MouseClickCallback(left:, top:, width:, height:, ..) = callback

      list.all(
        [
          row >= top,
          row < top + height,
          column >= left,
          column < left + width,
        ],
        function.identity,
      )
    })

  case match {
    Ok(callback) -> process.send(app_state.actor, AppMsg(callback.callback()))
    Error(Nil) -> Nil
  }
}

fn do_update(app_state: AppState(model, msg), msg: msg) -> AppState(model, msg) {
  let #(next_model, next_effects) = app_state.app.update(app_state.model, msg)

  let next_state = AppState(..app_state, model: next_model, mouse_callbacks: [])

  let next_state = draw(next_state)
  run_effects(app_state.actor, next_effects)

  next_state
}

fn draw(app_state: AppState(model, msg)) -> AppState(model, msg) {
  let assert Ok(window_size) = terminal.window_size()
  let #(commands, mouse_callbacks) =
    ui.draw(app_state.app.view(app_state.model), window_size)

  stdout.Queue([command.Clear(terminal.All)])
  |> stdout.queue(commands)
  |> stdout.flush()

  AppState(..app_state, mouse_callbacks:)
}

fn restore_term() -> Nil {
  stdout.execute([
    command.DisableMouseCapture,
    command.LeaveAlternateScreen,
    command.ShowCursor,
  ])
}
