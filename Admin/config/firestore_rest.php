<?php
require __DIR__ . '/../vendor/autoload.php';

use Google\Auth\Credentials\ServiceAccountCredentials;
use GuzzleHttp\Client;

/**
 * Returns: [$httpClient, $accessToken, $projectId]
 */
function firestore_client(): array {
    $serviceAccountPath = __DIR__ . '/serviceAccountKey.json';
    if (!file_exists($serviceAccountPath)) {
        throw new Exception("Service account key missing: $serviceAccountPath");
    }

    $json = json_decode(file_get_contents($serviceAccountPath), true);
    $projectId = $json['project_id'] ?? null;
    if (!$projectId) throw new Exception("project_id missing in service account json");

    $scopes = ['https://www.googleapis.com/auth/datastore'];
    $creds  = new ServiceAccountCredentials($scopes, $serviceAccountPath);
    $token  = $creds->fetchAuthToken();

    if (!isset($token['access_token'])) {
        throw new Exception("Could not fetch access token");
    }

    $http = new Client([
        'base_uri' => "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/",
        'timeout'  => 20,
    ]);

    return [$http, $token['access_token'], $projectId];
}

/**
 * Helper: create a Firestore REST Timestamp Value using current UTC time.
 * Use in your endpoint code: 'createdAt' => fs_timestamp_now()
 */
function fs_timestamp_now(): array {
    return ['timestampValue' => gmdate('c')];
}


/**
 * Helper: create a Firestore REST Timestamp Value from a DateTime (or parsable string).
 */
function fs_timestamp($dt): array {
    if ($dt instanceof DateTimeInterface) {
        // Always serialize to UTC ISO-8601
        $utc = (new DateTimeImmutable($dt->format('c')))->setTimezone(new DateTimeZone('UTC'));
        return ['timestampValue' => $utc->format('c')];
    }
    // If string passed, try parse; otherwise assume it is already RFC3339
    $parsed = date_create($dt);
    if ($parsed) {
        $utc = (new DateTimeImmutable($parsed->format('c')))->setTimezone(new DateTimeZone('UTC'));
        return ['timestampValue' => $utc->format('c')];
    }
    return ['timestampValue' => (string)$dt];
}

/**
 * Detect if an array is already a Firestore REST "Value" object.
 * If yes, return as-is from firestore_pack_value to avoid double-wrapping.
 */
function firestore_is_raw_value_array($v): bool {
    if (!is_array($v)) return false;

    $knownKeys = [
        'nullValue', 'booleanValue', 'integerValue', 'doubleValue', 'stringValue',
        'timestampValue', 'bytesValue', 'referenceValue', 'geoPointValue',
        'arrayValue', 'mapValue'
    ];

    foreach ($knownKeys as $k) {
        if (array_key_exists($k, $v)) return true;
    }
    return false;
}

/**
 * Convert PHP value -> Firestore REST Value
 */
function firestore_pack_value($v): array {
    // ✅ If caller already provided a Firestore REST Value object, pass through unchanged.
    if (firestore_is_raw_value_array($v)) return $v;

    // ✅ Support DateTime directly
    if ($v instanceof DateTimeInterface) {
        $utc = (new DateTimeImmutable($v->format('c')))->setTimezone(new DateTimeZone('UTC'));
        return ['timestampValue' => $utc->format('c')];
    }

    if (is_string($v)) return ['stringValue' => $v];
    if (is_bool($v))   return ['booleanValue' => $v];
    if (is_int($v))    return ['integerValue' => (string)$v];
    if (is_float($v))  return ['doubleValue' => $v];
    if ($v === null)   return ['nullValue' => null];

    // Numeric arrays -> arrayValue
    if (is_array($v) && array_is_list($v)) {
        $values = [];
        foreach ($v as $item) $values[] = firestore_pack_value($item);
        return ['arrayValue' => ['values' => $values]];
    }

    // Assoc arrays -> mapValue
    if (is_array($v)) {
        $fields = [];
        foreach ($v as $k => $vv) $fields[$k] = firestore_pack_value($vv);
        return ['mapValue' => ['fields' => $fields]];
    }

    // Fallback
    return ['stringValue' => (string)$v];
}

