# Software Praktikum

"Colours of Wine"

PR Software Praktikum WS 2025/26

Sofia Zauner, Peter Balint

## ✅ TO-DOs

### Data Extraction

- [ ] Rebsorte (evtl. weitere fehlende Daten?) mittels Gemini finden

### Web Descriptioins

- [ ] Descriptions filtern (momentan noch mit Domainnamen in der Suchanfrage - fuktioniert nicht so gut; wenn wir es so behalten, Logik davon in backend geben (Code Review))
- [ ] Nicht nur englische Descriptions suchen, sondern auch deutsche (oder überhaupt keinen Sprachfilter - Gemini übersetzt intern?)

### Summary

- [ ] Nicht nur Snippets verwenden, sondern ganze Descriptions auslesen (Readability.js?)
- [ ] Nicht erneut nach Descriptions suchen, sondern die bereits gefundenen verwenden (vllt. als Parameter übergeben?)
- [ ] Improve generation time (not sure if still relevant after model change?)

### Image Generation

- [ ] Mineralik-/Süße-Sidebar + Bubbles hinzufügen (Angabe von Anja)
- [ ] Bild downloadable (?)
- [ ] Farben auf #E- Format (?) (Code Review)
- [ ] Bild als multipart übergeben, nicht als base64
	* oder vlt. sollte das ein anderer Endpoint sein, dann könnte man
	  Summary vor dem Bild zeigen wenn z.B. das Netzwerk langsam ist

### Database

- [ ] Bild in der Db speichern (summary auch?)
- [ ] Direkte Neugenerierung möglich (?)
- [ ] "Reset search"- / "Close"-button oben fixieren (sonst zu lange scrollen, um Fenster schließen zu können)

### Etc

- [ ] Vllt. message bei long loading-screens
- [ ] Anzeige von Bild (momentan einf mit Summary unter Winecard, vllt eigenes Fenster oder so? und vllt größer)



## ✅ Code Quality Review: Colours of Wine --> Bis Montag!!
 
### 1. Architecture ✅

- [x] **1.1 Monolithic Orchestrator File** (No file bigger than 250 lines)
      
- [x] **1.2 Missing Service Layer**

- [x] **1.3 Hardcoded Configuration**
      
### 2. Readability ✅

- [x] **2.1 Mixed Language Comments** (all in english now, just texts for ai prompt in german)

- [x] **2.2 Inconsistent Error Messages**
      
- [x] **2.3 Magic Numbers and Strings**

### 3. Maintainability

- [x] **3.1 Large Files** (new structure; no file bigger than 250 lines)

- [ ] **3.2 Tight Coupling**
      
Problem: 
- UI components directly depend on implementation details.

Example: 
- `_buildResultView()` directly calls `_fetchWineDescription()` and `fetchSummary()`.

Recommendation: 
- Use dependency injection and interfaces to decouple components.

- [ ] **3.3 Missing Abstraction**
      
Problem: 
- Direct dependencies on Firebase, HTTP, and other services.

Recommendation: 
- Use repository pattern:
```dart
abstract class WineRepository {
  Future<WineData> analyzeLabel(Uint8List front, Uint8List back);
  // ...
}

class FirebaseWineRepository implements WineRepository {
  // Implementation
}
```


### 4. Code Duplication

### Critical Issues

- [ ] **4.1 Repeated Error Handling Pattern**
      
Location:
- Multiple files

