import etch/command
import etch/event
import etch/style
import gleam/int
import gleam/list
import gleam/string
import str

pub type Size {
  Cells(Int)
  Percent(Int)
  Auto
}

pub type Node(msg) {
  Empty
  Text(String)
  ScrollableText(model: ScrollableTextModel, is_focused: Bool)

  Button(text: String, is_focused: Bool, on_click: fn() -> msg)
  TextInput(model: TextInputModel, is_focused: Bool, on_click: fn() -> msg)

  OutlinedBox(child: Node(msg))

  VerticalSplit(left: Node(msg), right: Node(msg), left_size: Size)
  HorizontalSplit(upper: Node(msg), lower: Node(msg), upper_size: Size)
  Grid(rows: List(Size), columns: List(Size), children: List(GridCell(msg)))
}

pub type ScrollableTextModel {
  ScrollableTextModel(text: String, scroll_position: Int)
}

pub type TextInputModel {
  TextInputModel(text: String, cursor_position: Int)
}

pub fn update_text_input(
  model: TextInputModel,
  key_event: event.KeyEvent,
) -> TextInputModel {
  case key_event.kind {
    event.Release ->
      case key_event.code {
        event.LeftArrow ->
          TextInputModel(
            ..model,
            cursor_position: int.max(0, model.cursor_position - 1),
          )

        event.RightArrow ->
          TextInputModel(
            ..model,
            cursor_position: int.min(
              string.length(model.text),
              model.cursor_position + 1,
            ),
          )

        event.Delete -> {
          let before = string.slice(model.text, 0, model.cursor_position)
          let after =
            string.slice(
              model.text,
              model.cursor_position + 1,
              string.length(model.text) - model.cursor_position - 1,
            )
          TextInputModel(
            text: before <> after,
            cursor_position: int.min(
              model.cursor_position,
              string.length(model.text),
            ),
          )
        }

        event.Char("\u{007F}") -> {
          // Backspace isn't handled right by etch
          let before = string.slice(model.text, 0, model.cursor_position - 1)
          let after =
            string.slice(
              model.text,
              model.cursor_position,
              string.length(model.text) - model.cursor_position,
            )
          TextInputModel(
            text: before <> after,
            cursor_position: int.max(0, model.cursor_position - 1),
          )
        }

        event.Char(char) -> {
          let before = string.slice(model.text, 0, model.cursor_position)
          let after =
            string.slice(
              model.text,
              model.cursor_position,
              string.length(model.text) - model.cursor_position,
            )
          TextInputModel(
            text: before <> char <> after,
            cursor_position: model.cursor_position + 1,
          )
        }
        _ -> model
      }
    _ -> model
  }
}

pub fn update_scrollable_text(
  model: ScrollableTextModel,
  event: event.Event,
) -> ScrollableTextModel {
  case event {
    event.Mouse(event.MouseEvent(kind: event.ScrollUp, ..), ..) ->
      ScrollableTextModel(
        ..model,
        scroll_position: int.max(0, model.scroll_position - 1),
      )

    event.Mouse(event.MouseEvent(kind: event.ScrollDown, ..), ..) ->
      ScrollableTextModel(..model, scroll_position: model.scroll_position + 1)

    event.Key(event.KeyEvent(kind: event.Release, code: event.UpArrow, ..)) ->
      ScrollableTextModel(
        ..model,
        scroll_position: int.max(0, model.scroll_position - 1),
      )

    event.Key(event.KeyEvent(kind: event.Release, code: event.DownArrow, ..)) ->
      ScrollableTextModel(..model, scroll_position: model.scroll_position + 1)

    event.Key(event.KeyEvent(kind: event.Release, code: event.PageUp, ..)) ->
      ScrollableTextModel(
        ..model,
        scroll_position: int.max(0, model.scroll_position - 10),
      )

    event.Key(event.KeyEvent(kind: event.Release, code: event.PageDown, ..)) ->
      ScrollableTextModel(..model, scroll_position: model.scroll_position + 10)

    _ -> model
  }
}

pub type GridCell(msg) {
  GridCell(node: Node(msg), rows: #(Int, Int), columns: #(Int, Int))
}

pub type MouseCallback(msg) {
  MouseClickCallback(
    left: Int,
    top: Int,
    width: Int,
    height: Int,
    callback: fn() -> msg,
  )
}

type Context {
  Context(left: Int, top: Int, width: Int, height: Int)
}

type DrawResponse(msg) {
  DrawResponse(
    commands: List(command.Command),
    callbacks: List(MouseCallback(msg)),
    // Commands to be run after drawing everything else
    // I don't like this it is a hack but it is the way I came up with
    // to move the cursor to a focused input without managing focus
    after_commands: List(command.Command),
  )
}

@internal
pub fn draw(
  node: Node(msg),
  window_size: #(Int, Int),
) -> #(List(command.Command), List(MouseCallback(msg))) {
  let #(columns, rows) = window_size

  let DrawResponse(commands, callbacks, after_commands) =
    draw_in_context(node, Context(0, 0, columns, rows))

  let commands = list.flatten([[command.HideCursor], commands, after_commands])

  #(commands, callbacks)
}

