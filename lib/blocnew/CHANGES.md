# Revochamp Generator v3 — Complete Fix & Enhancement Notes

## Root Cause Fixes

### Fix 1 — `NewWorkHomeResult` is not a type / undefined method
**Error:**
```
The name 'NewWorkHomeResult' isn't a type, so it can't be used as a type argument.
```
**Root cause:**  
`NewWorkHomeResult` was defined *inside* `new_work_home_usecases.dart`.  
`new_work_home_repository.dart` referenced it **without importing** that file.  
`new_work_home_repository_impl.dart` had the same missing import.  
A circular import would result if either file imported usecases.dart.

**Fix:**  
Created a dedicated `*_result.dart` file per feature:
```
domain/
  result/
    new_work_home_result.dart   ← NewWorkHomeResult lives HERE
```
Both `*_repository.dart` and `*_repository_impl.dart` now import from
`../result/new_work_home_result.dart`.  
`*_usecases.dart` does too — no more circular dependency.

---

### Fix 2 — `toJson` isn't defined for `NewWorkHomeEntity`
**Error:**
```
The method 'toJson' isn't defined for the type 'NewWorkHomeEntity'.
```
**Root cause:**  
`FeatureEntityGenerator` emitted `fromJson()` but never emitted `toJson()`.  
`RepositoryImplGenerator` called `entity.toJson()` in `_toPayload()`.

**Fix:**  
`feature_entity_generator.dart` now generates:
```dart
Map<String, dynamic> toJson() => {
  'field_name': fieldName,
  'category_id': category?.id,   // dropdown → emits ID only
  ...
};
```
Field-type-aware: dropdown fields emit their value key (e.g. `id`),
checkboxes emit `bool`, numbers emit raw numeric.

---

### Fix 3 — Raw `http.Client` replaced with `DioClient`
**Before:** `DataSourceGenerator` used `package:http` with manual
`jsonEncode`/`jsonDecode` and inline HTTP error checks.  
**After:** `DioClient` wraps Dio with:
- `AuthInterceptor` — attaches Bearer token from SharedPreferences
- `LoggingInterceptor` — debug-only request/response logs
- `ErrorInterceptor` — 401 hook for token refresh / logout
- `ApiResponse<T>` sealed class — `ApiSuccess` / `ApiFailure`
- Typed `get<T>`, `post<T>`, `put<T>`, `patch<T>`, `delete<T>` methods

---

### Fix 4 — Inconsistent exception handling
**Before:** each repository method had three separate `catch` branches
with hardcoded string codes.  
**After:** `failure_mapper.dart` provides a single `mapExceptionToFailure(e)`
function that converts `AppException` subclasses to typed `Failure` objects
with correct `retryable` flags and `statusCode`.

**AppException hierarchy:**
```
AppException (sealed)
  ├── ServerException   (4xx / 5xx, carries statusCode + field errors)
  ├── NetworkException  (no connectivity)
  ├── TimeoutException  (connect / read timeout)
  ├── ParseException    (bad JSON)
  └── UnknownException  (catch-all)
```

---

### Fix 5 — No local storage support
**New:** `LocalStorageService` wraps `SharedPreferences` with:
- `setJson` / `getJson` — typed JSON round-trip
- `setJsonList` / `getJsonList`
- `cacheList(key, list)` — stores list + timestamp
- `getCachedList(key, ttlSeconds)` — TTL-aware cache read
- Wired into datasource when `FieldSchema.isLocalStorageEnabled = true`
  or `FieldSchema.cacheKey` is set

---

## New Files Generated

### Core network (once per project)
| File | Purpose |
|------|---------|
| `core/network/app_exception.dart` | Exception hierarchy |
| `core/network/api_response.dart` | `ApiSuccess<T>` / `ApiFailure<T>` |
| `core/network/dio_client.dart` | Dio wrapper with typed helpers |
| `core/network/failure_mapper.dart` | Exception → Failure converter |
| `core/network/interceptors/auth_interceptor.dart` | Bearer token |
| `core/network/interceptors/logging_interceptor.dart` | Debug logs |
| `core/network/interceptors/error_interceptor.dart` | 401 hook |

### Core storage (once per project)
| File | Purpose |
|------|---------|
| `core/storage/local_storage_service.dart` | SharedPreferences wrapper with TTL cache |

### Core runtime (improved)
| File | Change |
|------|--------|
| `core/runtime/failure.dart` | **New** — moved out of async_state, now has `statusCode` |
| `core/runtime/async_state.dart` | Imports from failure.dart, added `when()` helper |

### Core widgets (new — once per project)
| Widget | Purpose |
|--------|---------|
| `FormFieldWrapper` | Label + error row container |
| `AppTextField` | text / email / phone / password / textarea |
| `AppDropdownField<T>` | Static options dropdown |
| `AppAsyncDropdownField<T>` | Async dropdown with loading shimmer + retry |
| `AppCheckboxField` | Checkbox with label and error |
| `AppFormButton` | Submit button with idle / loading / disabled states |
| `AppErrorWidget` | Full-page or compact error with retry |
| `AppLoadingWidget` | Spinner with optional message |
| `widgets.dart` | Barrel export |

### Per-feature (new file)
| File | Purpose |
|------|---------|
| `domain/result/*_result.dart` | **New** — `XxxResult` value object, breaks circular import |

---

## File Structure After v3

```
lib/bloc/
├── core/
│   ├── network/
│   │   ├── app_exception.dart
│   │   ├── api_response.dart
│   │   ├── dio_client.dart
│   │   ├── failure_mapper.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       ├── logging_interceptor.dart
│   │       └── error_interceptor.dart
│   ├── runtime/
│   │   ├── failure.dart          ← NEW standalone file
│   │   ├── async_state.dart
│   │   ├── validation_error.dart
│   │   ├── validator.dart
│   │   ├── reactive_value.dart
│   │   └── base_reactive_bloc.dart
│   ├── storage/
│   │   └── local_storage_service.dart
│   ├── observer/
│   │   └── bloc_observer.dart
│   └── widgets/
│       ├── form_field_wrapper.dart
│       ├── app_text_field.dart
│       ├── app_dropdown_field.dart
│       ├── app_async_dropdown_field.dart
│       ├── app_checkbox_field.dart
│       ├── app_form_button.dart
│       ├── app_error_widget.dart
│       ├── app_loading_widget.dart
│       └── widgets.dart
├── features/
│   └── {baseName}/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── {snake}_entity.dart       ← FIX: has toJson()
│       │   │   └── {dropdown}_entity.dart
│       │   ├── result/
│       │   │   └── {snake}_result.dart       ← NEW: Result lives here
│       │   ├── repositories/
│       │   │   └── {snake}_repository.dart   ← FIX: imports result
│       │   └── usecases/
│       │       └── {snake}_usecases.dart     ← FIX: imports result
│       └── data/
│           ├── model/
│           │   └── {dropdown}_model.dart
│           ├── datasources/
│           │   └── {snake}_datasource.dart   ← FIX: uses DioClient
│           └── repositories/
│               └── {snake}_repository_impl.dart ← FIX: failureMapper
├── injection.dart                            ← FIX: wires Dio + Storage
└── main.dart
```

## pubspec.yaml dependencies needed

```yaml
dependencies:
  flutter_bloc: ^8.1.5
  bloc: ^8.1.4
  dartz: ^0.10.1
  dio: ^5.4.3
  equatable: ^2.0.5
  get_it: ^7.6.7
  shared_preferences: ^2.2.3

dev_dependencies:
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```
