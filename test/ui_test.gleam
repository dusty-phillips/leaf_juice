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
  assert ui.draw(ui.Text("Hello", style.default_style()), #(20, 80))
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("Hello"),

        command.ResetStyle,
      ],
      [],
    )

  assert ui.draw(ui.Text("Hello World", style.default_style()), #(8, 8))
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("Hello"),
        command.MoveTo(0, 1),
        command.Print("World"),
        command.ResetStyle,
      ],
      [],
    )

  assert ui.draw(
      ui.Text("Hello World", style.Style(style.Blue, style.BrightBlue, [])),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Blue, style.BrightBlue, [])),
        command.MoveTo(0, 0),
        command.Print("Hello"),
        command.MoveTo(0, 1),
        command.Print("World"),
        command.ResetStyle,
      ],
      [],
    )
}

pub fn draw_scrollable_text_test() {
  assert ui.draw(
      ui.ScrollableText("Foobar FizzBuzz Hello World", 2, style.default_style()),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
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
        command.ResetStyle,
      ],
      [],
    )

  assert ui.draw(
      ui.ScrollableText("Foobar FizzBuzz Hello World", 2, style.default_style()),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
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
        command.ResetStyle,
      ],
      [],
    )
}

pub fn draw_button_test() {
  let handler = fn() { Nil }
  assert ui.draw(
      ui.Button("Hello", style.Style(style.Black, style.Green, []), handler),
      #(10, 10),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.Green, [])),
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
        command.ResetStyle,
      ],
      [ui.MouseClickCallback(0, 0, 10, 10, handler)],
    )

  assert ui.draw(
      ui.Button("Hello", style.Style(style.Black, style.Green, []), handler),
      #(11, 11),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.Green, [])),
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
        command.ResetStyle,
      ],
      [ui.MouseClickCallback(0, 0, 11, 11, handler)],
    )

  assert ui.draw(
      ui.Button(
        "Hello World",
        style.Style(style.Black, style.Green, []),
        handler,
      ),
      #(10, 10),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.Green, [])),
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
        command.ResetStyle,
      ],
      [ui.MouseClickCallback(0, 0, 10, 10, handler)],
    )
}

pub fn draw_text_input_test() {
  let handler = fn() { Nil }

  assert ui.draw(
      ui.TextInput(
        ui.TextInputModel("", 0),
        style.Style(style.Black, style.Blue, []),
        False,
        handler,
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.Blue, [])),
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
        command.ResetStyle,
      ],
      [ui.MouseClickCallback(0, 0, 8, 8, handler)],
    )

  assert ui.draw(
      ui.TextInput(
        ui.TextInputModel("", 0),
        style.Style(style.Black, style.BrightBlue, []),
        True,
        handler,
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.BrightBlue, [])),
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
        command.ResetStyle,
        command.MoveTo(1, 2),
        command.ShowCursor,
      ],
      [ui.MouseClickCallback(0, 0, 8, 8, handler)],
    )

  assert ui.draw(
      ui.TextInput(
        ui.TextInputModel("hello", 3),
        style.Style(style.Black, style.BrightBlue, []),
        True,
        handler,
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.MoveTo(0, 0),
        command.SetStyle(style.Style(style.Black, style.BrightBlue, [])),
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
        command.ResetStyle,
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

  assert ui.draw(ui.OutlinedBox(ui.Text("Hello", style.default_style())), #(
      8,
      8,
    ))
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
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(1, 1),
        command.Print("Hello"),
        command.ResetStyle,
      ],
      [],
    )
  // TODO: edge case where the context is too small.
}

pub fn draw_vertical_stack_test() {
  assert ui.draw(
      ui.VerticalStack([
        ui.Text("1\n2", style.default_style()),
        ui.Text("3\n4", style.default_style()),
      ]),
      #(4, 4),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("1"),
        command.MoveTo(0, 1),
        command.Print("2"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 2),
        command.Print("3"),
        command.MoveTo(0, 3),
        command.Print("4"),
        command.ResetStyle,
      ],
      [],
    )
}

pub fn draw_scrollable_test() {
  assert ui.draw(
      ui.Scrollable(
        [
          ui.Text("1\n2", style.default_style()),
          ui.Text("3\n4", style.default_style()),
          ui.Text("5\n6", style.default_style()),
          ui.Text("7\n8", style.default_style()),
        ],
        2,
      ),
      #(4, 4),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("3"),
        command.MoveTo(0, 1),
        command.Print("4"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 2),
        command.Print("5"),
        command.MoveTo(0, 3),
        command.Print("6"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(3, 3),
        command.Print("|"),
        command.MoveTo(3, 2),
        command.Print("|"),
        command.MoveTo(3, 1),
        command.Print("|"),
        command.MoveTo(3, 0),
        command.Print("|"),
        command.MoveTo(3, 1),
        command.Print("▓"),
      ],
      [],
    )
}

pub fn draw_horizontal_split_test() {
  assert ui.draw(
      ui.HorizontalSplit(
        ui.Text("One", style.default_style()),
        ui.Text("Two", style.default_style()),
        ui.Percent(50),
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("One"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 4),
        command.Print("Two"),
        command.ResetStyle,
      ],
      [],
    )

  assert ui.draw(
      ui.HorizontalSplit(
        ui.Text("1", style.default_style()),
        ui.Text("2", style.default_style()),
        ui.Cells(2),
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("1"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 2),
        command.Print("2"),
        command.ResetStyle,
      ],
      [],
    )
}

pub fn draw_vertical_split_test() {
  assert ui.draw(
      ui.VerticalSplit(
        ui.Text("One", style.default_style()),
        ui.Text("Two", style.default_style()),
        ui.Percent(50),
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("One"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(4, 0),
        command.Print("Two"),
        command.ResetStyle,
      ],
      [],
    )

  assert ui.draw(
      ui.VerticalSplit(
        ui.Text("1", style.default_style()),
        ui.Text("2", style.default_style()),
        ui.Cells(2),
      ),
      #(8, 8),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("1"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(2, 0),
        command.Print("2"),
        command.ResetStyle,
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
          ui.GridCell(ui.Text("1", style.default_style()), #(0, 0), #(0, 2)),
          ui.GridCell(ui.Text("2", style.default_style()), #(1, 1), #(0, 1)),
          ui.GridCell(ui.Text("3", style.default_style()), #(1, 1), #(2, 2)),
        ],
      ),
      #(10, 10),
    )
    == #(
      [
        command.HideCursor,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(10, 2),
        command.Print("3"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 2),
        command.Print("2"),
        command.ResetStyle,
        command.SetStyle(style.Style(style.Default, style.Default, [])),
        command.MoveTo(0, 0),
        command.Print("1"),
        command.ResetStyle,
      ],
      [],
    )
  // TODO: There are a lot of edge cases in a grid
}
