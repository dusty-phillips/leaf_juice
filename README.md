# Leaf Juice

The Elm Architecture built on [etch](https://hexdocs.pm/etch/index.html)


## Development

```sh
gleam run -m leaf_juice_example
gleam test  # Run the tests
```

Look at the example in dev/leaf_juice_example.gleam to see what works

## Current and Planned Features

- [x] Text
- [x] Split Layouts
- [x] Grid Layout
- [x] Stack Layout
- [x] Scrollable Layouts (including with mouse)
- [x] Scrollable text (including with mouse)
- [x] Single line input
- [x] Button
- [x] Basic outline box
- [x] styling with Etch styles
- [x] Tabbed Layout
- [ ] Multi-line text input
- [ ] List

## Focus is NOT PLANNED

After looking at some of my favourite TUI apps and the sources of TUIs that try
to manage focus, I decided not to add focus management to leaf juice.

It's pretty easy to add yourself as shown in the example. I think it looks better
that way than to add a false dependency between view and model in Leaf Juice.

More importantly, I noticed that LazyGit, for example, has multiple distinct
focus cycles. This is nice from a user perspective and has to be implemented in
the application. In contrast, the global tab-order in a browser is actually
kind of useless because there are so many potential tab stops. So I didn't even
try to manage focus and I don't intend to. Focus is state in Leaf Juice, and
it is up to the application to manage state.
