1. Avoid last 20% of context window for - Large-scale refactoring, Feature implementation spanning multiple files, Debugging complex interactions
2. Lower context sensitivity tasks - Single-file edits, Independent utility creation, Documentation updates, Simple bug fixes
3. Extended thinking is enabled by default, reserving up to 31,999 tokens for internal reasoning.
4. Control extended thinking via `export MAX_THINKING_TOKENS=10000`


For complex tasks requiring deep reasoning:

3. Use multiple critique rounds for thorough analysis
4. Use split role sub-agents for diverse perspectives, for a complex 4+ task items
