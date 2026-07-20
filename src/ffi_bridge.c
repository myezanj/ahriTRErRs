#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/*
 * Keep dynamic loading logic behind a tiny portability shim so the bridge
 * builds on both POSIX and Windows toolchains.
 */
#ifdef _WIN32
typedef HMODULE tre_lib_handle;

static tre_lib_handle tre_dlopen(const char *path) {
    return LoadLibraryA(path);
}

static void tre_dlclose(tre_lib_handle handle) {
    if (handle != NULL) {
        FreeLibrary(handle);
    }
}

static void *tre_dlsym(tre_lib_handle handle, const char *name) {
    return (void *)GetProcAddress(handle, name);
}
#else
typedef void *tre_lib_handle;

static tre_lib_handle tre_dlopen(const char *path) {
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
}

static void tre_dlclose(tre_lib_handle handle) {
    if (handle != NULL) {
        dlclose(handle);
    }
}

static void *tre_dlsym(tre_lib_handle handle, const char *name) {
    return dlsym(handle, name);
}
#endif

typedef enum ahri_tre_status {
    AHRI_TRE_STATUS_OK = 0,
    AHRI_TRE_STATUS_NULL_POINTER = 1,
    AHRI_TRE_STATUS_INVALID_CONFIG = 2,
    AHRI_TRE_STATUS_UNSUPPORTED_CONFIG = 3,
    AHRI_TRE_STATUS_INVALID_HANDLE = 4,
    AHRI_TRE_STATUS_INVALID_UTF8 = 5,
    AHRI_TRE_STATUS_ALLOCATION_FAILED = 6
} ahri_tre_status;

typedef struct ahri_tre_client ahri_tre_client;
typedef struct ahri_tre_result ahri_tre_result;

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
    int kind;
    uint32_t flags;
    const char *protocol_ref;
    const char *media_type;
    const char *suggested_name;
    size_t size_bytes;
} ahri_tre_payload_descriptor;

#define AHRI_TRE_RUNTIME_CONFIG_FLAGS_NEVER_START 1u

static void ahri_tre_library_finalizer(SEXP external) {
    tre_lib_handle handle = (tre_lib_handle)R_ExternalPtrAddr(external);
    if (handle != NULL) {
        tre_dlclose(handle);
        R_ClearExternalPtr(external);
    }
}

static void ahri_tre_client_finalizer(SEXP external) {
    void *client = R_ExternalPtrAddr(external);
    SEXP tag = R_ExternalPtrTag(external);
    if (client != NULL && TYPEOF(tag) == STRSXP && Rf_length(tag) == 1) {
        /*
         * External pointers only retain the runtime library path in their tag,
         * so finalization re-opens the ABI library to resolve the free symbol.
         */
        const char *path = CHAR(STRING_ELT(tag, 0));
        tre_lib_handle handle = tre_dlopen(path);
        if (handle != NULL) {
            void (*client_free)(ahri_tre_client *) =
                (void (*)(ahri_tre_client *))tre_dlsym(handle, "ahri_tre_client_free");
            if (client_free != NULL) {
                client_free((ahri_tre_client *)client);
            }
            tre_dlclose(handle);
        }
        R_ClearExternalPtr(external);
    }
}

static tre_lib_handle open_library(const char *path) {
    tre_lib_handle handle = tre_dlopen(path);
    if (handle == NULL) {
        Rf_error("failed to load AHRI TRE C ABI library");
    }
    return handle;
}

static void *symbol(tre_lib_handle handle, const char *name) {
    void *ptr = tre_dlsym(handle, name);
    if (ptr == NULL) {
        /*
         * Fail fast when an expected symbol is missing so the caller gets a
         * deterministic error instead of undefined behavior later.
         */
        Rf_error("AHRI TRE C ABI library is missing symbol '%s'", name);
    }
    return ptr;
}

static const char *nullable_string(SEXP value) {
    if (value == R_NilValue || Rf_length(value) == 0) {
        return NULL;
    }
    if (TYPEOF(value) == STRSXP && Rf_length(value) == 1 && STRING_ELT(value, 0) != NA_STRING) {
        return CHAR(STRING_ELT(value, 0));
    }
    return NULL;
}

static SEXP make_status_result(ahri_tre_status status, const char *name, void *ptr) {
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("status"));
    SET_STRING_ELT(names, 1, Rf_mkChar(name));
    SET_VECTOR_ELT(out, 0, Rf_ScalarInteger((int)status));
    SET_VECTOR_ELT(out, 1, R_MakeExternalPtr(ptr, R_NilValue, R_NilValue));
    Rf_setAttrib(out, R_NamesSymbol, names);
    UNPROTECT(2);
    return out;
}

