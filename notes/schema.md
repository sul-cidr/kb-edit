
# KB schema changes

To play nice with Rails, a handful of column names need to be changed in the original Kindred Britain database:

### `event`

- `class` -> `class_`
- `type` -> `type_`

### `occu`

- `class` -> `class_`

### `indiv_occu`

- `occu` -> `occu_text`
