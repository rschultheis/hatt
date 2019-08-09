workflow "unit tests" {
  on = "push"
  resolves = ["rake"]
}

action "Setup Ruby for use with actions" {
  uses = "actions/setup-ruby@v1"
}

action "rake" {
  uses = "rake"
  needs = ["Setup Ruby for use with actions"]
}
