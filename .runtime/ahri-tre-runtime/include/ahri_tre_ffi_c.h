#ifndef AHRI_TRE_FFI_C_H
#define AHRI_TRE_FFI_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ahri_tre_status {
    /* Call completed and output ownership follows the function docs. */
    AHRI_TRE_STATUS_OK = 0,
    /* A required input or output pointer was NULL. */
    AHRI_TRE_STATUS_NULL_POINTER = 1,
    /* ABI-side configuration shape or value is invalid. */
    AHRI_TRE_STATUS_INVALID_CONFIG = 2,
    /* ABI-side configuration uses flags or options this adapter does not support. */
    AHRI_TRE_STATUS_UNSUPPORTED_CONFIG = 3,
    /*
     * A non-NULL handle pointer is not a live handle of the expected type.
     * Double-free, foreign-pointer free, and concurrent mutation/free of the
     * same handle remain caller errors.
     */
    AHRI_TRE_STATUS_INVALID_HANDLE = 4,
    /* Request bytes were not UTF-8 before a protocol envelope could be parsed. */
    AHRI_TRE_STATUS_INVALID_UTF8 = 5,
    /* ABI-side allocation failed while producing an owned output. */
    AHRI_TRE_STATUS_ALLOCATION_FAILED = 6
} ahri_tre_status;

typedef struct ahri_tre_client ahri_tre_client;
typedef struct ahri_tre_result ahri_tre_result;
typedef struct ahri_tre_session ahri_tre_session;

typedef enum ahri_tre_payload_kind {
    AHRI_TRE_PAYLOAD_KIND_NONE = 0,
    AHRI_TRE_PAYLOAD_KIND_ARROW_IPC = 1,
    AHRI_TRE_PAYLOAD_KIND_PARQUET = 2,
    AHRI_TRE_PAYLOAD_KIND_ARTIFACT = 3
} ahri_tre_payload_kind;

#define AHRI_TRE_PAYLOAD_DESCRIPTOR_FLAGS_NONE 0u
#define AHRI_TRE_PAYLOAD_DESCRIPTOR_FLAGS_BYTES_BORROWABLE 1u

#define AHRI_TRE_CLIENT_CONFIG_FLAGS_NONE 0u
#define AHRI_TRE_RUNTIME_CONFIG_FLAGS_NONE 0u
#define AHRI_TRE_RUNTIME_CONFIG_FLAGS_NEVER_START 1u

typedef struct ahri_tre_client_config {
    size_t struct_size;
    uint32_t flags;
} ahri_tre_client_config;

typedef struct ahri_tre_runtime_config {
    size_t struct_size;
    uint32_t flags;
    const char *daemon_endpoint;
    const char *daemon_binary;
    uint32_t readiness_timeout_ms;
} ahri_tre_runtime_config;

typedef struct ahri_tre_byte_view {
    const uint8_t *data;
    size_t len;
} ahri_tre_byte_view;

typedef struct ahri_tre_payload_descriptor {
    size_t struct_size;
    ahri_tre_payload_kind kind;
    uint32_t flags;
    const char *protocol_ref;
    const char *media_type;
    const char *suggested_name;
    size_t size_bytes;
} ahri_tre_payload_descriptor;

/*
 * Returned strings are owned by the caller and must be released with
 * ahri_tre_string_free. Passing NULL to ahri_tre_string_free is allowed.
 */

/* ABI surface version for the stable C adapter layer. */
char *ahri_tre_abi_version(void);

/*
 * C ABI library package version. This is build/package identity, not the
 * protocol compatibility contract.
 */
char *ahri_tre_library_version(void);

/* Current public AHRI TRE protocol version from ahri_tre_protocol. */
char *ahri_tre_protocol_version(void);

/* Minimum supported public AHRI TRE protocol version. */
char *ahri_tre_protocol_compatibility_minimum(void);

/* Maximum supported public AHRI TRE protocol version. */
char *ahri_tre_protocol_compatibility_maximum(void);

/* Protocol compatibility rule name, for example "same_major_not_newer". */
char *ahri_tre_protocol_compatibility_rule(void);

/*
 * Returns a default client configuration. The default configuration does not
 * open a datastore, lake, OAuth/OIDC, daemon, or session connection during
 * ahri_tre_client_create.
 */
ahri_tre_client_config ahri_tre_client_config_default(void);

/*
 * Returns a default managed-runtime lifecycle configuration.
 *
 * Runtime configuration is separate from client configuration. It carries
 * lifecycle concerns such as endpoint-only operation, never-start policy,
 * daemon binary override, and readiness options. Passing NULL for a
 * runtime config to lifecycle helpers is equivalent to this default.
 *
 * daemon_endpoint, when present, selects endpoint-only behavior: the ABI uses
 * that local daemon endpoint and does not start a replacement runtime if it is
 * unavailable. AHRI_TRE_RUNTIME_CONFIG_FLAGS_NEVER_START forbids starting a
 * runtime; with no explicit endpoint it may reuse an already-running shared
 * runtime and otherwise returns a lifecycle unavailable result or, during
 * protocol execution, a protocol-shaped unavailable failure.
 */
