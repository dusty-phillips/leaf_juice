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
  Fill
}

pub type Node(msg) {
  Empty
  Text(String)
  ScrollableText(text: String, scroll_position: Int, is_focused: Bool)

  Button(text: String, is_focused: Bool, on_click: fn() -> msg)
  TextInput(model: TextInputModel, is_focused: Bool, on_click: fn() -> msg)

  OutlinedBox(child: Node(msg))

  VerticalSplit(left: Node(msg), right: Node(msg), left_size: Size)
  HorizontalSplit(upper: Node(msg), lower: Node(msg), upper_size: Size)
  VerticalStack(children: List(Node(msg)))
  Scrollable(children: List(Node(msg)), scroll_position: Int)
  Grid(rows: List(Size), columns: List(Size), children: List(GridCell(msg)))
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

pub fn update_scrollable(scroll_position: Int, event: event.Event) -> Int {
  case event {
    event.Mouse(event.MouseEvent(kind: event.ScrollUp, ..), ..) ->
      int.max(0, scroll_position - 1)

    event.Mouse(event.MouseEvent(kind: event.ScrollDown, ..), ..) ->
      scroll_position + 1

    event.Key(event.KeyEvent(kind: event.Release, code: event.UpArrow, ..)) ->
      int.max(0, scroll_position - 1)

    event.Key(event.KeyEvent(kind: event.Release, code: event.DownArrow, ..)) ->
      scroll_position + 1

    event.Key(event.KeyEvent(kind: event.Release, code: event.PageUp, ..)) ->
      int.max(0, scroll_position - 10)

    event.Key(event.KeyEvent(kind: event.Release, code: event.PageDown, ..)) ->
      scroll_position + 10

    _ -> scroll_position
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

type ContextHeight {
  BoundedHeight(Int)
  UnboundedHeight
}

type Context {
  Context(left: Int, top: Int, width: Int, height: ContextHeight)
}

type DrawResponse(msg) {
  DrawResponse(
    commands: List(command.Command),
    callbacks: List(MouseCallback(msg)),
    // Commands to be run after drawing everything else
    // I don't like this it is a hack but it is the way I came up with
    // to move the cursor to a focused input without managing focus
    after_commands: List(command.Command),
    height: Int,
  )
}

@internal
pub fn draw(
  node: Node(msg),
  window_size: #(Int, Int),
) -> #(List(command.Command), List(MouseCallback(msg))) {
  let #(columns, rows) = window_size

  let DrawResponse(commands, callbacks, after_commands, _height) =
    draw_in_context(node, Context(0, 0, columns, BoundedHeight(rows)))

  let commands = list.flatten([[command.HideCursor], commands, after_commands])

  #(commands, callbacks)
}

fn draw_in_context(node: Node(msg), context: Context) -> DrawResponse(msg) {
  case node {
    Empty ->
      DrawResponse([], [], [], case context.height {
        BoundedHeight(height) -> height
        UnboundedHeight -> 0
      })

    Text(text) -> draw_text(context, text)

    ScrollableText(text, scroll_position, is_focused) ->
      draw_scrollable_text(context, text, scroll_position, is_focused)

    Button(text, is_focused, on_click) ->
      draw_button(context, text, is_focused, on_click)

    TextInput(model, is_focused, on_click) ->
      draw_text_input(context, model, is_focused, on_click)

    OutlinedBox(child) -> draw_outlined_box(context, child)

    VerticalSplit(left, right, left_size) ->
      draw_vertical_split(context, left, right, left_size)

    HorizontalSplit(upper, lower, upper_size) ->
      draw_horizontal_split(context, upper, lower, upper_size)

    VerticalStack(children) -> draw_vertical_stack(context, children)

    Scrollable(children, scroll_position) ->
      draw_scrollable(context, children, scroll_position)

    Grid(rows, columns, children) -> draw_grid(context, rows, columns, children)
  }
}

fn draw_text(context: Context, text: String) -> DrawResponse(msg) {
  let all_lines =
    text
    |> string.split("\n")
    |> list.map(fn(line) {
      line |> str.wrap_at(context.width) |> string.split("\n")
    })
    |> list.flatten

  let #(lines, height) = case context.height {
    BoundedHeight(height) -> #(list.take(all_lines, height), height)
    UnboundedHeight -> #(all_lines, list.length(all_lines))
  }

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
    height,
  )
}

