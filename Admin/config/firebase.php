<?php
// config/firebase.php
// Firestore REST compatibility layer (no Kreait, no gRPC)
// Keeps existing pages working: FirebaseAdmin::getInstance()->getFirestore()->collection(...)

require_once __DIR__ . '/firestore_rest.php';

class FirebaseAdmin
{
    private static ?FirebaseAdmin $instance = null;

    public static function getInstance(): FirebaseAdmin
    {
        if (self::$instance === null) self::$instance = new FirebaseAdmin();
        return self::$instance;
    }

    public function getFirestore(): FirestoreRestDb
    {
        return new FirestoreRestDb();
    }
}

class FirestoreRestDb
{
    public function collection(string $collectionId): FirestoreRestQuery
    {
        return new FirestoreRestQuery($collectionId);
    }
}

class FirestoreRestQuery
{
    private string $collectionPath;   // can be "services" OR "services/{id}/entries"
    private ?array $orderBy = null;   // ['field' => 'createdAt', 'dir' => 'DESCENDING']
    private ?int $limit = null;

    public function __construct(string $collectionPath)
    {
        $this->collectionPath = trim($collectionPath, '/');
    }

    // Matches pages: ->orderBy('createdAt', 'DESC')
    public function orderBy(string $field, string $direction = 'ASC'): self
    {
        $dir = strtoupper(trim($direction));
        $this->orderBy = [
            'field' => $field,
            'dir'   => ($dir === 'DESC' || $dir === 'DESCENDING') ? 'DESCENDING' : 'ASCENDING',
        ];
        return $this;
    }

    public function limit(int $n): self
    {
        $this->limit = max(1, (int)$n);
        return $this;
    }

    /**
     * Matches pages: ->documents()
     * IMPORTANT: supports subcollection path "services/{docId}/entries"
     */
    public function documents(): array
    {
        // Split "services/{docId}/entries" into:
        // parentPath = "services/{docId}"
        // collectionId = "entries"
        [$parentPath, $collectionId] = $this->splitParentAndCollection($this->collectionPath);

        $q = [
            "from" => [[ "collectionId" => $collectionId ]],
        ];

        if ($this->orderBy) {
            $q["orderBy"] = [[
                "field" => ["fieldPath" => $this->orderBy['field']],
                "direction" => $this->orderBy['dir'],
            ]];
        }

        if ($this->limit !== null) {
            $q["limit"] = $this->limit;
        }

        // ✅ Root collections use firestore_runQuery()
        // ✅ Subcollections use firestore_runQueryWithParent(parentDocPath, query)
        $rows = ($parentPath === '')
            ? firestore_runQuery($q)
            : firestore_runQueryWithParent($parentPath, $q);

        $docs = [];
        foreach ($rows as $row) {
            if (empty($row['document'])) continue;

            $doc = $row['document'];
            $name = $doc['name'] ?? '';
            $id = $this->extractIdFromName($name);

            $fields = $doc['fields'] ?? [];
            $data = firestore_unpack_fields($fields);

            // Convert timestamp strings to Timestamp-like shim
            $data = $this->convertTimestamps($data);

            $docs[] = new FirestoreRestDocumentSnapshot($id, $data);
        }

        return $docs;
    }

    // Optional: if any page later uses ->document('id')
    public function document(string $id): FirestoreRestDocumentRef
    {
        // If collectionPath is a subcollection path (services/{id}/entries)
        // document() should still work and refer to that path.
        return new FirestoreRestDocumentRef($this->collectionPath, $id);
    }

    private function splitParentAndCollection(string $collectionPath): array
    {
        // If no slashes => root collection
        if (strpos($collectionPath, '/') === false) {
            return ['', $collectionPath];
        }

        $parts = explode('/', $collectionPath);

        // valid subcollection path has odd number of parts:
        // collection/doc/collection  => 3 parts
        // collection/doc/collection/doc/collection => 5 parts
        // We want parent = everything except last segment
        // collectionId = last segment
        $collectionId = array_pop($parts);
        $parentPath = implode('/', $parts);

        return [$parentPath, $collectionId];
    }

    private function extractIdFromName(string $fullName): string
    {
        // "projects/{pid}/databases/(default)/documents/.../docId"
        $parts = explode('/', $fullName);
        return end($parts) ?: '';
    }

    private function convertTimestamps(array $data): array
    {
        foreach ($data as $k => $v) {
            if (is_string($v) && $this->looksLikeFirestoreTimestamp($v)) {
                $data[$k] = new TimestampShim($v);
            } elseif (is_array($v)) {
                $data[$k] = $this->convertTimestamps($v);
            }
        }
        return $data;
    }

    private function looksLikeFirestoreTimestamp(string $s): bool
    {
        return (bool)preg_match('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/', $s);
    }
}

class FirestoreRestDocumentSnapshot
{
    private string $id;
    private array $data;

    public function __construct(string $id, array $data)
    {
        $this->id = $id;
        $this->data = $data;
    }

    public function id(): string
    {
        return $this->id;
    }

    public function data(): array
    {
        return $this->data;
    }

    public function exists(): bool
    {
        return $this->id !== '';
    }
}

// Used only if pages later call ->document()->set/update
class FirestoreRestDocumentRef
{
    private string $collectionPath;
    private string $docId;

    public function __construct(string $collectionPath, string $docId)
    {
        $this->collectionPath = trim($collectionPath, '/');
        $this->docId = $docId;
    }

    public function collection(string $subcollectionId): FirestoreRestQuery
    {
        // doc ref -> subcollection path: "{collectionPath}/{docId}/{subcollectionId}"
        $full = $this->collectionPath . '/' . $this->docId . '/' . trim($subcollectionId, '/');
        return new FirestoreRestQuery($full);
    }

    public function set(array $fields): array
    {
        // If you want exact-id set, you should use firestore_setDocument().
        // But to keep compatibility, we create in collectionPath.
        return firestore_createDocument($this->collectionPath, $fields);
    }
}

// Timestamp shim to satisfy existing pages:
// $data['lastActive']->get()->getTimestamp()
class TimestampShim
{
    private string $iso;

    public function __construct(string $iso)
    {
        $this->iso = $iso;
    }

    public function get(): TimestampShim
    {
        return $this;
    }

    public function getTimestamp(): int
    {
        $t = strtotime($this->iso);
        return $t ? $t : 0;
    }
}

// Provide $firestore variable for pages
if (!isset($firestore)) {
    $firestore = FirebaseAdmin::getInstance()->getFirestore();
}