ahri_tre_runtime_config ahri_tre_runtime_config_default(void);

/*
 * Reports managed local runtime status without starting, stopping, cleaning, or
 * otherwise mutating the runtime root.
 *
 * config may be NULL to use the default user-scoped runtime. out_result must be
 * non-NULL. On success, out_result owns private local-runtime lifecycle JSON
 * and must be released with ahri_tre_result_free. Use the existing result JSON
 * accessors to inspect it, but do not treat lifecycle JSON as a public TRE
 * protocol response envelope.
 *
 * The lifecycle JSON includes stable top-level schema, schema_version, kind,
 * status, action, message, and diagnostics fields. Diagnostics are safe for
 * wrapper logs and omit credentials, request bodies, host paths, lake internals,
 * and runtime storage details.
 */
ahri_tre_status ahri_tre_runtime_status(
    const ahri_tre_runtime_config *config,
    ahri_tre_result **out_result);

/*
 * Discovers the managed local daemon binary used by runtime ensure/start paths.
 * This is a local-runtime lifecycle helper, not a public TRE protocol request.
 *
 * Discovery checks an explicit daemon_binary override first, then
 * AHRI_TRE_DAEMON_BIN, then packaged/sibling ahri-tred locations beside the
 * loaded C ABI artifact or current executable. It does not require ahri-tred to
 * be on the caller's shell PATH.
 *
 * On success or failure, out_result owns private local-runtime lifecycle JSON
 * and must be released with ahri_tre_result_free. Diagnostics report safe
 * discovery source labels and location classes, and omit credentials, raw
 * request bodies, host paths, lake internals, and runtime storage details.
 */
ahri_tre_status ahri_tre_runtime_discover_daemon_binary(
    const ahri_tre_runtime_config *config,
    ahri_tre_result **out_result);

/*
 * Ensures the shared managed local runtime is ready for protocol execution.
 *
 * config may be NULL to use the default user-scoped runtime. out_result must be
 * non-NULL. On success, out_result owns private local-runtime lifecycle JSON
 * and must be released with ahri_tre_result_free. This helper does not require
 * an ahri_tre_client handle, and no client handle owns or stops the shared
 * runtime.
 *
 * Ensure/start reuses an already-running compatible daemon. Otherwise it uses
 * the shared session root, daemon socket, daemon session metadata semantics,
 * stale-socket recovery, and readiness checks of the local daemon path. It
 * verifies public protocol compatibility by talking to the daemon separately
 * from C ABI/package version metadata.
 *
 * Lifecycle JSON reports startup, reuse, readiness timeout, stale socket
 * recovery, incompatible runtime, discovery failure, and policy-forbidden
 * outcomes through stable top-level schema, schema_version, kind, status,
 * action, message, and diagnostics fields.
 */
ahri_tre_status ahri_tre_runtime_ensure(
    const ahri_tre_runtime_config *config,
    ahri_tre_result **out_result);

/*
 * Stops the shared managed local runtime explicitly and idempotently.
 *
 * config may be NULL to use the default user-scoped runtime. out_result must be
 * non-NULL. On success, out_result owns private local-runtime lifecycle JSON
 * and must be released with ahri_tre_result_free. This helper does not require
 * an ahri_tre_client handle, and no client, session, or result cleanup function
 * stops the shared runtime.
 *
 * Stop sends a best-effort private shutdown request to the local daemon. If the
 * runtime is already absent or the configured endpoint is unavailable, it
 * returns a successful not-running lifecycle result rather than an ABI boundary
 * error. Lifecycle JSON reports stopped, already-not-running, stale socket,
 * invalid socket state, shutdown refusal, shutdown failure, and timeout
 * outcomes through stable top-level schema, schema_version, kind, status,
 * action, message, and diagnostics fields.
 */
ahri_tre_status ahri_tre_runtime_stop(
    const ahri_tre_runtime_config *config,
    ahri_tre_result **out_result);

/*
 * Returns a static diagnostic string for an ABI status value.
 *
 * The returned pointer is owned by the library and must not be freed. Messages
 * describe only status classes; they do not include request bodies, token or
 * password values, auth artifacts, local paths, lake internals, or handle
 * addresses.
 */
const char *ahri_tre_status_message(ahri_tre_status status);

