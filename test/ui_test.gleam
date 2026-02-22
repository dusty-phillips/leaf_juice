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

  assert ui.draw(ui.Text("Hello World"), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("Hello"),
        command.MoveTo(0, 1),
        command.Print("World"),
      ],
      [],
    )
}

pub fn draw_scrollable_text_test() {
  assert ui.draw(ui.ScrollableText("Foobar FizzBuzz Hello World", 2, False), #(
      8,
      8,
    ))
    == #(
      [
        command.HideCursor,
        command.SetForegroundColor(style.Grey),
        command.MoveTo(0, 0),
        command.Print("Hello"),
        command.MoveTo(0, 1),
        command.Print("World"),
        command.MoveTo(7, 7),
        command.Print("|"),
        command.MoveTo(7, 6),
        command.Print("|"),
        command.MoveTo(7, 5),
        command.Print("|"),
        command.MoveTo(7, 4),
        command.Print("|"),
        command.MoveTo(7, 3),
        command.Print("|"),
        command.MoveTo(7, 2),
        command.Print("|"),
        command.MoveTo(7, 1),
        command.Print("|"),
        command.MoveTo(7, 0),
        command.Print("|"),
        command.MoveTo(7, 4),
        command.Print("▓"),
        command.ResetColor,
      ],
      [],
    )

  assert ui.draw(ui.ScrollableText("Foobar FizzBuzz Hello World", 2, True), #(
      8,
      8,
    ))
    == #(
      [
        command.HideCursor,
        command.SetForegroundColor(style.White),
        command.MoveTo(0, 0),
        command.Print("Hello"),
        command.MoveTo(0, 1),
        command.Print("World"),
        command.MoveTo(7, 7),
        command.Print("|"),
        command.MoveTo(7, 6),
        command.Print("|"),
        command.MoveTo(7, 5),
        command.Print("|"),
        command.MoveTo(7, 4),
        command.Print("|"),
        command.MoveTo(7, 3),
        command.Print("|"),
        command.MoveTo(7, 2),
        command.Print("|"),
        command.MoveTo(7, 1),
        command.Print("|"),
        command.MoveTo(7, 0),
        command.Print("|"),
        command.MoveTo(7, 4),
        command.Print("▓"),
        command.ResetColor,
      ],
      [],
    )
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

pub fn draw_text_input_test() {
  let handler = fn() { Nil }

  assert ui.draw(ui.TextInput(ui.TextInputModel("", 0), False, handler), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundColor(style.Blue),
        command.Print("┌"),
        command.Print("──────"),
        command.Print("┐"),
        command.MoveTo(0, 7),
        command.Print("└"),
        command.Print("──────"),
        command.Print("┘"),
        command.MoveTo(0, 1),
        command.Print("│"),
        command.MoveTo(7, 1),
        command.Print("│"),
        command.MoveTo(0, 2),
        command.Print("│"),
        command.MoveTo(7, 2),
        command.Print("│"),
        command.MoveTo(0, 3),
        command.Print("│"),
        command.MoveTo(7, 3),
        command.Print("│"),
        command.MoveTo(0, 4),
        command.Print("│"),
        command.MoveTo(7, 4),
        command.Print("│"),
        command.MoveTo(0, 5),
        command.Print("│"),
        command.MoveTo(7, 5),
        command.Print("│"),
        command.MoveTo(0, 6),
        command.Print("│"),
        command.MoveTo(7, 6),
        command.Print("│"),
        command.MoveTo(1, 2),
        command.Print(""),
        command.ResetColor,
      ],
      [ui.MouseClickCallback(0, 0, 8, 8, handler)],
    )

  assert ui.draw(ui.TextInput(ui.TextInputModel("", 0), True, handler), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundColor(style.BrightBlue),
        command.Print("┌"),
        command.Print("──────"),
        command.Print("┐"),
        command.MoveTo(0, 7),
        command.Print("└"),
        command.Print("──────"),
        command.Print("┘"),
        command.MoveTo(0, 1),
        command.Print("│"),
        command.MoveTo(7, 1),
        command.Print("│"),
        command.MoveTo(0, 2),
        command.Print("│"),
        command.MoveTo(7, 2),
        command.Print("│"),
        command.MoveTo(0, 3),
        command.Print("│"),
        command.MoveTo(7, 3),
        command.Print("│"),
        command.MoveTo(0, 4),
        command.Print("│"),
        command.MoveTo(7, 4),
        command.Print("│"),
        command.MoveTo(0, 5),
        command.Print("│"),
        command.MoveTo(7, 5),
        command.Print("│"),
        command.MoveTo(0, 6),
        command.Print("│"),
        command.MoveTo(7, 6),
        command.Print("│"),
        command.MoveTo(1, 2),
        command.Print(""),
        command.ResetColor,
        command.MoveTo(1, 2),
        command.ShowCursor,
      ],
      [ui.MouseClickCallback(0, 0, 8, 8, handler)],
    )

  assert ui.draw(ui.TextInput(ui.TextInputModel("hello", 3), True, handler), #(
      8,
      8,
    ))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetForegroundColor(style.BrightBlue),
        command.Print("┌"),
        command.Print("──────"),
        command.Print("┐"),
        command.MoveTo(0, 7),
        command.Print("└"),
        command.Print("──────"),
        command.Print("┘"),
        command.MoveTo(0, 1),
        command.Print("│"),
        command.MoveTo(7, 1),
        command.Print("│"),
        command.MoveTo(0, 2),
        command.Print("│"),
        command.MoveTo(7, 2),
        command.Print("│"),
        command.MoveTo(0, 3),
        command.Print("│"),
        command.MoveTo(7, 3),
        command.Print("│"),
        command.MoveTo(0, 4),
        command.Print("│"),
        command.MoveTo(7, 4),
        command.Print("│"),
        command.MoveTo(0, 5),
        command.Print("│"),
        command.MoveTo(7, 5),
        command.Print("│"),
        command.MoveTo(0, 6),
        command.Print("│"),
        command.MoveTo(7, 6),
        command.Print("│"),
        command.MoveTo(1, 2),
        command.Print("hello"),
        command.ResetColor,
        command.MoveTo(4, 2),
        command.ShowCursor,
      ],
      [ui.MouseClickCallback(0, 0, 8, 8, handler)],
    )
  // TODO: edge case where text doesn't fit horizonally. it needs to scroll so the cursor is visible
  // TODO: edge case where the context is too small.
}

