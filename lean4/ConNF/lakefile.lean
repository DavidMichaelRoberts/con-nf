import Lake
open Lake DSL

package ConNF

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"

@[default_target]
lean_lib ConNF
