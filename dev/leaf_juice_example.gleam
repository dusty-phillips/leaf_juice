import etch/event
import etch/style
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
  Model(
    last_key: String,
    last_button: String,
    input_text: ui.TextInputModel,
    scrollable_text: #(String, Int),
    scrollable_position: Int,
    width: Int,
    height: Int,
    focused: Focus,
  )
}

type Focus {
  FocusNone
  FocusOne
  FocusInput
  FocusScrollable
  FocusScrollableText
  FocusLastKey
}

fn next_focus(focus: Focus) -> Focus {
  case focus {
    FocusNone -> FocusOne
    FocusOne -> FocusInput
    FocusInput -> FocusScrollable
    FocusScrollable -> FocusScrollableText
    FocusScrollableText -> FocusLastKey
    FocusLastKey -> FocusOne
  }
}

fn prev_focus(focus: Focus) -> Focus {
  case focus {
    FocusNone -> FocusLastKey
    FocusOne -> FocusLastKey
    FocusInput -> FocusOne
    FocusScrollable -> FocusInput
    FocusScrollableText -> FocusScrollable
    FocusLastKey -> FocusScrollableText
  }
}

fn confirm_focused(model: Model) -> #(Model, List(leaf_juice.Effect(Msg))) {
  case model.focused {
    FocusNone | FocusInput | FocusScrollable | FocusScrollableText -> #(
      model,
      [],
    )

    FocusOne -> #(model, [leaf_juice.Effect(fn() { UserInvokedOne })])
    FocusLastKey -> #(model, [leaf_juice.Effect(fn() { UserInvokedLastKey })])
  }
}

type Msg {
  RuntimeEmittedEvent(event.Event)
  UserClickedInput
  UserInvokedOne
  UserInvokedLastKey
}

fn init() -> #(Model, List(leaf_juice.Effect(Msg))) {
  let assert Ok(#(width, height)) = terminal.window_size()
  #(
    Model(
      last_key: "None",
      last_button: "None",
      input_text: ui.TextInputModel("", cursor_position: 0),
      scrollable_text: #(
        " is the number of columns and rows in this the world of text that we are testing out the wrapping on right now just to see if it works or not or whatever, if it wraps. And also testing the total number of lines get truncated to fit in the context space, just truncation sorry, not gonna add anything else until I need it but I do want multi-line text, y'know.
              I guess I also want multi-line components, but that's a separate concern for later for now I just want lots of text right here for me to test with.",
        2,
      ),
      scrollable_position: 0,
      width:,
      height:,
      focused: FocusNone,
    ),
    [],
  )
}

fn update(model: Model, msg: Msg) -> #(Model, List(leaf_juice.Effect(Msg))) {
  case msg {
    RuntimeEmittedEvent(event.Key(event.KeyEvent(
      code: event.Tab,
      kind: event.Release,
      modifiers: event.Modifiers(shift: False, ..),
      ..,
    ))) -> #(Model(..model, focused: next_focus(model.focused)), [])

    RuntimeEmittedEvent(event.Key(event.KeyEvent(
      code: event.Backtab,
      kind: event.Release,
      modifiers: event.Modifiers(shift: True, ..),
      ..,
    ))) -> #(Model(..model, focused: prev_focus(model.focused)), [])

    // Escape clears focus
    RuntimeEmittedEvent(event.Key(event.KeyEvent(
      code: event.Esc,
      kind: event.Release,
      ..,
    ))) -> #(Model(..model, focused: FocusNone), [])

    // Enter invokes action
    RuntimeEmittedEvent(event.Key(event.KeyEvent(
      code: event.Enter,
      kind: event.Release,
      ..,
    ))) -> confirm_focused(model)

    RuntimeEmittedEvent(event.Key(
      event.KeyEvent(code: event.Char("q"), kind: event.Release, ..) as key_event,
    )) -> {
      case model.focused {
        FocusInput -> #(
          Model(
            ..model,
            input_text: ui.update_text_input(model.input_text, key_event),
          ),
          [],
        )
        _ -> #(model, [
          leaf_juice.Exit,
        ])
      }
    }

    RuntimeEmittedEvent(event.Key(key_event) as event) ->
      case model.focused {
        FocusInput -> #(
          Model(
            ..model,
            input_text: ui.update_text_input(model.input_text, key_event),
          ),
          [],
        )

        FocusScrollableText -> #(
          Model(..model, scrollable_text: #(
            model.scrollable_text.0,
            ui.update_scrollable(model.scrollable_text.1, event),
          )),
          [],
        )

        FocusScrollable -> #(
          Model(
            ..model,
            scrollable_position: ui.update_scrollable(
              model.scrollable_position,
              event,
            ),
          ),
          [],
        )

        _ -> #(Model(..model, last_key: event.to_string(key_event.code)), [])
      }

    RuntimeEmittedEvent(event.Resize(width, height)) -> #(
      Model(..model, width:, height:),
      [],
    )

    RuntimeEmittedEvent(event.Mouse(..) as event) -> {
      case model.focused {
        FocusScrollableText -> #(
          Model(..model, scrollable_text: #(
            model.scrollable_text.0,
            ui.update_scrollable(model.scrollable_text.1, event),
          )),
          [],
        )

        FocusScrollable -> #(
          Model(
            ..model,
            scrollable_position: ui.update_scrollable(
              model.scrollable_position,
              event,
            ),
          ),
          [],
        )

        _ -> #(model, [])
      }
    }

    RuntimeEmittedEvent(event.FocusGained(..))
    | RuntimeEmittedEvent(event.FocusLost(..)) -> #(model, [])

    UserInvokedOne -> #(Model(..model, last_button: "One"), [])
    UserInvokedLastKey -> #(Model(..model, last_button: "LastKey"), [])
    UserClickedInput -> #(Model(..model, focused: FocusInput), [])
  }
}