pub fn draw_outline_box_test() {
  assert ui.draw(ui.OutlinedBox(ui.Empty), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("╭"),
        command.Print("──────"),
        command.Print("╮"),
        command.MoveTo(0, 7),
        command.Print("╰"),
        command.Print("──────"),
        command.Print("╯"),
        command.MoveTo(0, 1),
        command.Print("│"),
        command.MoveTo(7, 1),
        command.Print("│"),
        command.MoveTo(0, 2),
        command.Print("│"),
        command.MoveTo(7, 2),
        command.Print("│"),
        command.MoveTo(0, 3),
        command.Print("│"),
        command.MoveTo(7, 3),
        command.Print("│"),
        command.MoveTo(0, 4),
        command.Print("│"),
        command.MoveTo(7, 4),
        command.Print("│"),
        command.MoveTo(0, 5),
        command.Print("│"),
        command.MoveTo(7, 5),
        command.Print("│"),
        command.MoveTo(0, 6),
        command.Print("│"),
        command.MoveTo(7, 6),
        command.Print("│"),
      ],
      [],
    )

  assert ui.draw(ui.OutlinedBox(ui.Text("Hello")), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("╭"),
        command.Print("──────"),
        command.Print("╮"),
        command.MoveTo(0, 7),
        command.Print("╰"),
        command.Print("──────"),
        command.Print("╯"),
        command.MoveTo(0, 1),
        command.Print("│"),
        command.MoveTo(7, 1),
        command.Print("│"),
        command.MoveTo(0, 2),
        command.Print("│"),
        command.MoveTo(7, 2),
        command.Print("│"),
        command.MoveTo(0, 3),
        command.Print("│"),
        command.MoveTo(7, 3),
        command.Print("│"),
        command.MoveTo(0, 4),
        command.Print("│"),
        command.MoveTo(7, 4),
        command.Print("│"),
        command.MoveTo(0, 5),
        command.Print("│"),
        command.MoveTo(7, 5),
        command.Print("│"),
        command.MoveTo(0, 6),
        command.Print("│"),
        command.MoveTo(7, 6),
        command.Print("│"),
        command.MoveTo(1, 1),
        command.Print("Hello"),
      ],
      [],
    )
  // TODO: edge case where the context is too small.
}

pub fn draw_vertical_stack_test() {
  assert ui.draw(ui.VerticalStack([ui.Text("1\n2"), ui.Text("3\n4")]), #(4, 4))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("1"),
        command.MoveTo(0, 1),
        command.Print("2"),
        command.MoveTo(0, 2),
        command.Print("3"),
        command.MoveTo(0, 3),
        command.Print("4"),
      ],
      [],
    )
}

pub fn draw_scrollable_test() {
  assert ui.draw(
      ui.Scrollable(
        [ui.Text("1\n2"), ui.Text("3\n4"), ui.Text("5\n6"), ui.Text("7\n8")],
        2,
      ),
      #(4, 4),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("3"),
        command.MoveTo(0, 1),
        command.Print("4"),
        command.MoveTo(0, 2),
        command.Print("5"),
        command.MoveTo(0, 3),
        command.Print("6"),
      ],
      [],
    )
}

pub fn draw_horizontal_split_test() {
  assert ui.draw(
      ui.HorizontalSplit(ui.Text("One"), ui.Text("Two"), ui.Percent(50)),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("One"),
        command.MoveTo(0, 4),
        command.Print("Two"),
      ],
      [],
    )

  assert ui.draw(ui.HorizontalSplit(ui.Text("1"), ui.Text("2"), ui.Cells(2)), #(
      8,
      8,
    ))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("1"),
        command.MoveTo(0, 2),
        command.Print("2"),
      ],
      [],
    )
}

pub fn draw_vertical_split_test() {
  assert ui.draw(
      ui.VerticalSplit(ui.Text("One"), ui.Text("Two"), ui.Percent(50)),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("One"),
        command.MoveTo(4, 0),
        command.Print("Two"),
      ],
      [],
    )

  assert ui.draw(ui.VerticalSplit(ui.Text("1"), ui.Text("2"), ui.Cells(2)), #(
      8,
      8,
    ))
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.Print("1"),
        command.MoveTo(2, 0),
        command.Print("2"),
      ],
      [],
    )
}

pub fn draw_grid_test() {
  assert ui.draw(
      ui.Grid(
        [ui.Percent(20), ui.Fill, ui.Percent(10)],
        [ui.Cells(2), ui.Fill],
        [
          ui.GridCell(ui.Text("1"), #(0, 0), #(0, 2)),
          ui.GridCell(ui.Text("2"), #(1, 1), #(0, 1)),
          ui.GridCell(ui.Text("3"), #(1, 1), #(2, 2)),
        ],
      ),
      #(10, 10),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(10, 2),
        command.Print("3"),
        command.MoveTo(0, 2),
        command.Print("2"),
        command.MoveTo(0, 0),
        command.Print("1"),
      ],
      [],
    )
  // TODO: There are a lot of edge cases in a grid
}