Problem: 
- Same error handling code repeated throughout:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Error message"),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 7),
    backgroundColor: Color.fromARGB(255, 210, 8, 8),
    margin: EdgeInsets.all(50),
  ),
);
```

Recommendation: 
- Create utility function:
```dart
class SnackBarHelper {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        backgroundColor: AppConstants.errorRed,
        margin: const EdgeInsets.all(50),
      ),
    );
  }
}
```

- [ ] **4.2 Token Verification Duplication**
      
Location:
- All backend functions

Problem: 
- Token verification code repeated in every function:
```javascript
let user;
try {
  user = await admin.auth().verifyIdToken(token);
} catch (e) {
  logger.info("Wrong token", {token: token, error: e});
  return res.status(401).send("Wrong token");
}
```

Recommendation: 
- Create middleware:
```javascript
async function verifyToken(req, res, next) {
  const token = req.query.token || req.body.token;
  if (!token) {
    return res.status(401).send("Token missing");
  }
  try {
    req.user = await admin.auth().verifyIdToken(token);
    next();
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
}
```

- [ ] **4.3 CORS Headers Duplication**
      
Location:
- All backend functions

Problem: 
- `res.set('Access-Control-Allow-Origin', '*');` repeated in every function.

Recommendation: 
- Use middleware or set globally in Firebase Functions configuration.

- [ ] **4.4 Similar API Call Patterns**
      
Location: 
- Multiple Dart files

Problem: 
- Similar HTTP request patterns repeated.

Recommendation: 
- Create a base HTTP client:
```dart
class ApiClient {
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams});
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body});
}
```


### 5. Error Handling

- [ ] **5.1 Inconsistent Error Handling**
      
Problem: 
- Some errors are caught and shown to users, others are silently logged.

Examples:
- `lib/winedata_registration.dart:218`: Errors are caught and shown
- `lib/descriptions.dart:65`: Errors are caught but generic message shown
- `lib/summary.dart:25`: Errors return empty map `{}` without indication

Recommendation: 
- Always provide user feedback for user-initiated actions
- Log detailed errors for debugging
- Use Result/Either pattern for better error handling:
```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}
```

- [ ] **5.2 Missing Error Types**
      
Problem: 
- All errors treated the same way.

Recommendation: 
- Create specific error types:
```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
```

- [ ] **5.3 No Retry Logic**
      
Problem: 
- Network failures immediately fail without retry.

Recommendation:
- Implement exponential backoff retry for network calls:
```dart
Future<T> retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: pow(2, i).toInt()));
    }
  }
  throw Exception("Max retries exceeded");
}
```

- [ ] **5.4 Missing Input Validation**
      
Problem: 
- Limited validation of user inputs and API responses.

Recommendation: 
- Add validation:
```dart
class WineDataValidator {
  static ValidationResult validate(WineData data) {
    if (data.grapeVariety.isEmpty) {
      return ValidationResult.error("Grape Variety is mandatory");
    }
    return ValidationResult.success();
  }
}
```


### 6. Documentation

### Critical Issues

- [ ] **6.1 Missing API Documentation**
      
Problem:
- No documentation for backend API endpoints.

Recommendation: 
- Add JSDoc comments to all functions
- Document request/response formats
- Include example requests

- [ ] **6.2 Minimal Code Documentation**
      
Problem: 
- Most functions lack documentation.

Recommendation: 
- Add DartDoc comments:
```dart
/// Analyzes wine label images using Gemini AI.
/// 
/// Takes front and back label images and extracts wine information
/// including name, winery, vintage, grape variety, etc.
/// 
/// Throws [ApiException] if the API call fails.
/// Throws [NetworkException] if network connectivity issues occur.
Future<WineData> analyzeLabel(Uint8List front, Uint8List back) async {
  // ...
}
```

- [ ] **6.3 No Architecture Documentation**
      
Problem: 
- No README explaining project structure or architecture decisions.

Recommendation: 
- Create comprehensive README with:
	- Project overview
	- Architecture diagram
	- Setup instructions
	- API documentation
	- Development guidelines

- [ ] **6.4 Missing Inline Comments for Complex Logic**
      
Problem: 
- Complex logic (e.g., summary generation feedback loop) lacks explanation.

Location: 
- `backend/functions/summary.js:70-92`

Recommendation: 
- Add detailed comments explaining the iteration logic and why it's necessary.



### 7. Performance Issues

- [ ] **7.1 No Caching**
      
Problem: 
- No caching of API responses or images.

Recommendation: 
- Cache wine descriptions
- Cache label analysis results
- Use image caching library

- [ ] **7.2 Inefficient Image Handling**
      
Problem:
- Images are loaded into memory without optimization.

Location: 
- `lib/winedata_registration.dart`

Recommendation: 
- Compress images before upload
- Resize images to reasonable dimensions
- Use image caching

- [ ] **7.3 Multiple Sequential API Calls**
      
Problem:
- Some operations make multiple sequential API calls that could be parallelized.

Example: 
- `fetchDescriptions` and `generateSummary` could potentially be optimized.

Recommendation: 
- Use `Future.wait()` for independent operations:
```dart
final results = await Future.wait([
  fetchDescriptions(query),
  // other independent calls
]);
```

- [ ] **7.4 No Pagination**
      
Problem: 
- Search history loads all results at once.

Location: 
- `backend/functions/previousWines.js:20`

Recommendation: 
- Implement pagination:
```javascript
const limit = parseInt(req.query.limit) || 20;
const offset = parseInt(req.query.offset) || 0;
const queryResult = await searchCollection
  .where("uid", "==", uid)
  .orderBy("createdAt", "desc")
  .limit(limit)
  .offset(offset)
  .get();