fn draw_in_context(node: Node(msg), context: Context) -> DrawResponse(msg) {
  case node {
    Empty -> DrawResponse([], [], [])

    Text(text) -> draw_text(context, text)

    ScrollableText(model, is_focused) ->
      draw_scrollable_text(context, model, is_focused)

    Button(text, is_focused, on_click) ->
      draw_button(context, text, is_focused, on_click)

    TextInput(model, is_focused, on_click) ->
      draw_text_input(context, model, is_focused, on_click)

    OutlinedBox(child) -> draw_outlined_box(context, child)

    VerticalSplit(left, right, left_size) ->
      draw_vertical_split(context, left, right, left_size)

    HorizontalSplit(upper, lower, upper_size) ->
      draw_horizontal_split(context, upper, lower, upper_size)

    Grid(rows, columns, children) -> draw_grid(context, rows, columns, children)
  }
}

fn draw_text(context: Context, text: String) -> DrawResponse(msg) {
  let lines =
    text
    |> str.wrap_at(context.width)
    |> string.split("\n")
    |> list.take(context.height)

  DrawResponse(
    lines
      |> list.index_map(fn(line, row) {
        [
          command.MoveTo(context.left, context.top + row),
          command.Print(line),
        ]
      })
      |> list.flatten,
    [],
    [],
  )
}

fn draw_scrollable_text(
  context: Context,
  model: ScrollableTextModel,
  is_focused: Bool,
) -> DrawResponse(msg) {
  let fg = case is_focused {
    False -> style.Grey
    True -> style.White
  }
  let lines =
    model.text
    |> str.wrap_at(context.width)
    |> string.split("\n")

  let displayed_lines =
    lines |> list.drop(model.scroll_position) |> list.take(context.height)

  DrawResponse(
    [
      [command.SetForegroundColor(fg)],
      displayed_lines
        |> list.index_map(fn(line, row) {
          [command.MoveTo(context.left, context.top + row), command.Print(line)]
        })
        |> list.flatten,
      [command.ResetColor],
    ]
      |> list.flatten,
    [],
    [],
  )
}

fn draw_button(
  context: Context,
  text: String,
  is_focused: Bool,
  on_click: fn() -> msg,
) -> DrawResponse(msg) {
  let rows_above = { context.height - 1 } / 2
  let columns_before = { context.width - string.length(text) } / 2
  let text = string.slice(text, 0, context.width)

  let bg = case is_focused {
    False -> style.Green
    True -> style.BrightGreen
  }

  DrawResponse(
    [
      [
        command.MoveTo(context.left, context.top),
        command.SetForegroundAndBackgroundColors(bg:, fg: style.Black),
      ],

      list.range(context.top, context.top + rows_above)
        |> list.flat_map(fn(row) {
          [
            command.MoveTo(context.left, row),
            " " |> string.repeat(context.width) |> command.Print,
          ]
        }),

      [
        command.MoveTo(context.left, context.top + rows_above + 1),
        command.Print(string.repeat(" ", columns_before)),
        command.Print(text),
        command.Print(string.repeat(
          " ",
          context.width - columns_before - string.length(text),
        )),
      ],

      list.range(context.top + rows_above + 2, context.top + context.height - 1)
        |> list.flat_map(fn(row) {
          [
            command.MoveTo(context.left, row),
            " " |> string.repeat(context.width) |> command.Print,
          ]
        }),

      [command.ResetColor],
    ]
      |> list.flatten,
    [
      MouseClickCallback(
        context.left,
        context.top,
        context.width,
        context.height,
        on_click,
      ),
    ],
    [],
  )
}

