import etch/command
import etch/terminal
import gleam/int
import gleam/list
import gleam/string

pub type Size {
  Cells(Int)
  Percent(Int)
  Auto
  Full
}

pub type Node {
  Empty
  Text(String)

  OutlinedBox(child: Node)

  VerticalSplit(left: Node, right: Node, left_size: Size)
  HorizontalSplit(upper: Node, lower: Node, upper_size: Size)
}

type Context {
  Context(left: Int, top: Int, width: Int, height: Int)
}

@internal
pub fn draw(node: Node) -> List(command.Command) {
  let #(columns, rows) = terminal.window_size()

  draw_in_context(node, Context(0, 0, columns, rows))
}

fn draw_in_context(node: Node, context: Context) -> List(command.Command) {
  case node {
    Empty -> []

    Text(text) -> [
      command.MoveTo(context.left, context.top),
      command.Print(text),
    ]

    OutlinedBox(child) -> draw_outlined_box(context, child)

    VerticalSplit(left, right, left_size) ->
      {
        let left_size =
          calculate_size(left_size, context.width, context.width / 2)
        [
          draw_in_context(
            left,
            Context(context.left, context.top, left_size, context.height),
          ),
          draw_in_context(
            right,
            Context(
              context.left + left_size,
              context.top,
              context.width - left_size,
              context.height,
            ),
          ),
        ]
      }
      |> list.flatten

    HorizontalSplit(upper, lower, upper_size) -> {
      let upper_size =
        calculate_size(upper_size, context.height, context.height / 2)
      [
        draw_in_context(
          upper,
          Context(context.left, context.top, context.width, upper_size),
        ),
        draw_in_context(
          lower,
          Context(
            context.left,
            context.top + upper_size,
            context.width,
            context.height - upper_size,
          ),
        ),
      ]
      |> list.flatten
    }
  }
}

fn draw_outlined_box(context: Context, child: Node) -> List(command.Command) {
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
    draw_in_context(
      child,
      Context(
        context.left + 1,
        context.top + 1,
        context.width - 2,
        context.height - 2,
      ),
    ),
  ])
}

fn calculate_size(size: Size, full_size: Int, auto_size: Int) -> Int {
  case size {
    Cells(cells) ->
      case cells <= full_size {
        True -> cells
        False -> full_size
      }
    Percent(percent) -> full_size * percent / 100
    Full -> full_size
    Auto -> auto_size
  }
}
