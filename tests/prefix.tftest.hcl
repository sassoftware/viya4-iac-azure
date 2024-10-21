variables {
  location = "eastus2"
}

run "prefix_length_should_not_be_too_short" {

  command = plan
  
  variables {
    prefix = "ba"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_should_not_include_disallowed_char" {

  command = plan
  
  variables {
    prefix = "foo*"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_should_not_include_dissallowed_uppercase" {

  command = plan
  
  variables {
    prefix = "Foobar"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_should_not_start_with_dash" {

  command = plan
  
  variables {
    prefix = "-bar"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_should_not_end_with_dash" {

  command = plan
  
  variables {
    prefix = "ba-"
  }

  expect_failures = [
    var.prefix,
  ]
}

run "prefix_length_is_ok_with_internal_dash" {

  command = plan
  
  variables {
    prefix = "my-prefix"
  }
}


run "prefix_length_is_ok_and_includes_a_number" {

  command = plan
  
  variables {
    prefix = "my-prefix21"
  }
}