static ahri_tre_runtime_config runtime_config(void *handle, SEXP endpoint, SEXP binary, SEXP timeout, SEXP never_start) {
    ahri_tre_runtime_config (*config_default)(void) =
        (ahri_tre_runtime_config (*)(void))symbol(handle, "ahri_tre_runtime_config_default");
    ahri_tre_runtime_config config = config_default();
    config.daemon_endpoint = nullable_string(endpoint);
    config.daemon_binary = nullable_string(binary);
    config.readiness_timeout_ms = (uint32_t)Rf_asInteger(timeout);
    if (Rf_asLogical(never_start) == TRUE) {
        config.flags |= AHRI_TRE_RUNTIME_CONFIG_FLAGS_NEVER_START;
    }
    return config;
}

SEXP ahri_tre_library_open(SEXP path) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    tre_lib_handle handle = open_library(library_path);
    SEXP external = PROTECT(R_MakeExternalPtr((void *)handle, R_NilValue, R_NilValue));
    R_RegisterCFinalizerEx(external, ahri_tre_library_finalizer, TRUE);
    UNPROTECT(1);
    return external;
}

SEXP ahri_tre_owned_string(SEXP path, SEXP symbol_name) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    const char *name = CHAR(STRING_ELT(symbol_name, 0));
    tre_lib_handle handle = open_library(library_path);
    char *(*func)(void) = (char *(*)(void))symbol(handle, name);
    void (*string_free)(char *) = (void (*)(char *))symbol(handle, "ahri_tre_string_free");
    char *value = func();
    SEXP out = PROTECT(Rf_mkString(value == NULL ? "" : value));
    string_free(value);
    tre_dlclose(handle);
    UNPROTECT(1);
    return out;
}

SEXP ahri_tre_status_message_bridge(SEXP path, SEXP status) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    tre_lib_handle handle = open_library(library_path);
    const char *(*func)(ahri_tre_status) =
        (const char *(*)(ahri_tre_status))symbol(handle, "ahri_tre_status_message");
    const char *message = func((ahri_tre_status)Rf_asInteger(status));
    SEXP out = PROTECT(Rf_mkString(message == NULL ? "" : message));
    tre_dlclose(handle);
    UNPROTECT(1);
    return out;
}

SEXP ahri_tre_result_response_json_bridge(SEXP path, SEXP result_external) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_result *result = (ahri_tre_result *)R_ExternalPtrAddr(result_external);
    tre_lib_handle handle = open_library(library_path);
    const char *(*func)(const ahri_tre_result *) =
        (const char *(*)(const ahri_tre_result *))symbol(handle, "ahri_tre_result_response_json_borrowed");
    const char *json = func(result);
    SEXP out = PROTECT(Rf_mkString(json == NULL ? "" : json));
    tre_dlclose(handle);
    UNPROTECT(1);
    return out;
}

SEXP ahri_tre_result_free_bridge(SEXP path, SEXP result_external) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_result *result = (ahri_tre_result *)R_ExternalPtrAddr(result_external);
    if (result != NULL) {
        tre_lib_handle handle = open_library(library_path);
        void (*func)(ahri_tre_result *) =
            (void (*)(ahri_tre_result *))symbol(handle, "ahri_tre_result_free");
        func(result);
        tre_dlclose(handle);
        R_ClearExternalPtr(result_external);
    }
    return R_NilValue;
}

SEXP ahri_tre_runtime_call_bridge(SEXP path, SEXP action, SEXP endpoint, SEXP binary, SEXP timeout, SEXP never_start) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    const char *action_name = CHAR(STRING_ELT(action, 0));
    tre_lib_handle handle = open_library(library_path);
    ahri_tre_runtime_config config = runtime_config(handle, endpoint, binary, timeout, never_start);
    ahri_tre_result *result = NULL;
    ahri_tre_status (*func)(const ahri_tre_runtime_config *, ahri_tre_result **) = NULL;
    if (strcmp(action_name, "status") == 0) {
        func = (ahri_tre_status (*)(const ahri_tre_runtime_config *, ahri_tre_result **))symbol(handle, "ahri_tre_runtime_status");
    } else if (strcmp(action_name, "discover_daemon_binary") == 0) {
        func = (ahri_tre_status (*)(const ahri_tre_runtime_config *, ahri_tre_result **))symbol(handle, "ahri_tre_runtime_discover_daemon_binary");
    } else if (strcmp(action_name, "ensure") == 0) {
        func = (ahri_tre_status (*)(const ahri_tre_runtime_config *, ahri_tre_result **))symbol(handle, "ahri_tre_runtime_ensure");
    } else if (strcmp(action_name, "stop") == 0) {
        func = (ahri_tre_status (*)(const ahri_tre_runtime_config *, ahri_tre_result **))symbol(handle, "ahri_tre_runtime_stop");
    } else {
        tre_dlclose(handle);
        Rf_error("unknown AHRI TRE runtime action");
    }
    ahri_tre_status status = func(&config, &result);
    tre_dlclose(handle);
    return make_status_result(status, "result", result);
}

