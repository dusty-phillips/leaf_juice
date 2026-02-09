import etch/command
import etch/terminal
import gleam/int
import gleam/list
import gleam/string

pub type Node {
  Empty
  Text(String)

  OutlinedBox(child: Node)

  VerticalSplit(left: Node, right: Node)
  HorizontalSplit(upper: Node, lower: Node)
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

    VerticalSplit(left, right) ->
      [
        draw_in_context(
          left,
          Context(context.left, context.top, context.width / 2, context.height),
        ),
        draw_in_context(
          right,
          Context(
            context.left + context.width / 2,
            context.top,
            context.width / 2,
            context.height,
          ),
        ),
      ]
      |> list.flatten

    HorizontalSplit(upper, lower) ->
      [
        draw_in_context(
          upper,
          Context(context.left, context.top, context.width, context.height / 2),
        ),
        draw_in_context(
          lower,
          Context(
            context.left,
            context.top + context.height / 2,
            context.width,
            context.height / 2,
          ),
        ),
      ]
      |> list.flatten
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
