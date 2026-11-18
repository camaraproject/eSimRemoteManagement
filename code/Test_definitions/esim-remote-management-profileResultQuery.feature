Feature: CAMARA eSIM Remote Management API, v0.1.0-alpha.1 - Operation profileResultQuery

  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  #
  # Testing assets:
  # * A task identifier returned by a previously submitted profile download, enable,
  #   disable or delete operation, both for a completed and a still pending operation
  # * A task identifier that is schema-compliant but does not identify any known task
  # * A valid access token including the scope "esim-remote-management:query-result"
  # * An access token that does not include that scope
  #
  # References to OAS spec schemas refer to schemas specified in esim-remote-management.yaml, version vwip

  Background: Common profileResultQuery setup
    Given an environment at "apiRoot"
    And the resource "/esim-remote-management/v0.1alpha1/results/{taskId}"
    And the path parameter "taskId" is set to a valid task id of a previously submitted operation
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"

# Success scenarios

  @esim_remote_management_profileResultQuery_01_success
  Scenario: Retrieve the result of a completed profile operation
    Given a profile operation previously submitted and identified by its task id
    When the request "profileResultQuery" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/ProfileOperationResult"
    And the response property "$.taskId" has the same value as the request path parameter "taskId"
    And the response property "$.status" is one of "SUCCESS", "ERROR"
    And the response property "$.statusInfo" is only included when "$.status" is "ERROR"

  @esim_remote_management_profileResultQuery_02_pending_operation
  Scenario: Retrieve the result of an operation that is still pending
    Given the path parameter "taskId" is set to a task id of an operation still in progress
    When the request "profileResultQuery" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "#/components/schemas/ProfileOperationResult"
    And the response property "$.taskId" has the same value as the request path parameter "taskId"
    And the response property "$.status" is "PENDING"
    And the response property "$.statusInfo" is not included

# Error scenarios

  @esim_remote_management_profileResultQuery_03_identifier_not_schema_compliant
  Scenario Outline: Query is rejected when the task identifier does not comply with the schema
    Given the path parameter "taskId" is set to "<value>"
    When the request "profileResultQuery" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | value                                                |
      | a string with an illegal character, such as "task#1"  |
      | a string longer than 64 characters                    |

  @esim_remote_management_profileResultQuery_04_invalid_token
  Scenario: Query is rejected without a valid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "profileResultQuery" is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileResultQuery_05_missing_scope
  Scenario: Query is rejected when the access token lacks the required scope
    Given the header "Authorization" is set to a valid access token that does not include the scope "esim-remote-management:query-result"
    When the request "profileResultQuery" is sent
    Then the response status code is 403
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileResultQuery_06_task_not_found
  Scenario: Query is rejected when the task identifier does not match any known task
    Given the path parameter "taskId" is compliant with the schema but does not identify a known task
    When the request "profileResultQuery" is sent
    Then the response status code is 404
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileResultQuery_07_too_many_requests
  Scenario: Query is rejected when the rate limit enforced by the API Provider is exceeded
    # This test only applies if the API Provider enforces a rate limit on the API
    Given the API consumer has exceeded the rate limit enforced by the API Provider
    When the request "profileResultQuery" is sent
    Then the response status code is 429
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