SEXP ahri_tre_client_create_bridge(SEXP path, SEXP endpoint, SEXP binary, SEXP timeout, SEXP never_start) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    tre_lib_handle handle = open_library(library_path);
    ahri_tre_client_config (*client_config_default)(void) =
        (ahri_tre_client_config (*)(void))symbol(handle, "ahri_tre_client_config_default");
    ahri_tre_status (*client_create)(const ahri_tre_client_config *, const ahri_tre_runtime_config *, ahri_tre_client **) =
        (ahri_tre_status (*)(const ahri_tre_client_config *, const ahri_tre_runtime_config *, ahri_tre_client **))symbol(handle, "ahri_tre_client_create_with_runtime_config");
    ahri_tre_client_config client_config = client_config_default();
    ahri_tre_runtime_config config = runtime_config(handle, endpoint, binary, timeout, never_start);
    ahri_tre_client *client = NULL;
    ahri_tre_status status = client_create(&client_config, &config, &client);
    tre_dlclose(handle);
    SEXP out = PROTECT(make_status_result(status, "client", client));
    SEXP client_external = VECTOR_ELT(out, 1);
    R_SetExternalPtrTag(client_external, path);
    R_RegisterCFinalizerEx(client_external, ahri_tre_client_finalizer, TRUE);
    UNPROTECT(1);
    return out;
}

SEXP ahri_tre_client_free_bridge(SEXP path, SEXP client_external) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_client *client = (ahri_tre_client *)R_ExternalPtrAddr(client_external);
    if (client != NULL) {
        tre_lib_handle handle = open_library(library_path);
        void (*func)(ahri_tre_client *) =
            (void (*)(ahri_tre_client *))symbol(handle, "ahri_tre_client_free");
        func(client);
        tre_dlclose(handle);
        R_ClearExternalPtr(client_external);
    }
    return R_NilValue;
}

SEXP ahri_tre_client_execute_protocol_json_bridge(SEXP path, SEXP client_external, SEXP request) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_client *client = (ahri_tre_client *)R_ExternalPtrAddr(client_external);
    const uint8_t *data = RAW(request);
    size_t len = (size_t)Rf_length(request);
    tre_lib_handle handle = open_library(library_path);
    ahri_tre_status (*func)(ahri_tre_client *, const uint8_t *, size_t, ahri_tre_result **) =
        (ahri_tre_status (*)(ahri_tre_client *, const uint8_t *, size_t, ahri_tre_result **))symbol(handle, "ahri_tre_client_execute_protocol_json");
    ahri_tre_result *result = NULL;
    ahri_tre_status status = func(client, data, len, &result);
    tre_dlclose(handle);
    return make_status_result(status, "result", result);
}

SEXP ahri_tre_result_payload_count_bridge(SEXP path, SEXP result_external) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_result *result = (ahri_tre_result *)R_ExternalPtrAddr(result_external);
    tre_lib_handle handle = open_library(library_path);
    size_t (*func)(const ahri_tre_result *) =
        (size_t (*)(const ahri_tre_result *))symbol(handle, "ahri_tre_result_payload_count");
    size_t count = func(result);
    tre_dlclose(handle);
    return Rf_ScalarInteger((int)count);
}

