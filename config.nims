switch "outdir", "$config/bin"
switch "path", "$config"
# begin Nimble config (version 1)
when fileExists("nimble.paths"):
  include "nimble.paths"
# end Nimble config
