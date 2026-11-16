Feature: CAMARA eSIM Remote Management API, v0.1.0-alpha.1 - Operation profileEnable

  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Whether the implementation supports asynchronous notification of the operation outcome
  #   via the optional `sink` parameter, and the behaviour when `sink` is not supported
  #
  # Testing assets:
  # * A valid EID of a device with an eUICC, on which a disabled profile is installed
  # * A valid IMEI of a device with an eUICC
  # * A valid ICCID of a profile installed on that device which is currently disabled
  # * An EID and an IMEI that are schema-compliant but do not identify any existing device
  # * A valid access token including the scope "esim-remote-management:enable-profile"
  # * An access token that does not include that scope
  # * A sink URL able to receive and record notifications in CloudEvents format
  # * A device for which the service is not applicable
  # * A valid access token which does not identify a single device
  #
  # References to OAS spec schemas refer to schemas specified in esim-remote-management.yaml, version vwip

  Background: Common profileEnable setup
    Given an environment at "apiRoot"
    And the resource "/esim-remote-management/v0.1alpha1/enable-profile"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set based on the OAS schema at "#/components/schemas/ProfileOperationRequest"
    And the request body property "$.device.eId" is set to a valid EID
    And the request body property "$.device.iccid" is set to a valid ICCID of a disabled profile

# Success scenarios

  @esim_remote_management_profileEnable_01_success
  Scenario: Enable a profile and receive a task identifier
    Given a device with an eUICC carrying the disabled profile identified in the request body
    When the request "profileEnable" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response header "Location" exists
    And the response body complies with the OAS schema at "#/components/schemas/ProfileOperationResult"
    And the response property "$.taskId" exists
    And the response property "$.status" exists

  @esim_remote_management_profileEnable_02_imei_as_device_identifier
  Scenario: Enable a profile on a device identified by IMEI instead of EID
    Given the request body property "$.device.eId" is not included
    And the request body property "$.device.imei" is set to a valid IMEI
    When the request "profileEnable" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/ProfileOperationResult"
    And the response property "$.taskId" exists

  @esim_remote_management_profileEnable_03_notification_success
  Scenario: Outcome of the profile enable operation is notified to the provided sink
    Given the request body property "$.sink" is set to a valid callback URI
    When the request "profileEnable" is sent
    Then the response status code is 201
    And the response property "$.taskId" exists
    And within 30 seconds a notification is received at the sink
    And the notification property "$.type" is "org.camaraproject.esim-remote-management.v0.profile-operation-completed"
    And the notification body complies with the OAS schema at "#/components/schemas/ProfileOperationCallback"
    And the notification property "$.data.taskId" has the same value as the response property "$.taskId"

# Error scenarios

  @esim_remote_management_profileEnable_04_device_without_identifier
  Scenario: Enable is rejected when the device object contains no identifier
    Given the request body property "$.device" is set to: {}
    When the request "profileEnable" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_05_identifier_not_schema_compliant
  Scenario Outline: Enable is rejected when <property> does not comply with the schema
    Given the request body property "<property>" does not comply with the OAS schema at "<schema>"
    When the request "profileEnable" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property        | schema                                |
      | $.device.eId    | #/components/schemas/Eid              |
      | $.device.iccid  | #/components/schemas/Iccid            |

  @esim_remote_management_profileEnable_06_unknown_property
  Scenario: Enable is rejected when the request body contains an undeclared property
    Given the request body property "$.unknownProperty" is set to "x"
    When the request "profileEnable" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_07_invalid_token
  Scenario: Enable is rejected without a valid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "profileEnable" is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_08_missing_scope
  Scenario: Enable is rejected when the access token lacks the required scope
    Given the header "Authorization" is set to a valid access token that does not include the scope "esim-remote-management:enable-profile"
    When the request "profileEnable" is sent
    Then the response status code is 403
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_09_identifier_not_found
  Scenario: Enable is rejected when the device identifier does not match any device
    Given the request body property "$.device.eId" is compliant with the schema but does not identify an existing device
    When the request "profileEnable" is sent
    Then the response status code is 404
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_10_event_notifications_not_supported
  Scenario: Enable is rejected when a sink is provided but notifications are not supported
    # Only applicable when the implementation does not support notification delivery
    Given the request body property "$.sink" is set to a valid callback URI
    When the request "profileEnable" is sent
    Then the response status code is 422
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "EVENT_NOTIFICATIONS_NOT_SUPPORTED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_11_unnecessary_identifier
  Scenario: Enable is rejected when the device is identified both by the token and in the request body
    Given the header "Authorization" is set to a valid three-legged access token identifying the device
    And the request body property "$.device.eId" is set to a valid EID
    When the request "profileEnable" is sent
    Then the response status code is 422
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_12_missing_identifier
  Scenario: Enable is rejected when the device cannot be identified
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "profileEnable" is sent
    Then the response status code is 422
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_13_unsupported_identifier
  Scenario: Enable is rejected when none of the provided device identifiers is supported
    Given that some types of device identifiers are not supported by the implementation
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "profileEnable" is sent
    Then the response status code is 422
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_14_service_not_applicable
  Scenario: Enable is rejected when the service is not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "profileEnable" is sent
    Then the response status code is 422
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileEnable_15_too_many_requests
  Scenario: Enable is rejected when the rate limit enforced by the API Provider is exceeded
    # This test only applies if the API Provider enforces a rate limit on the API
    Given the API consumer has exceeded the rate limit enforced by the API Provider
    When the request "profileEnable" is sent
    Then the response status code is 429
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
