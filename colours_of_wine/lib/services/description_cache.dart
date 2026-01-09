/* cache for descriptions */

/* gets cleared after every logout -->
 * when a user has serched a wine, but is not satisfied with the picture he can easily retry it, 
 * but still has the option to use new (maybe more current) descriptions in his next session 
 * like this it's good for user and storage
 */

// map with key = wine query string, value = list of descriptions
class DescriptionCache {
  static final Map<String, List<Map<String, String>>> _cache = {};

  static bool has(String key) => _cache.containsKey(key);

  static List<Map<String, String>>? get(String key) => _cache[key];

  static void set(String key, List<Map<String, String>> data) {
    _cache[key] = data;
  }

  static void clear() => _cache.clear();
}
