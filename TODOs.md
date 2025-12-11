## ✅ TO-DOs

### Data Extraction

- [ ] Rebsorte (evtl. weitere fehlende Daten?) mittels Gemini finden

### Image Generation

- [ ] Mineralik-/Süße-Sidebar + Bubbles hinzufügen (Angabe von Anja)
- [ ] Bild downloadable (?)
- [ ] Farben auf #E- Format (?) (Code Review)
- [ ] Bild als multipart übergeben, nicht als base64
	* oder vlt. sollte das ein anderer Endpoint sein, dann könnte man
	  Summary vor dem Bild zeigen wenn z.B. das Netzwerk langsam ist

### Database

- [ ] Direkte Neugenerierung möglich (?)
- [ ] History nach Datum sortieren
- [ ] ganze descriptions speichern, aber nur die snippets anzeigen (?)

### Etc

- [ ] Vllt. message bei long loading-screens
- [ ] Anzeige von Bild




## ✅ Code Quality Review: Colours of Wine --> Bis Montag!!
 
### 1. Architecture ✅

- [x] **1.1 Monolithic Orchestrator File** (No file bigger than 250 lines)
      
- [x] **1.2 Missing Service Layer**

- [x] **1.3 Hardcoded Configuration**
      
### 2. Readability ✅

- [x] **2.1 Mixed Language Comments** (all in english now, just texts for ai prompt in german)

- [x] **2.2 Inconsistent Error Messages**
      
- [x] **2.3 Magic Numbers and Strings**

### 3. Maintainability ✅

- [x] **3.1 Large Files** (new structure; no file bigger than 250 lines)

- [x] **3.2 Tight Coupling** (solved via service layer)

- [x] **3.3 Missing Abstraction**

### 4. Code Duplication ✅

- [x] **4.1 Repeated Error Handling Pattern**

- [x] **4.2 Token Verification Duplication**

- [x] **4.3 CORS Headers Duplication**

- [x] **4.4 Similar API Call Patterns**

### 5. Error Handling ✅

- [x] **5.1 Inconsistent Error Handling**

- [x] **5.2 Missing Error Types**

- [x] **5.3 No Retry Logic**

- [x] **5.4 Missing Input Validation**

### 6. Documentation ✅

- [x] **6.1 Missing API Documentation**

- [x] **6.2 Minimal Code Documentation**

- [x] **6.3 No Architecture Documentation**

- [x] **6.4 Missing Inline Comments for Complex Logic**

### 7. Performance Issues ✅

- [x] **7.1 No Caching** (done for descriptions -- no sense for labels, because pictures are (almost) always different (mostly taken with camera) && AI-Image should alwyas be different (I guess))

- [x] **7.2 Inefficient Image Handling**

- [x] **7.3 Multiple Sequential API Calls** (Not applicable: each operation always calls a single endpoint)

- [ ] **7.4 No Pagination** & **7.5 Large Payloads** --> both points depend on the accessing of the websites, better to fix it, when that is fixed
      
- [x] **7.6 No Request Timeout**


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

- [x] **8.3 No Cost Monitoring**

- [x] **8.4 No Error Handling for AI Failures**

- [x] **8.5 Inefficient AI Usage**

- [ ] **8.6 No Prompt Versioning**
      
Problem:
- AI prompts are hardcoded without versioning.

Impact: 
- Difficult to A/B test or rollback prompt changes.

Recommendation: 
- Store prompts in database or config
- Version prompts
- Allow prompt updates without code deployment

- [x] **8.7 Missing Input Sanitization** (This is not true. We do not pass user inputs to AI at all, the input always comes from websites)

- [x] **8.8 No Response Validation**
      
### 9. Additional Issues

- [x] **9.1 Typo in UI**

- [x] **9.2 Unused Dependencies**

- [ ] **9.3 Missing Tests**
      
Problem: 
- No test files found in the codebase.

Recommendation: 
- Add unit tests for business logic
- Add integration tests for API calls
- Add widget tests for UI components

- [x] **9.4 Hardcoded Domain List**

- [x] **9.5 Missing Loading States** (also did not find any)

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
3. ✅ **Standardize error handling** - Better UX
4. ✅ **Add comprehensive error handling** - Reliability
5. ✅ **Implement rate limiting** - Cost control

### Medium Priority
1. ✅ **Add documentation** - Developer experience
2. ✅ **Reduce code duplication** - Maintainability
3. ✅ **Add input validation** - Data quality
4. ✅ **Implement caching** - Performance
5. -- **Add tests** - Code quality

### Low Priority
1. ✅ **Fix typos** - Polish
2. -- **Optimize AI usage** - Cost optimization
3. -- **Add pagination** - Scalability
4. -- **Improve offline support** - UX
