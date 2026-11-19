# Changelog eSimRemoteManagement

<!-- TOC:START -->
## Table of Contents
- [r1.1](#r11)
<!-- TOC:END -->

**Please be aware that the project will have frequent updates to the main branch. There are no compatibility guarantees associated with code in any branch, including main, until it has been released. For example, changes may be reverted before a release is published. For the best results, use the latest published release.**

The below sections record the changes for each API version in each release as follows:

* for an alpha release, the delta with respect to the previous release
* for the first release-candidate, all changes since the last public release
* for subsequent release-candidate(s), only the delta to the previous release-candidate
* for a public release, the consolidated changes since the previous public release

# r1.1

## Release Notes

This pre-release contains the definition and documentation of
* esim-remote-management 0.1.0-alpha.1

The API definition(s) are based on
* Commonalities r4.4 (0.9.0)
* Identity and Consent Management r4.2 (0.5.0)

## esim-remote-management 0.1.0-alpha.1

**esim-remote-management 0.1.0-alpha.1 is the first alpha version of this API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/eSimRemoteManagement/r1.1/code/API_definitions/esim-remote-management.yaml&nocors)
  - [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/eSimRemoteManagement/r1.1/code/API_definitions/esim-remote-management.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/eSimRemoteManagement/blob/r1.1/code/API_definitions/esim-remote-management.yaml)

### Breaking changes

* N/A

### Added

* Initial version of the `esim-remote-management` API definition, covering the remote lifecycle management of eSIM profiles on a device's eUICC. The API provides five operations:
- `POST /download` - download a new eSIM profile to the eUICC. The profile is left in the `downloaded` state and is activated by a separate enable operation.
- `POST /enable-profile` - enable a downloaded profile.
- `POST /disable-profile` - disable an enabled profile without deleting it from the device.
- `POST /delete-profile` - delete a profile from the device.
- `GET /results/{taskId}` - query the outcome of an asynchronous profile operation using the task ID returned in the `Location` header of the originating request.
* The profile lifecycle is documented as a state machine: `downloaded --enable--> enabled --disable--> disabled`, and `enabled / disabled --delete--> deleted`.
* Every profile operation targets one profile on one eUICC, and both are stated in the request body: `device.eId` identifies the eUICC and `device.iccid` the profile on it. Both are required and not interchangeable; `device.imei` is optional additional information. A request missing either identifier is rejected with `400 INVALID_ARGUMENT`.
* The four asynchronous operations (`/download`, `/enable-profile`, `/disable-profile`, `/delete-profile`) return a task ID for status tracking and can optionally notify the API consumer through the `sink`/`sinkCredential` mechanism, using `application/cloudevents+json` callbacks as defined by Commonalities. Where notification delivery is not supported by the API provider, a request carrying `sink` is rejected with `422 EVENT_NOTIFICATIONS_NOT_SUPPORTED` and the operation is not started.
* Operation status is reported as `PENDING`, `SUCCESS` or `ERROR`. `statusInfo` is present only when `status` is `ERROR`, carrying either `ICCID_NOT_FOUND` or `OPERATION_UNKNOWN_ERROR`; it is omitted for `PENDING` and `SUCCESS`. `PENDING` is returned by the originating request and by `/results/{taskId}` until the operation completes.
* Error responses aligned with Commonalities 0.9.0 (`400`, `401`, `403`, `404`, `422`, `429`), including request body strictness with `400 INVALID_ARGUMENT` for undeclared properties at any nesting level. The documented `422` codes are `SERVICE_NOT_APPLICABLE`, `UNSUPPORTED_IDENTIFIER` and `EVENT_NOTIFICATIONS_NOT_SUPPORTED`.

### Changed

* N/A

### Fixed

* N/A

### Removed

* N/A

**Full Changelog**: https://github.com/camaraproject/eSimRemoteManagement/commits/r1.1