fn view(model: Model) -> ui.Node(Msg) {
  ui.OutlinedBox(
    ui.Grid([ui.Cells(6), ui.Cells(7), ui.Fill], [ui.Cells(20), ui.Fill], [
      ui.GridCell(
        ui.OutlinedBox(
          ui.Button(
            int.to_string(model.width) <> ", " <> int.to_string(model.height),
            style: button_style(model.focused, FocusOne),
            on_click: fn() { UserInvokedOne },
          ),
        ),
        rows: #(0, 0),
        columns: #(0, 0),
      ),
      ui.GridCell(
        ui.TextInput(
          model.input_text,
          text_input_style(model.focused, FocusInput),
          is_focused: model.focused == FocusInput,
          on_click: fn() { UserClickedInput },
        ),
        rows: #(1, 1),
        columns: #(0, 0),
      ),
      ui.GridCell(
        ui.Scrollable(
          [
            ui.Text("1\n2", focused_style(model.focused, FocusScrollable)),
            ui.Text("3\n4", focused_style(model.focused, FocusScrollable)),
            ui.OutlinedBox(ui.Text(
              "5\n6\n7",
              focused_style(model.focused, FocusScrollable),
            )),
            ui.Text(
              "eight nine ten eleven",
              focused_style(model.focused, FocusScrollable),
            ),
            ui.Text("12\n13\n14", focused_style(model.focused, FocusScrollable)),
            ui.Text("15\n16\n17", focused_style(model.focused, FocusScrollable)),
          ],
          model.scrollable_position,
        ),
        rows: #(2, 2),
        columns: #(0, 0),
      ),
      ui.GridCell(
        ui.OutlinedBox(ui.ScrollableText(
          model.scrollable_text.0,
          model.scrollable_text.1,
          focused_style(model.focused, FocusScrollableText),
        )),
        rows: #(0, 0),
        columns: #(1, 1),
      ),
      ui.GridCell(
        ui.OutlinedBox(ui.Text(model.last_button, style.default_style())),
        rows: #(1, 1),
        columns: #(1, 1),
      ),
      ui.GridCell(
        ui.Button(
          model.last_key,
          style: button_style(model.focused, FocusLastKey),
          on_click: fn() { UserInvokedLastKey },
        ),
        rows: #(2, 2),
        columns: #(1, 1),
      ),
    ]),
  )
}

fn focused_style(focused: Focus, target: Focus) -> style.Style {
  case focused == target {
    True -> style.Style(style.Default, style.White, [])
    False -> style.default_style()
  }
}

fn button_style(focused: Focus, target: Focus) -> style.Style {
  case focused == target {
    True -> style.Style(style.BrightGreen, style.Black, [])
    False -> style.Style(style.Green, style.Black, [])
  }
}

fn text_input_style(focused: Focus, target: Focus) -> style.Style {
  case focused == target {
    True -> style.Style(style.Default, style.BrightBlue, [])
    False -> style.Style(style.Default, style.Blue, [])
  }
}
