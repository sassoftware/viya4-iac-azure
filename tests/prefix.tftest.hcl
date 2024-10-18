variables {
  location = "eastus2"
}

run "prefix_length_too_short" {

  command = plan
  
  variables {
    prefix = "ba"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_disallowed_char" {

  command = plan
  
  variables {
    prefix = "foo*"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_dissallowed_uppercase" {

  command = plan
  
  variables {
    prefix = "Foobar"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_cannot_start_with_dash" {

  command = plan
  
  variables {
    prefix = "-bar"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_cannot_end_with_dash" {

  command = plan
  
  variables {
    prefix = "ba-"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_length_ok_internal_dash" {

  command = plan
  
  variables {
    prefix = "my-prefix"
  }
}


run "prefix_length_ok_with_number" {

  command = plan
  
  variables {
    prefix = "my-prefix21"
  }
}