/**
 * Firestore REST Value -> PHP value
 */
function firestore_unpack_value(array $v) {
    if (isset($v['stringValue']))    return $v['stringValue'];
    if (isset($v['booleanValue']))   return (bool)$v['booleanValue'];
    if (isset($v['integerValue']))   return (int)$v['integerValue'];
    if (isset($v['doubleValue']))    return (float)$v['doubleValue'];
    if (isset($v['timestampValue'])) return $v['timestampValue']; // you can keep as string or parse later
    if (isset($v['nullValue']))      return null;

    if (isset($v['mapValue']['fields'])) {
        return firestore_unpack_fields($v['mapValue']['fields']);
    }

    if (isset($v['arrayValue']['values'])) {
        $arr = [];
        foreach ($v['arrayValue']['values'] as $vv) $arr[] = firestore_unpack_value($vv);
        return $arr;
    }

    return $v; // fallback raw
}

function firestore_unpack_fields(array $fields): array {
    $out = [];
    foreach ($fields as $k => $v) $out[$k] = firestore_unpack_value($v);
    return $out;
}

/**
 * PATCH helper (partial update by field mask)
 * $docPath example: "users/abc123"
 */
if (!function_exists('firestore_patch')) {
  function firestore_patch(string $docPath, array $fields): array {
    [$http, $token, $projectId] = firestore_client();

    $fsFields = [];
    foreach ($fields as $k => $v) {
      $fsFields[$k] = firestore_pack_value($v);
    }

    $res = $http->patch($docPath, [
      'headers' => [
        'Authorization' => "Bearer $token",
        'Content-Type'  => 'application/json',
      ],
      'json' => ['fields' => $fsFields],
    ]);

    return json_decode((string)$res->getBody(), true);
  }
}

/**
 * Run query - supports:
 * 1) firestore_runQuery($structuredQueryArray)
 * 2) firestore_runQuery('collectionName', $structuredQueryArray) (legacy)
 */
function firestore_runQuery($arg1, $arg2 = null): array {
    if (is_array($arg1) && $arg2 === null) {
        $structuredQuery = $arg1;
    } elseif (is_string($arg1) && is_array($arg2)) {
        $structuredQuery = $arg2;
    } else {
        throw new InvalidArgumentException('firestore_runQuery() expects (array) or (string, array).');
    }

    [$http, $accessToken, $projectId] = firestore_client();

    $res = $http->post(":runQuery", [
        'headers' => [
            'Authorization' => "Bearer $accessToken",
            'Content-Type'  => 'application/json',
        ],
        'json' => [
            'structuredQuery' => $structuredQuery
        ],
    ]);

    return json_decode((string)$res->getBody(), true);
}

/**
 * Run query with parent path (for subcollections)
 * $parentPath example: "services/svc_library_print" (document path)
 */
function firestore_runQueryWithParent(string $parentPath, array $structuredQuery): array {
    [$http, $accessToken, $projectId] = firestore_client();

    $endpoint = $parentPath === ''
        ? ':runQuery'
        : rtrim($parentPath, '/') . ':runQuery';

    $res = $http->post($endpoint, [
        'headers' => [
            'Authorization' => "Bearer $accessToken",
            'Content-Type'  => 'application/json',
        ],
        'json' => [
            'structuredQuery' => $structuredQuery
        ],
    ]);

    return json_decode((string)$res->getBody(), true);
}

/**
 * Create document in a collection (auto-id)
 * $collectionId example: "users"
 */
function firestore_createDocument(string $collectionId, array $fields): array {
    [$http, $accessToken, $projectId] = firestore_client();

    $fsFields = [];
    foreach ($fields as $k => $v) $fsFields[$k] = firestore_pack_value($v);

    $res = $http->post($collectionId, [
        'headers' => [
            'Authorization' => "Bearer $accessToken",
            'Content-Type'  => 'application/json',
        ],
        'json' => ['fields' => $fsFields],
    ]);

    return json_decode((string)$res->getBody(), true);
}