fn draw_text_input(
  context: Context,
  model: TextInputModel,
  is_focused: Bool,
  on_click: fn() -> msg,
) -> DrawResponse(msg) {
  let rows_above = { context.height - 3 } / 2
  let fg = case is_focused {
    False -> style.Blue
    True -> style.BrightBlue
  }

  DrawResponse(
    list.flatten([
      [
        command.MoveTo(context.left, context.top),
        command.SetForegroundColor(fg),
        command.Print("┌"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("┐"),
        command.MoveTo(context.left, context.top + context.height - 1),
        command.Print("└"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("┘"),
      ],

      list.range(context.top + 1, context.top + context.height - 2)
        |> list.map(fn(row) {
          [
            command.MoveTo(context.left, row),
            command.Print("│"),
            command.MoveTo(int.max(0, context.left + context.width - 1), row),
            command.Print("│"),
          ]
        })
        |> list.flatten,

      [
        command.MoveTo(context.left + 1, context.top + rows_above),
        command.Print(model.text),
        command.ResetColor,
      ],
    ]),
    [
      MouseClickCallback(
        context.left,
        context.top,
        context.width,
        context.height,
        on_click,
      ),
    ],
    // Move cursor after drawing everything else
    // assumes only one element focused, else last focus wins

    case is_focused {
      True -> [
        command.MoveTo(
          context.left + 1 + model.cursor_position,
          context.top + rows_above,
        ),
        command.ShowCursor,
      ]
      False -> []
    },
  )
}

fn draw_outlined_box(context: Context, child: Node(msg)) -> DrawResponse(msg) {
  let DrawResponse(child_commands, child_callbacks, child_after) =
    draw_in_context(
      child,
      Context(
        context.left + 1,
        context.top + 1,
        context.width - 2,
        context.height - 2,
      ),
    )

  DrawResponse(
    list.flatten([
      [
        command.MoveTo(context.left, context.top),
        command.Print("╭"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("╮"),
        command.MoveTo(context.left, context.top + context.height - 1),
        command.Print("╰"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("╯"),
      ],

      list.range(context.top + 1, context.top + context.height - 2)
        |> list.map(fn(row) {
          [
            command.MoveTo(context.left, row),
            command.Print("│"),
            command.MoveTo(int.max(0, context.left + context.width - 1), row),
            command.Print("│"),
          ]
        })
        |> list.flatten,
      child_commands,
    ]),
    child_callbacks,
    child_after,
  )
}

fn draw_vertical_split(
  context: Context,
  left: Node(msg),
  right: Node(msg),
  left_size: Size,
) -> DrawResponse(msg) {
  let left_size = calculate_size(left_size, context.width, context.width / 2)
  let DrawResponse(left_commands, left_callbacks, left_after) =
    draw_in_context(
      left,
      Context(context.left, context.top, left_size, context.height),
    )
  let DrawResponse(right_commands, right_callbacks, right_after) =
    draw_in_context(
      right,
      Context(
        context.left + left_size,
        context.top,
        context.width - left_size,
        context.height,
      ),
    )

  DrawResponse(
    list.flatten([left_commands, right_commands]),
    list.flatten([left_callbacks, right_callbacks]),
    list.flatten([left_after, right_after]),
  )
}

fn draw_horizontal_split(
  context: Context,
  upper: Node(msg),
  lower: Node(msg),
  upper_size: Size,
) -> DrawResponse(msg) {
  let upper_size =
    calculate_size(upper_size, context.height, context.height / 2)
  let DrawResponse(upper_commands, upper_callbacks, upper_after) =
    draw_in_context(
      upper,
      Context(context.left, context.top, context.width, upper_size),
    )
  let DrawResponse(lower_commands, lower_callbacks, lower_after) =
    draw_in_context(
      lower,
      Context(
        context.left,
        context.top + upper_size,
        context.width,
        context.height - upper_size,
      ),
    )

  DrawResponse(
    list.flatten([upper_commands, lower_commands]),
    list.flatten([upper_callbacks, lower_callbacks]),
    list.flatten([upper_after, lower_after]),
  )
}

fn draw_grid(
  context: Context,
  rows: List(Size),
  columns: List(Size),
  children: List(GridCell(msg)),
) -> DrawResponse(msg) {
  let row_sizes = calculate_sizes(rows, context.height)
  let col_sizes = calculate_sizes(columns, context.width)

  let accumulated =
    list.fold(children, #([], [], []), fn(accumulator, child) {
      let #(row_start, row_end) = child.rows
      let #(col_start, col_end) = child.columns

      let #(top, height) =
        calculate_span(row_sizes, row_start, row_end + 1 - row_start)
      let #(left, width) =
        calculate_span(col_sizes, col_start, col_end + 1 - col_start)

      let DrawResponse(child_commands, child_callbacks, child_after) =
        draw_in_context(
          child.node,
          Context(
            left: context.left + left,
            top: context.top + top,
            width: width,
            height: height,
          ),
        )

      #([child_commands, ..accumulator.0], [child_callbacks, ..accumulator.1], [
        child_after,
        ..accumulator.2
      ])
    })

  DrawResponse(
    list.flatten(accumulated.0),
    list.flatten(accumulated.1),
    list.flatten(accumulated.2),
  )
}

fn calculate_span(sizes: List(Int), start: Int, count: Int) -> #(Int, Int) {
  let offset = sizes |> list.take(start) |> int.sum
  let size = sizes |> list.drop(start) |> list.take(count) |> int.sum
  #(offset, size)
}

fn calculate_size(size: Size, full_size: Int, auto_size: Int) -> Int {
  case size {
    Cells(cells) ->
      case cells <= full_size {
        True -> cells
        False -> full_size
      }
    Percent(percent) -> full_size * percent / 100
    Auto -> auto_size
  }
}

fn calculate_sizes(sizes: List(Size), full_size: Int) -> List(Int) {
  let auto_count =
    list.count(sizes, fn(size) {
      case size {
        Auto -> True
        _ -> False
      }
    })

  let cells_used =
    sizes
    |> list.map(fn(size) {
      case size {
        Auto -> 0
        Cells(cells) -> cells
        Percent(percent) -> full_size * percent / 100
      }
    })
    |> int.sum

  let auto_size = { full_size - cells_used } / auto_count

  list.map(sizes, fn(size) {
    case size {
      Cells(cells) -> cells
      Percent(percent) -> full_size * percent / 100
      Auto -> auto_size
    }
  })
}
