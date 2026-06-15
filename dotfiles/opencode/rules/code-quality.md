1. Immutability (CRITICAL) - ALWAYS create new objects, NEVER mutate existing ones:
2. MANY SMALL FILES > FEW LARGE FILES:
	1. 200-400 lines typical, 800 max
	2. Extract utilities from large modules
	3. Organize by feature/domain, not by type
3. ALWAYS handle errors comprehensively
4. Log detailed error context on the server side
5. Never silently swallow errors
5. Make sure code is readable and well-named
	1. Functions are small (<50 lines)
	2. Files are focused (<800 lines)
	3. No deep nesting
	4. Proper error handling
	5. No hardcoded values (use constants or config)
	6. No mutation (immutable patterns used)
7. Dont add redundant comment, only add comments where its really required