/*
 * Creates an opaque client handle that owns ABI-side adapter state only.
 *
 * config may be NULL to use the default deferred-transport configuration.
 * out_client must be non-NULL. On failure, out_client is set to NULL when
 * possible.
 *
 * Client configuration does not carry local daemon endpoints, daemon binaries,
 * PostgreSQL, DuckDB, DuckLake, OAuth, OIDC, session, lake, or runtime handles.
 */
ahri_tre_status ahri_tre_client_create(
    const ahri_tre_client_config *config,
    ahri_tre_client **out_client);

/*
 * Creates an opaque client handle with separate managed-runtime policy.
 *
 * client_config may be NULL to use the default protocol-client adapter state.
 * runtime_config may be NULL to use default managed auto-start/reuse behavior.
 * A non-NULL runtime_config carries endpoint-only and never-start opt-outs
 * without placing lifecycle policy on ahri_tre_client_config.
 */
ahri_tre_status ahri_tre_client_create_with_runtime_config(
    const ahri_tre_client_config *client_config,
    const ahri_tre_runtime_config *runtime_config,
    ahri_tre_client **out_client);

/*
 * Frees a client returned by ahri_tre_client_create. Passing NULL is a no-op.
 * This releases the client handle only; it does not stop a shared managed
 * runtime.
 *
 * Passing a foreign pointer, freeing the same pointer twice, or mutating/freeing
 * the same handle concurrently is a caller error and has undefined behavior.
 */
void ahri_tre_client_free(ahri_tre_client *client);

/*
 * Executes one serialized stable protocol request envelope.
 *
 * client must be a live handle returned by ahri_tre_client_create.
 * request_json must point to request_json_len readable bytes containing a JSON
 * protocol request envelope. out_result must be non-NULL.
 *
 * When this function returns AHRI_TRE_STATUS_OK, out_result owns a protocol
 * response envelope result for both protocol success and protocol failure. With
 * default runtime policy, execution ensures or reuses the managed local runtime
 * and forwards the request to that daemon. When runtime config supplies an
 * explicit endpoint, execution is forwarded to that endpoint without starting a
 * replacement. The ABI status channel is reserved for unsafe-boundary failures:
 * NULL pointers, non-live handles, invalid UTF-8 before protocol parsing, and
 * ABI-side allocation failure. Workflow, validation, unsupported operation,
 * managed-runtime startup/readiness, runtime unavailable under explicit
 * never-start policy, daemon transport, and other protocol-level failures are
 * returned in the result JSON envelope whenever a protocol-shaped response can
 * be produced.
 *
 * Passing a foreign pointer, freeing the same pointer twice, or mutating/freeing
 * the same handle concurrently is a caller error.
 */
ahri_tre_status ahri_tre_client_execute_protocol_json(
    ahri_tre_client *client,
    const uint8_t *request_json,
    size_t request_json_len,
    ahri_tre_result **out_result);

/*
 * Selects a session using one serialized stable protocol request envelope.
 *
 * request_json must be a session.use protocol envelope. On protocol-shaped
 * failures, this function returns AHRI_TRE_STATUS_OK, out_session remains NULL,
 * and out_result owns the failure response envelope. On success, out_session
 * owns an opaque selected-session context and out_result owns the session.use
 * success response envelope.
 *
 * The session handle identifies selected session context only. It never exposes
 * daemon internals, raw datastore handles, OAuth/OIDC handles, DuckDB/DuckLake
 * handles, lake handles, credentials, or paths.
 *
 * Passing a foreign pointer, closing/freeing the same pointer twice, or using
 * the same client/session/result handle concurrently is a caller error.
 */
ahri_tre_status ahri_tre_client_select_session_protocol_json(
    ahri_tre_client *client,
    const uint8_t *request_json,
    size_t request_json_len,
    ahri_tre_session **out_session,
    ahri_tre_result **out_result);

/*
 * Executes one serialized stable protocol request envelope through a selected
 * session handle.
 *
 * session must be a live handle returned by
 * ahri_tre_client_select_session_protocol_json. request_json must point to
 * request_json_len readable bytes containing a JSON protocol request envelope.
 * out_result must be non-NULL.
 *
 * The selected session context is applied to the protocol request body before
 * execution for request kinds that carry session context. Workflow semantics
 * remain in the protocol envelope; this ABI layer does not add typed workflow
 * functions.
 *
 * Passing a closed/foreign session handle returns
 * AHRI_TRE_STATUS_INVALID_HANDLE. Passing a foreign pointer, closing/freeing
 * the same pointer twice, or using the same handle concurrently is a caller
 * error unless a future ABI symbol explicitly documents otherwise.
 */
ahri_tre_status ahri_tre_session_execute_protocol_json(
    ahri_tre_session *session,
    const uint8_t *request_json,
    size_t request_json_len,
    ahri_tre_result **out_result);