fn draw_scrollable_text(
  context: Context,
  text: String,
  scroll_position: Int,
  is_focused: Bool,
) -> DrawResponse(msg) {
  let fg = case is_focused {
    False -> style.Grey
    True -> style.White
  }
  let all_lines =
    text
    |> str.wrap_at(context.width - 2)
    |> string.split("\n")

  let lines =
    all_lines
    |> list.drop(scroll_position)

  let line_count = all_lines |> list.length

  let #(displayed_lines, height) = case context.height {
    BoundedHeight(height) -> #(lines |> list.take(height), height)
    // Doesn't make a lot of sense to have unbounded height with a scrollable
    // (i.e. a scrollable in a scrollable), but gleam makes us support it.
    UnboundedHeight -> #(lines, list.length(lines))
  }

  let scrollbar_position =
    int.min(height + 1, scroll_position * height / line_count + context.top)

  DrawResponse(
    [
      [command.SetForegroundColor(fg)],
      displayed_lines
        |> list.index_map(fn(line, row) {
          [
            command.MoveTo(context.left, context.top + row),
            command.Print(line),
          ]
        })
        |> list.flatten,
      draw_scrollbar(
        context.left + context.width - 1,
        context.top,
        height,
        scrollbar_position,
      ),
      [
        command.ResetColor,
      ],
    ]
      |> list.flatten,
    [],
    [],
    height,
  )
}

fn draw_scrollbar(
  x_position: Int,
  top: Int,
  height: Int,
  scroll_position: Int,
) -> List(command.Command) {
  [
    int.range(top, top + height, [], fn(acc, row) {
      [
        [
          command.MoveTo(x_position, row),
          command.Print("|"),
        ],
        acc,
      ]
      |> list.flatten
    }),
    [
      command.MoveTo(x_position, scroll_position),
      command.Print("▓"),
    ],
  ]
  |> list.flatten
}

fn draw_button(
  context: Context,
  text: String,
  is_focused: Bool,
  on_click: fn() -> msg,
) -> DrawResponse(msg) {
  let height = case context.height {
    BoundedHeight(height) -> height
    // one cell above and below one line of text
    UnboundedHeight -> 3
  }

  let rows_above = { height - 1 } / 2
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

      int.range(
        context.top + rows_above,
        context.top - 1,
        [],
        fn(accumulator, row) {
          [
            command.MoveTo(context.left, row),
            " " |> string.repeat(context.width) |> command.Print,
            ..accumulator
          ]
        },
      ),

      [
        command.MoveTo(context.left, context.top + rows_above + 1),
        command.Print(string.repeat(" ", columns_before)),
        command.Print(text),
        command.Print(string.repeat(
          " ",
          context.width - columns_before - string.length(text),
        )),
      ],

      int.range(
        context.top + height - 1,
        context.top + rows_above + 1,
        [],
        fn(accumulator, row) {
          [
            command.MoveTo(context.left, row),
            " " |> string.repeat(context.width) |> command.Print,
            ..accumulator
          ]
        },
      ),

      [command.ResetColor],
    ]
      |> list.flatten,
    [
      MouseClickCallback(
        context.left,
        context.top,
        context.width,
        height,
        on_click,
      ),
    ],
    [],
    height,
  )
}