SEXP ahri_tre_result_payload_descriptor_bridge(SEXP path, SEXP result_external, SEXP index) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_result *result = (ahri_tre_result *)R_ExternalPtrAddr(result_external);
    tre_lib_handle handle = open_library(library_path);
    ahri_tre_status (*func)(const ahri_tre_result *, size_t, ahri_tre_payload_descriptor *) =
        (ahri_tre_status (*)(const ahri_tre_result *, size_t, ahri_tre_payload_descriptor *))symbol(handle, "ahri_tre_result_payload_descriptor");
    ahri_tre_payload_descriptor descriptor;
    memset(&descriptor, 0, sizeof(descriptor));
    descriptor.struct_size = sizeof(descriptor);
    ahri_tre_status status = func(result, (size_t)Rf_asInteger(index), &descriptor);
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 7));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, 7));
    const char *field_names[] = {"status", "kind", "flags", "protocol_ref", "media_type", "suggested_name", "size_bytes"};
    for (int i = 0; i < 7; i++) {
        SET_STRING_ELT(names, i, Rf_mkChar(field_names[i]));
    }
    SET_VECTOR_ELT(out, 0, Rf_ScalarInteger((int)status));
    SET_VECTOR_ELT(out, 1, Rf_ScalarInteger(descriptor.kind));
    SET_VECTOR_ELT(out, 2, Rf_ScalarInteger((int)descriptor.flags));
    SET_VECTOR_ELT(out, 3, descriptor.protocol_ref == NULL ? R_NilValue : Rf_mkString(descriptor.protocol_ref));
    SET_VECTOR_ELT(out, 4, descriptor.media_type == NULL ? R_NilValue : Rf_mkString(descriptor.media_type));
    SET_VECTOR_ELT(out, 5, descriptor.suggested_name == NULL ? R_NilValue : Rf_mkString(descriptor.suggested_name));
    SET_VECTOR_ELT(out, 6, Rf_ScalarReal((double)descriptor.size_bytes));
    Rf_setAttrib(out, R_NamesSymbol, names);
    tre_dlclose(handle);
    UNPROTECT(2);
    return out;
}

SEXP ahri_tre_result_payload_bytes_bridge(SEXP path, SEXP result_external, SEXP index) {
    const char *library_path = CHAR(STRING_ELT(path, 0));
    ahri_tre_result *result = (ahri_tre_result *)R_ExternalPtrAddr(result_external);
    tre_lib_handle handle = open_library(library_path);
    ahri_tre_status (*func)(const ahri_tre_result *, size_t, ahri_tre_byte_view *) =
        (ahri_tre_status (*)(const ahri_tre_result *, size_t, ahri_tre_byte_view *))symbol(handle, "ahri_tre_result_payload_bytes_borrowed");
    ahri_tre_byte_view view;
    memset(&view, 0, sizeof(view));
    ahri_tre_status status = func(result, (size_t)Rf_asInteger(index), &view);
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("status"));
    SET_STRING_ELT(names, 1, Rf_mkChar("data"));
    SET_VECTOR_ELT(out, 0, Rf_ScalarInteger((int)status));
    if (view.data == NULL || view.len == 0) {
        SET_VECTOR_ELT(out, 1, R_NilValue);
    } else {
        SEXP raw = PROTECT(Rf_allocVector(RAWSXP, (R_xlen_t)view.len));
        memcpy(RAW(raw), view.data, view.len);
        SET_VECTOR_ELT(out, 1, raw);
        UNPROTECT(1);
    }
    Rf_setAttrib(out, R_NamesSymbol, names);
    tre_dlclose(handle);
    UNPROTECT(2);
    return out;
}

static const R_CallMethodDef call_methods[] = {
    {"ahri_tre_library_open", (DL_FUNC)&ahri_tre_library_open, 1},
    {"ahri_tre_owned_string", (DL_FUNC)&ahri_tre_owned_string, 2},
    {"ahri_tre_status_message_bridge", (DL_FUNC)&ahri_tre_status_message_bridge, 2},
    {"ahri_tre_result_response_json_bridge", (DL_FUNC)&ahri_tre_result_response_json_bridge, 2},
    {"ahri_tre_result_free_bridge", (DL_FUNC)&ahri_tre_result_free_bridge, 2},
    {"ahri_tre_runtime_call_bridge", (DL_FUNC)&ahri_tre_runtime_call_bridge, 6},
    {"ahri_tre_client_create_bridge", (DL_FUNC)&ahri_tre_client_create_bridge, 5},
    {"ahri_tre_client_free_bridge", (DL_FUNC)&ahri_tre_client_free_bridge, 2},
    {"ahri_tre_client_execute_protocol_json_bridge", (DL_FUNC)&ahri_tre_client_execute_protocol_json_bridge, 3},
    {"ahri_tre_result_payload_count_bridge", (DL_FUNC)&ahri_tre_result_payload_count_bridge, 2},
    {"ahri_tre_result_payload_descriptor_bridge", (DL_FUNC)&ahri_tre_result_payload_descriptor_bridge, 3},
    {"ahri_tre_result_payload_bytes_bridge", (DL_FUNC)&ahri_tre_result_payload_bytes_bridge, 3},
    {NULL, NULL, 0}
};

void R_init_ahriTRErRs(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