/*
 * Closes and invalidates a selected session handle. Passing NULL is a no-op.
 * Later status-returning use of the same closed handle fails with
 * AHRI_TRE_STATUS_INVALID_HANDLE.
 *
 * Same-handle concurrent use or concurrent close is invalid in this first
 * stable ABI surface unless a future symbol explicitly promises otherwise.
 */
ahri_tre_status ahri_tre_session_close(ahri_tre_session *session);

/*
 * Returns a borrowed NUL-terminated JSON response envelope string.
 *
 * The returned pointer is owned by result and remains valid until
 * ahri_tre_result_free(result). Passing NULL or a non-live result handle returns
 * NULL.
 */
const char *ahri_tre_result_response_json_borrowed(
    const ahri_tre_result *result);

/*
 * Returns the byte length of the borrowed response JSON string, excluding the
 * trailing NUL byte. Passing NULL or a non-live result handle returns 0.
 */
size_t ahri_tre_result_response_json_len(const ahri_tre_result *result);

/*
 * Copies the response JSON into a caller-owned NUL-terminated string.
 *
 * out_response_json must be non-NULL. On success, the caller owns the returned
 * string and must release it with ahri_tre_string_free. On failure,
 * out_response_json is set to NULL when possible. Protocol-level failures are
 * still copied as normal response JSON; only unsafe-boundary failures use the
 * ABI status channel.
 */
ahri_tre_status ahri_tre_result_response_json_copy(
    const ahri_tre_result *result,
    char **out_response_json);

/*
 * Returns the number of payloads attached to a result handle.
 *
 * A result with no attached binary or artifact payloads returns 0. Passing NULL
 * or a non-live result handle also returns 0; status-returning descriptor/byte
 * accessors should be used when callers need to distinguish invalid handles
 * from normal absence.
 */
size_t ahri_tre_result_payload_count(const ahri_tre_result *result);

/*
 * Returns a borrowed descriptor for one attached payload.
 *
 * out_descriptor must be non-NULL. On success, descriptor string pointers are
 * owned by result and remain valid until ahri_tre_result_free(result). If
 * payload_index is out of range, this returns AHRI_TRE_STATUS_OK and fills a
 * descriptor with AHRI_TRE_PAYLOAD_KIND_NONE, NULL strings, and zero size.
 *
 * Descriptors expose protocol refs, media types, suggested names, sizes, and
 * byte-availability flags. They must not expose runtime lake paths, datastore
 * connection details, credentials, or local temporary paths.
 */
ahri_tre_status ahri_tre_result_payload_descriptor(
    const ahri_tre_result *result,
    size_t payload_index,
    ahri_tre_payload_descriptor *out_descriptor);

/*
 * Returns a borrowed byte view for one attached payload.
 *
 * out_bytes must be non-NULL. On success, non-NULL bytes are owned by result and
 * remain valid until ahri_tre_result_free(result). Descriptor-only payloads and
 * out-of-range payload_index values return AHRI_TRE_STATUS_OK with data=NULL
 * and len=0.
 */
ahri_tre_status ahri_tre_result_payload_bytes_borrowed(
    const ahri_tre_result *result,
    size_t payload_index,
    ahri_tre_byte_view *out_bytes);

/*
 * Copies attached payload bytes into a caller-owned buffer.
 *
 * out_bytes and out_bytes_len must be non-NULL. On success with attached bytes,
 * the caller owns *out_bytes and must release it with ahri_tre_bytes_free using
 * the exact returned length. Descriptor-only payloads and out-of-range
 * payload_index values return AHRI_TRE_STATUS_OK with *out_bytes=NULL and
 * *out_bytes_len=0.
 */
ahri_tre_status ahri_tre_result_payload_bytes_copy(
    const ahri_tre_result *result,
    size_t payload_index,
    uint8_t **out_bytes,
    size_t *out_bytes_len);

/*
 * Frees a result returned by ahri_tre_client_execute_protocol_json. Passing NULL
 * is a no-op. Passing a foreign pointer, freeing the same pointer twice, or
 * mutating/freeing the same handle concurrently is undefined.
 */
void ahri_tre_result_free(ahri_tre_result *result);

/*
 * Frees strings returned by AHRI TRE FFI functions. Passing NULL is a no-op.
 * Passing a foreign pointer or freeing the same pointer twice is undefined.
 */
void ahri_tre_string_free(char *ptr);

/*
 * Frees byte buffers returned by AHRI TRE FFI payload copy functions. Passing
 * NULL is a no-op. Non-NULL pointers must be paired with the exact returned
 * length from the copy function that allocated them.
 */
void ahri_tre_bytes_free(uint8_t *ptr, size_t len);

#ifdef __cplusplus
}
#endif

#endif