/**
 * Get document as unpacked PHP array + _name
 * $docPath example: "users/abc123"
 */
function firestore_getDocument(string $docPath): ?array {
    [$http, $accessToken, $projectId] = firestore_client();

    try {
        $res = $http->get($docPath, [
            'headers' => ['Authorization' => "Bearer $accessToken"]
        ]);

        $json = json_decode((string)$res->getBody(), true);
        if (empty($json['fields'])) return null;

        return firestore_unpack_fields($json['fields']) + [
            '_name' => $json['name'] ?? null
        ];
    } catch (\Exception $e) {
        return null;
    }
}

/**
 * Set (replace fields) by PATCHing all fields provided
 * $docPath example: "users/abc123"
 */
function firestore_setDocument(string $docPath, array $fields): array {
    return firestore_updateDocument($docPath, $fields);
}

/**
 * Partial update (PATCH)
 */
if (!function_exists('firestore_updateDocument')) {
  function firestore_updateDocument(string $docPath, array $fields): array {
    [$http, $accessToken, $projectId] = firestore_client();

    $fsFields = [];
    $query = [];

    foreach ($fields as $k => $v) {
      $fsFields[$k] = firestore_pack_value($v);
      $query[] = 'updateMask.fieldPaths=' . rawurlencode($k);
    }

    // IMPORTANT: This makes Firestore update only these fields instead of replacing the doc
    $url = $docPath . (str_contains($docPath, '?') ? '&' : '?') . implode('&', $query);

    $res = $http->patch($url, [
      'headers' => [
        'Authorization' => "Bearer $accessToken",
        'Content-Type'  => 'application/json',
      ],
      'json' => ['fields' => $fsFields],
    ]);

    return json_decode((string)$res->getBody(), true);
  }
}


function firestore_deleteDocument(string $docPath): void {
    [$http, $accessToken, $projectId] = firestore_client();

    $http->delete($docPath, [
        'headers' => ['Authorization' => "Bearer $accessToken"]
    ]);
}

/**
 * Example: find user by email (returns unpacked doc fields + _name)
 */
function firestore_findUserByEmail(string $email): ?array {
    $results = firestore_runQuery([
        "from" => [["collectionId" => "users"]],
        "where" => [
            "fieldFilter" => [
                "field" => ["fieldPath" => "email"],
                "op"    => "EQUAL",
                "value" => ["stringValue" => $email]
            ]
        ],
        "limit" => 1
    ]);

    foreach ($results as $row) {
        if (!empty($row['document'])) {
            $doc = $row['document'];

            $fields = $doc['fields'] ?? [];
            $out = firestore_unpack_fields($fields);
            $out['_name'] = $doc['name'] ?? null;
            return $out;
        }
    }

    return null;
}

/**
 * Returns the Firebase project ID from service account JSON or env var.
 * Defined here (firestore_rest.php) as single canonical location.
 * DO NOT redefine this function in api/login.php or elsewhere.
 */
if (!function_exists('getFirebaseProjectId')) {
    function getFirebaseProjectId(): string {
        // Prefer env var (production)
        $fromEnv = getenv('FIREBASE_PROJECT_ID');
        if ($fromEnv) return trim($fromEnv);

        // Fallback: read from service account key path (dev only)
        $keyPath = getenv('FIREBASE_SERVICE_ACCOUNT') ?: '';
        if (!$keyPath) {
            // Last-resort dev fallback - outside web root preferred
            $keyPath = dirname(__DIR__, 2) . '/serviceAccountKey.json';
            if (!file_exists($keyPath)) {
                $keyPath = __DIR__ . '/serviceAccountKey.json';
            }
        }
        if (file_exists($keyPath)) {
            $j = json_decode(file_get_contents($keyPath), true);
            return $j['project_id'] ?? '';
        }
        return '';
    }
}
