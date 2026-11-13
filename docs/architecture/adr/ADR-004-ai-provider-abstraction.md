# ADR-004: AI Provider Abstraction
**Status:** Accepted target architecture. **Decision:** Separate Python/FastAPI orchestration with provider-neutral OpenAI, Bedrock and custom adapters.  
Keep provider SDKs and credentials server-side. Require contract tests, timeouts, quotas, fallback and observability. No AI call may block the game loop.
