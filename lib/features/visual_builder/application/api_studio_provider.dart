// lib/features/visual_builder/application/api_studio_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/api_config.dart';

class ApiCollectionsNotifier extends StateNotifier<List<ApiCollection>> {
  ApiCollectionsNotifier() : super([
    ApiCollection(
      id: 'coll_auth',
      name: 'Authentication',
      description: 'Endpoints for user sign in, registration, and sessions',
      baseUrl: 'https://api.revochamp.com',
      headers: {'Content-Type': 'application/json'},
      authentication: 'None',
    ),
    ApiCollection(
      id: 'coll_users',
      name: 'Users',
      description: 'Operations related to user profiles and details',
      baseUrl: 'https://api.revochamp.com',
      authentication: 'Bearer Token',
      authPassword: '{{accessToken}}',
    ),
    ApiCollection(
      id: 'coll_products',
      name: 'Products',
      description: 'Product catalog query endpoints',
      baseUrl: 'https://api.revochamp.com',
      authentication: 'API Key',
      apiKeyName: 'X-API-Key',
      apiKeyValue: 'prod_api_key_xyz_123',
    ),
  ]);

  void addCollection(ApiCollection collection) {
    state = [...state, collection];
  }

  void updateCollection(String id, ApiCollection updated) {
    state = state.map((c) => c.id == id ? updated : c).toList();
  }

  void deleteCollection(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final apiCollectionsProvider = StateNotifierProvider<ApiCollectionsNotifier, List<ApiCollection>>((ref) {
  return ApiCollectionsNotifier();
});

// API Config notifier
class ApiConfigsNotifier extends StateNotifier<List<ApiConfig>> {
  ApiConfigsNotifier() : super([
    ApiConfig(
      id: 'api_login',
      name: 'User Login API',
      baseUrl: '',
      endpoint: '/v1/auth/login',
      method: 'POST',
      headers: {},
      queryParams: {},
      requestBody: '{"email": "", "password": ""}',
      authentication: 'Inherit',
      responseMapping: {'token': 'sessionToken'},
      collectionId: 'coll_auth',
      inheritParentSettings: true,
    ),
    ApiConfig(
      id: 'api_get_profile',
      name: 'Get User Profile',
      baseUrl: '',
      endpoint: '/v1/users/profile',
      method: 'GET',
      headers: {},
      queryParams: {},
      requestBody: '',
      authentication: 'Inherit',
      responseMapping: {'name': 'userName'},
      collectionId: 'coll_users',
      inheritParentSettings: true,
    ),
  ]);

  void addConfig(ApiConfig config) {
    state = [...state, config];
  }

  void updateConfig(String id, ApiConfig updated) {
    state = state.map((c) => c.id == id ? updated : c).toList();
  }

  void deleteConfig(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final apiConfigsProvider = StateNotifierProvider<ApiConfigsNotifier, List<ApiConfig>>((ref) {
  return ApiConfigsNotifier();
});

class EnvVariablesNotifier extends StateNotifier<Map<String, Map<String, String>>> {
  EnvVariablesNotifier() : super({
    'DEV': {
      'baseUrl': 'https://api-dev.revochamp.com',
      'accessToken': 'dev_token_abc123',
      'tenantId': 'tenant_dev_99',
    },
    'UAT': {
      'baseUrl': 'https://api-uat.revochamp.com',
      'accessToken': 'uat_token_xyz789',
      'tenantId': 'tenant_uat_44',
    },
    'PROD': {
      'baseUrl': 'https://api.revochamp.com',
      'accessToken': 'prod_token_sec007',
      'tenantId': 'tenant_prod_11',
    },
    'LOCAL': {
      'baseUrl': 'http://localhost:8080',
      'accessToken': 'local_token_debug',
      'tenantId': 'tenant_local_00',
    },
  });

  void updateVariable(String env, String key, String value) {
    final envMap = Map<String, String>.from(state[env] ?? {});
    envMap[key] = value;
    state = {
      ...state,
      env: envMap,
    };
  }

  void addVariable(String key) {
    state = state.map((env, vars) {
      final newVars = Map<String, String>.from(vars);
      newVars[key] = 'value';
      return MapEntry(env, newVars);
    });
  }

  void removeVariable(String key) {
    state = state.map((env, vars) {
      final newVars = Map<String, String>.from(vars);
      newVars.remove(key);
      return MapEntry(env, newVars);
    });
  }
}

final activeEnvironmentProvider = StateProvider<String>((ref) => 'DEV');
final envVariablesProvider = StateNotifierProvider<EnvVariablesNotifier, Map<String, Map<String, String>>>((ref) {
  return EnvVariablesNotifier();
});

class ApiTestState {
  final bool isTesting;
  final int? responseStatus;
  final String? responseBody;
  final String? testError;

  const ApiTestState({
    this.isTesting = false,
    this.responseStatus,
    this.responseBody,
    this.testError,
  });

  ApiTestState copyWith({
    bool? isTesting,
    int? responseStatus,
    String? responseBody,
    String? testError,
  }) {
    return ApiTestState(
      isTesting: isTesting ?? this.isTesting,
      responseStatus: responseStatus ?? this.responseStatus,
      responseBody: responseBody ?? this.responseBody,
      testError: testError ?? this.testError,
    );
  }
}

final apiTestStateProvider = StateProvider<ApiTestState>((ref) => const ApiTestState());