fn draw_text_input(
  context: Context,
  model: TextInputModel,
  is_focused: Bool,
  on_click: fn() -> msg,
) -> DrawResponse(msg) {
  let height = case context.height {
    BoundedHeight(height) -> height
    // Two borders and one line of text
    UnboundedHeight -> 3
  }

  let rows_above = { height - 3 } / 2
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
        command.MoveTo(context.left, context.top + height - 1),
        command.Print("└"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("┘"),
      ],

      int.range(context.top + height - 2, context.top, [], fn(accumulator, row) {
        [
          [
            command.MoveTo(context.left, row),
            command.Print("│"),
            command.MoveTo(int.max(0, context.left + context.width - 1), row),
            command.Print("│"),
          ],
          ..accumulator
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
        height,
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
    height,
  )
}

fn draw_outlined_box(context: Context, child: Node(msg)) -> DrawResponse(msg) {
  let DrawResponse(child_commands, child_callbacks, child_after, child_height) =
    draw_in_context(
      child,
      Context(
        context.left + 1,
        context.top + 1,
        context.width - 2,
        case context.height {
          BoundedHeight(height) -> BoundedHeight(height - 2)
          UnboundedHeight -> UnboundedHeight
        },
      ),
    )

  DrawResponse(
    list.flatten([
      [
        command.MoveTo(context.left, context.top),
        command.Print("╭"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("╮"),
        command.MoveTo(context.left, context.top + child_height + 1),
        command.Print("╰"),
        command.Print(string.repeat("─", context.width - 2)),
        command.Print("╯"),
      ],

      int.range(
        context.top + child_height,
        context.top,
        [],
        fn(accumulator, row) {
          [
            [
              command.MoveTo(context.left, row),
              command.Print("│"),
              command.MoveTo(int.max(0, context.left + context.width - 1), row),
              command.Print("│"),
            ],
            ..accumulator
          ]
        },
      )
        |> list.flatten,
      child_commands,
    ]),
    child_callbacks,
    child_after,
    child_height + 2,
  )
}

fn draw_vertical_split(
  context: Context,
  left: Node(msg),
  right: Node(msg),
  left_size: Size,
) -> DrawResponse(msg) {
  let left_size = calculate_size(left_size, context.width, context.width / 2)
  let DrawResponse(left_commands, left_callbacks, left_after, left_height) =
    draw_in_context(
      left,
      Context(context.left, context.top, left_size, context.height),
    )
  let DrawResponse(right_commands, right_callbacks, right_after, right_height) =
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
    int.max(left_height, right_height),
  )
}

fn draw_horizontal_split(
  context: Context,
  upper: Node(msg),
  lower: Node(msg),
  upper_size: Size,
) -> DrawResponse(msg) {
  let upper_size = case context.height {
    BoundedHeight(height) ->
      BoundedHeight(calculate_size(upper_size, height, height / 2))
    UnboundedHeight -> UnboundedHeight
  }

  let DrawResponse(upper_commands, upper_callbacks, upper_after, upper_height) =
    draw_in_context(
      upper,
      Context(context.left, context.top, context.width, upper_size),
    )

  let lower_size = case context.height {
    BoundedHeight(height) -> BoundedHeight(height - upper_height)
    UnboundedHeight -> UnboundedHeight
  }

  let DrawResponse(lower_commands, lower_callbacks, lower_after, lower_height) =
    draw_in_context(
      lower,
      Context(
        context.left,
        context.top + upper_height,
        context.width,
        lower_size,
      ),
    )

  DrawResponse(
    list.flatten([upper_commands, lower_commands]),
    list.flatten([upper_callbacks, lower_callbacks]),
    list.flatten([upper_after, lower_after]),
    upper_height + lower_height,
  )
}

fn draw_vertical_stack(
  context: Context,
  children: List(Node(msg)),
) -> DrawResponse(msg) {
  let responses =
    list.fold(children, [], fn(previous_responses, child) {
      let accumulated_height =
        list.fold(previous_responses, 0, fn(total_height, draw_response) {
          let DrawResponse(height:, ..) = draw_response
          total_height + height
        })

      [
        draw_in_context(
          child,
          Context(
            context.left,
            context.top + accumulated_height,
            context.width,
            UnboundedHeight,
          ),
        ),
        ..previous_responses
      ]
    })
    |> list.reverse

  DrawResponse(
    commands: responses
      |> list.map(fn(response) { response.commands })
      |> list.flatten,
    callbacks: responses
      |> list.map(fn(response) { response.callbacks })
      |> list.flatten,
    after_commands: responses
      |> list.map(fn(response) { response.after_commands })
      |> list.flatten,
    height: responses |> list.map(fn(response) { response.height }) |> int.sum,
  )
}

fn draw_scrollable(
  context: Context,
  children: List(Node(msg)),
  scroll_position: Int,
) -> DrawResponse(msg) {
  let height = case context.height {
    BoundedHeight(height) -> height
    UnboundedHeight -> panic as "Cannot nest a scrollable in a scrollable"
  }

  let stack_response =
    draw_vertical_stack(
      Context(
        ..context,
        top: context.top - scroll_position,
        height: UnboundedHeight,
      ),
      children,
    )

  let commands =
    clip_commands(stack_response.commands, context.top, context.top + height)

  DrawResponse(..stack_response, commands:)
}

fn clip_commands(
  commands: List(command.Command),
  top: Int,
  bottom: Int,
) -> List(command.Command) {
  commands
  |> list.fold(#([], True), fn(acc, cmd) {
    let #(result, visible) = acc
    case cmd {
      command.MoveTo(_, y) -> {
        let in_view = y >= top && y < bottom
        case in_view {
          True -> #([cmd, ..result], True)
          False -> #(result, False)
        }
      }
      _ ->
        case visible {
          True -> #([cmd, ..result], visible)
          False -> #(result, visible)
        }
    }
  })
  |> fn(acc) { acc.0 }
  |> list.reverse
}

fn draw_grid(
  context: Context,
  rows: List(Size),
  columns: List(Size),
  children: List(GridCell(msg)),
) -> DrawResponse(msg) {
  let col_sizes = calculate_col_sizes(columns, context.width)
  let row_sizes = calculate_row_sizes(rows, context.height)

  let accumulated =
    list.fold(children, #([], [], []), fn(accumulator, child) {
      let #(row_start, row_end) = child.rows
      let #(col_start, col_end) = child.columns

      let #(top, height) =
        calculate_span(row_sizes, row_start, row_end + 1 - row_start)
      let #(left, width) =
        calculate_span(col_sizes, col_start, col_end + 1 - col_start)

      let DrawResponse(
        child_commands,
        child_callbacks,
        child_after,
        _child_height,
      ) =
        draw_in_context(
          child.node,
          Context(
            left: context.left + left,
            top: context.top + top,
            width: width,
            height: BoundedHeight(height),
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
    int.sum(row_sizes),
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
    Fill -> auto_size
  }
}

fn calculate_col_sizes(widths: List(Size), full_width: Int) -> List(Int) {
  let auto_count =
    list.count(widths, fn(size) {
      case size {
        Fill -> True
        _ -> False
      }
    })

  let cells_used =
    widths
    |> list.map(fn(size) {
      case size {
        Fill -> 0
        Cells(cells) -> cells
        Percent(percent) -> full_width * percent / 100
      }
    })
    |> int.sum

  let auto_size = { full_width - cells_used } / auto_count

  list.map(widths, fn(size) {
    case size {
      Cells(cells) -> cells
      Percent(percent) -> full_width * percent / 100
      Fill -> auto_size
    }
  })
}

fn calculate_row_sizes(
  heights: List(Size),
  full_height: ContextHeight,
) -> List(Int) {
  let height = case list.contains(heights, Fill), full_height {
    True, UnboundedHeight ->
      panic as "Fill row in unbounded height context. This usually happens when a Fill row is used inside a scrollable"
    _, BoundedHeight(height) -> height
    // fills aren't used with unbounded height
    False, UnboundedHeight -> 0
  }

  let fill_count =
    list.count(heights, fn(size) {
      case size {
        Fill -> True
        _ -> False
      }
    })

  let cells_used =
    heights
    |> list.map(fn(size) {
      case size {
        Fill -> 0
        Cells(cells) -> cells
        Percent(percent) -> height * percent / 100
      }
    })
    |> int.sum

  let fill_size = case fill_count {
    0 -> 0
    n -> { height - cells_used } / n
  }

  list.map(heights, fn(size) {
    case size {
      Cells(cells) -> cells
      Percent(percent) -> height * percent / 100
      Fill -> fill_size
    }
  })
}
