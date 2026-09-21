Feature: CAMARA eSIM Remote Management API v0.1.0-alpha.1 - Operation profileList

    # Input to be provided by the implementation to the tester
    #
    #
    # Implementation indications:
    #
    # References to OAS spec schemas refer to schemas specifies in esim-remote-management.yaml, version vwip

  Background: Common profileList setup
    Given an environment at "apiRoot"
    And the resource "/esim-remote-management/v0.1alpha1/profile/downloaded-list"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set based on the OAS schema at "/components/schemas/BaseCmpReqEIdProfileListReq"
    And the request body property "$.timestamp" is set to a valid timestamp
    And the request body property "$.sequenceNum" is set to a valid sequence number
    And the request body property "$.clientId" is set to a valid client id
    And the request body property "$.data.eId" is set to a valid EID

# Success scenarios

  @esim_remote_management_profileList_01_generic_success_scenario
  Scenario: Common validations for any success scenario
    Given all request body properties are set to valid values
    When the request "profileList" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BaseCmpRespEIdProfileListResp"

# Error scenarios

  @esim_remote_management_profileList_02_invalid_argument_scenario
  Scenario: Error response for invalid argument in request body
    Given a request body property is invalid, such as illegal character or format error
    When the request "profileList" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" is "Client specified an invalid argument, request body or query param."

  @esim_remote_management_profileList_03_out_of_range_scenario
  Scenario: Error response where request body parameters are out of range
    Given a request body property is out of range
    When the request "profileList" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE"
    And the response property "$.message" is "Client specified an invalid range."

  @esim_remote_management_profileList_04_missing_authorization_scenario
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    And all request body properties are set to valid values
    When the request "profileList" is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileList_05_missing_access_token_scope_scenario
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope esim-remote-management:downloadedlist
    When the request "profileList" is sent
    Then the response status code is 403
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @esim_remote_management_profileList_06_not_found_scenario
  Scenario: Not found
    Given request body is in the correct format, but the specified EID cannot be found
    When the request "profileList" is sent
    Then the response status code is 404
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text