```

- [ ] **7.5 Large Payloads**
      
Problem: 
- Full article text is fetched and stored for each description.

Location:
- `backend/functions/descriptions.js:100-106`

Recommendation: 
- Store only snippets initially
- Fetch full text on demand
- Limit article text length

- [ ] **7.6 No Request Timeout**
      
Problem: 
- HTTP requests have no timeout, can hang indefinitely.

Recommendation: 
- Add timeouts:
```dart
final response = await http.get(url).timeout(
  const Duration(seconds: 30),
  onTimeout: () {
    throw TimeoutException('Request timed out');
  },
);
```


### 8. AI API Usage

- [x] **8.1 CRITICAL: Hardcoded API Keys**

- [ ] **8.2 No Rate Limiting**
      
Problem: 
- No rate limiting on AI API calls.

Impact: 
- Potential cost overruns
- Risk of hitting API quotas
- No protection against abuse

Recommendation: Implement rate limiting:
```javascript
import rateLimit from 'express-rate-limit';

const aiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10 // limit each IP to 10 requests per windowMs
});
```

- [ ] **8.3 No Cost Monitoring**
      
Problem: 
- No tracking of AI API usage or costs.

Recommendation: 
- Log API usage
- Set up billing alerts
- Track costs per user/operation

- [ ] **8.4 No Error Handling for AI Failures**
      
Problem:
- Limited error handling for AI API failures.

Location: 
- `backend/functions/summary.js`, `backend/functions/labelExtraction.js`

Recommendation: 
- Handle quota exceeded errors
- Handle invalid response errors
- Provide fallback behavior

- [ ] **8.5 Inefficient AI Usage**
      
Problem: 
- Summary generation makes multiple AI calls in a loop.

Location: 
- `backend/functions/summary.js:70-92`

Issues:
- Up to 5 iterations (MaxIterationCount = 5)
- Each iteration makes 2 AI calls (writer + reviewer)
- Can take 10+ seconds per request
- No early exit conditions

Recommendation: 
- Consider reducing max iterations
- Add early exit if quality threshold met
- Cache intermediate results
- Consider using faster model for reviewer

- [ ] **8.6 No Prompt Versioning**
      
Problem:
- AI prompts are hardcoded without versioning.

Impact: 
- Difficult to A/B test or rollback prompt changes.

Recommendation: 
- Store prompts in database or config
- Version prompts
- Allow prompt updates without code deployment

- [ ] **8.7 Missing Input Sanitization**
      
Problem:
- User inputs passed directly to AI without sanitization.

Recommendation: 
- Sanitize inputs
- Limit input length
- Validate input format

- [ ] **8.8 No Response Validation**
      
Problem: 
- AI responses parsed without comprehensive validation.

Location: 
- `backend/functions/summary.js:179`, `backend/functions/labelExtraction.js:53`

Recommendation: 
- Validate JSON structure
- Validate required fields
- Handle malformed responses gracefully


### 9. Additional Issues

- [x] **9.1 Typo in UI**

- [ ] **9.2 Unused Dependencies**
      
Problem:
- Some dependencies may not be used.

Recommendation: 
- Run dependency analysis:
```bash
flutter pub deps
npm audit
```

- [ ] **9.3 Missing Tests**
      
Problem: 
- No test files found in the codebase.

Recommendation: 
- Add unit tests for business logic
- Add integration tests for API calls
- Add widget tests for UI components

- [ ] **9.4 Hardcoded Domain List**
      
Location: 
- `lib/model.dart:78-93`

Problem: 
- Allowed domains hardcoded in frontend with TODO to move to backend.

Recommendation: 
- Move to backend configuration or database.

- [ ] **9.5 Missing Loading States**
      
Problem:
- Some operations don't show loading indicators.

Recommendation: 
- Ensure all async operations show loading states.

- [ ] **9.6 No Offline Support**
      
Problem: 
- App requires internet connection for all operations.

Recommendation: 
- Cache recent results
- Queue operations when offline
- Show offline indicator

---


## Priority Recommendations

### Critical (Fix Immediately)
1. ✅ **Remove hardcoded API keys** - Security risk
2. ✅ **Rotate exposed API keys** - Security risk
3. ✅ **Add environment variable configuration** - Security and flexibility

### High Priority
1. ✅ **Refactor orchestrator.dart** - Improve maintainability
2. ✅ **Create service layer** - Better architecture
3. -- **Standardize error handling** - Better UX
4. -- **Add comprehensive error handling** - Reliability
5. -- **Implement rate limiting** - Cost control

### Medium Priority
1. -- **Add documentation** - Developer experience
2. -- **Reduce code duplication** - Maintainability
3. -- **Add input validation** - Data quality
4. -- **Implement caching** - Performance
5. -- **Add tests** - Code quality

### Low Priority
1. ✅ **Fix typos** - Polish
2. -- **Optimize AI usage** - Cost optimization
3. -- **Add pagination** - Scalability
4. -- **Improve offline support** - UX
