# Dependency Rules
1. Domain Resources do not depend on scenes, UI, backend SDKs or AI providers.
2. Presentation may depend on domain contracts; domain must not import presentation.
3. Core services remain generic; no hero-specific logic in autoloads.
4. Input produces intent; movement/combat interpret intent.
5. Animation presents state; it does not authoritatively apply damage or movement.
6. Nakama and AI are optional adapters.
7. Remote calls and disk I/O must not block frame-critical code.
8. Native modules require profiling evidence and an ADR.
