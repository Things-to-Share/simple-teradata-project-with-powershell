$environments = @()

# Here you can congiure the max length of a view (In Teradata the metadata is nog easily accessable.) Keeping view "short" will force the developer to stay on point and NOT to maken complex view the do everything in one go. Surpassing this length will result in warnings during deployment.
$ni_max_length_view = 16000

if ($true) { # Development

  $environment = @{

    # Name of Environment
    nm_environment = "Development"

    # Maximum length of Teradata View
    ni_max_length_view = $ni_max_length_view

    # List of Parameters
    parameters = @() 

  }

  # Add Parameters as needed
  $environment.parameters += @{
    name  = "cd_environment"
    value = "O"
  }
  $environment.parameters += @{
    name  = "nm_dsn"
    value = "OdbcDsnExampleName_O"
  }
  $environment.parameters += @{
    name  = "nm_database_target"
    value = "example_db_o"
  }

  # Add More Parameters if needed
  $environment.parameters += @{
    name  = "parameter_example_name"
    value = "parameter_example_value"
  }

  # Add the "Development"-environment information tp $environments
  $environments += $environment

}

if ($true) { # Test

  $environment = @{

    # Name of Environment
    nm_environment = "Test"

    # Maximum length of Teradata View
    ni_max_length_view = $ni_max_length_view

    # List of Parameters
    parameters = @() 

  }

  # Add Parameters as needed
  $environment.parameters += @{
    name  = "cd_environment"
    value = "T"
  }
  $environment.parameters += @{
    name  = "nm_dsn"
    value = "OdbcDsnExampleName_T"
  }
  $environment.parameters += @{
    name  = "nm_database_target"
    value = "example_db_t"
  }

  # Add More Parameters if needed
  $environment.parameters += @{
    name  = "parameter_example_name"
    value = "parameter_example_value"
  }

  # Add the "Development"-environment information tp $environments
  $environments += $environment

}

if ($true) { # Acceptance

  $environment = @{

    # Name of Environment
    nm_environment = "Acceptance"

    # Maximum length of Teradata View
    ni_max_length_view = $ni_max_length_view

    # List of Parameters
    parameters = @() 

  }

  # Add Parameters as needed
  $environment.parameters += @{
    name  = "cd_environment"
    value = "A"
  }
  $environment.parameters += @{
    name  = "nm_dsn"
    value = "OdbcDsnExampleName_A"
  }
  $environment.parameters += @{
    name  = "nm_database_target"
    value = "example_db_a"
  }

  # Add More Parameters if needed
  $environment.parameters += @{
    name  = "parameter_example_name"
    value = "parameter_example_value"
  }

  # Add the "Development"-environment information tp $environments
  $environments += $environment

}

if ($true) { # Production

  $environment = @{

    # Name of Environment
    nm_environment = "Production"

    # Maximum length of Teradata View
    ni_max_length_view = $ni_max_length_view

    # List of Parameters
    parameters = @() 

  }

  # Add Parameters as needed
  $environment.parameters += @{
    name  = "cd_environment"
    value = "P"
  }
  $environment.parameters += @{
    name  = "nm_dsn"
    value = "OdbcDsnExampleName_P"
  }
  $environment.parameters += @{
    name  = "nm_database_target"
    value = "example_db_p"
  }

  # Add More Parameters if needed
  $environment.parameters += @{
    name  = "parameter_example_name"
    value = "parameter_example_value"
  }

  # Add the "Development"-environment information tp $environments
  $environments += $environment

}
