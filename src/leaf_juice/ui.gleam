import etch/command
import etch/terminal
import gleam/int
import gleam/list
import gleam/string

pub type Size {
  Cells(Int)
  Percent(Int)
  Auto
}

pub type Node {
  Empty
  Text(String)

  OutlinedBox(child: Node)

  VerticalSplit(left: Node, right: Node, left_size: Size)
  HorizontalSplit(upper: Node, lower: Node, upper_size: Size)
  Grid(rows: List(Size), columns: List(Size), children: List(GridCell))
}

pub type GridCell {
  GridCell(node: Node, rows: #(Int, Int), columns: #(Int, Int))
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

    Grid(rows, columns, children) -> draw_grid(context, rows, columns, children)
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

fn draw_grid(
  context: Context,
  rows: List(Size),
  columns: List(Size),
  children: List(GridCell),
) -> List(command.Command) {
  let row_sizes = calculate_sizes(rows, context.height)
  let col_sizes = calculate_sizes(columns, context.width)

  children
  |> list.flat_map(fn(child) {
    let #(row_start, row_end) = child.rows
    let #(col_start, col_end) = child.columns

    let #(top, height) =
      calculate_span(row_sizes, row_start, row_end + 1 - row_start)
    let #(left, width) =
      calculate_span(col_sizes, col_start, col_end + 1 - col_start)

    draw_in_context(
      child.node,
      Context(
        left: context.left + left,
        top: context.top + top,
        width: width,
        height: height,
      ),
    )
  })
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
