import etch/event
import etch/terminal
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
  echo terminal.window_size()
}
