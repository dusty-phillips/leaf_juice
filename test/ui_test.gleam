import etch/command
import etch/event
import etch/style
import leaf_juice/ui

fn make_key_event(code: event.KeyCode) -> event.KeyEvent {
  event.KeyEvent(
    code:,
    kind: event.Release,
    modifiers: event.Modifiers(False, False, False, False, False, False),
    text: "",
    state: event.KeyEventState(False, False, False),
  )
}

pub fn update_text_input_left_test() {
  assert ui.update_text_input(
      ui.TextInputModel("", 0),
      make_key_event(event.LeftArrow),
    )
    == ui.TextInputModel("", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 0),
      make_key_event(event.LeftArrow),
    )
    == ui.TextInputModel("abc", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 2),
      make_key_event(event.LeftArrow),
    )
    == ui.TextInputModel("abc", 1)
}

pub fn update_text_input_right_test() {
  assert ui.update_text_input(
      ui.TextInputModel("", 0),
      make_key_event(event.RightArrow),
    )
    == ui.TextInputModel("", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 3),
      make_key_event(event.RightArrow),
    )
    == ui.TextInputModel("abc", 3)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 1),
      make_key_event(event.RightArrow),
    )
    == ui.TextInputModel("abc", 2)
}

pub fn update_text_input_delete_test() {
  assert ui.update_text_input(
      ui.TextInputModel("", 0),
      make_key_event(event.Delete),
    )
    == ui.TextInputModel("", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 0),
      make_key_event(event.Delete),
    )
    == ui.TextInputModel("bc", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 1),
      make_key_event(event.Delete),
    )
    == ui.TextInputModel("ac", 1)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 2),
      make_key_event(event.Delete),
    )
    == ui.TextInputModel("ab", 2)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 3),
      make_key_event(event.Delete),
    )
    == ui.TextInputModel("abc", 3)
}

pub fn update_text_input_backspace_test() {
  assert ui.update_text_input(
      ui.TextInputModel("", 0),
      make_key_event(event.Char("\u{007F}")),
    )
    == ui.TextInputModel("", 0)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 3),
      make_key_event(event.Char("\u{007F}")),
    )
    == ui.TextInputModel("ab", 2)

  assert ui.update_text_input(
      ui.TextInputModel("abc", 1),
      make_key_event(event.Char("\u{007F}")),
    )
    == ui.TextInputModel("bc", 0)
}

pub fn draw_empty_test() {
  assert ui.draw(ui.Empty, #(20, 80)) == #([command.HideCursor], [])
}

pub fn draw_text_test() {
  assert ui.draw(ui.Text("Hello"), #(20, 80))
    == #([command.HideCursor, command.MoveTo(0, 0), command.Print("Hello")], [])
}

pub fn draw_button_test() {
  let handler = fn() { Nil }
  assert ui.draw(ui.Button("Hello", False, handler), #(10, 10))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundAndBackgroundColors(style.Black, style.Green),
        command.MoveTo(0, 0),
        command.Print("          "),
        command.MoveTo(0, 1),
        command.Print("          "),
        command.MoveTo(0, 2),
        command.Print("          "),
        command.MoveTo(0, 3),
        command.Print("          "),
        command.MoveTo(0, 4),
        command.Print("          "),
        command.MoveTo(0, 5),
        command.Print("  "),
        command.Print("Hello"),
        command.Print("   "),
        command.MoveTo(0, 6),
        command.Print("          "),
        command.MoveTo(0, 7),
        command.Print("          "),
        command.MoveTo(0, 8),
        command.Print("          "),
        command.MoveTo(0, 9),
        command.Print("          "),
        command.ResetColor,
      ],
      [ui.MouseClickCallback(0, 0, 10, 10, handler)],
    )

  assert ui.draw(ui.Button("Hello", False, handler), #(11, 11))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundAndBackgroundColors(style.Black, style.Green),
        command.MoveTo(0, 0),
        command.Print("           "),
        command.MoveTo(0, 1),
        command.Print("           "),
        command.MoveTo(0, 2),
        command.Print("           "),
        command.MoveTo(0, 3),
        command.Print("           "),
        command.MoveTo(0, 4),
        command.Print("           "),
        command.MoveTo(0, 5),
        command.Print("           "),
        command.MoveTo(0, 6),
        command.Print("   "),
        command.Print("Hello"),
        command.Print("   "),
        command.MoveTo(0, 7),
        command.Print("           "),
        command.MoveTo(0, 8),
        command.Print("           "),
        command.MoveTo(0, 9),
        command.Print("           "),
        command.MoveTo(0, 10),
        command.Print("           "),
        command.ResetColor,
      ],
      [ui.MouseClickCallback(0, 0, 11, 11, handler)],
    )

  assert ui.draw(ui.Button("Hello", True, handler), #(10, 10))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundAndBackgroundColors(style.Black, style.BrightGreen),
        command.MoveTo(0, 0),
        command.Print("          "),
        command.MoveTo(0, 1),
        command.Print("          "),
        command.MoveTo(0, 2),
        command.Print("          "),
        command.MoveTo(0, 3),
        command.Print("          "),
        command.MoveTo(0, 4),
        command.Print("          "),
        command.MoveTo(0, 5),
        command.Print("  "),
        command.Print("Hello"),
        command.Print("   "),
        command.MoveTo(0, 6),
        command.Print("          "),
        command.MoveTo(0, 7),
        command.Print("          "),
        command.MoveTo(0, 8),
        command.Print("          "),
        command.MoveTo(0, 9),
        command.Print("          "),
        command.ResetColor,
      ],
      [ui.MouseClickCallback(0, 0, 10, 10, handler)],
    )

  assert ui.draw(ui.Button("Hello World", True, handler), #(10, 10))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundAndBackgroundColors(style.Black, style.BrightGreen),
        command.MoveTo(0, 0),
        command.Print("          "),
        command.MoveTo(0, 1),
        command.Print("          "),
        command.MoveTo(0, 2),
        command.Print("          "),
        command.MoveTo(0, 3),
        command.Print("          "),
        command.MoveTo(0, 4),
        command.Print("          "),
        command.MoveTo(0, 5),
        command.Print(""),
        command.Print("Hello Worl"),
        command.Print(""),
        command.MoveTo(0, 6),
        command.Print("          "),
        command.MoveTo(0, 7),
        command.Print("          "),
        command.MoveTo(0, 8),
        command.Print("          "),
        command.MoveTo(0, 9),
        command.Print("          "),
        command.ResetColor,
      ],
      [ui.MouseClickCallback(0, 0, 10, 10, handler)],
    )
}
