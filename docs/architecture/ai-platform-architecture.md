# AI Platform Architecture
A separate Python/FastAPI service will orchestrate optional AI workflows, provider selection, policy checks, request validation, quotas, telemetry and secret handling.

Provider adapters: OpenAI, Amazon Bedrock and custom providers. No provider SDK/key in Godot. No remote inference in frame, input, movement, combat or enemy decision loops. Deterministic local FSM/behavior logic controls real-time enemies. Game remains playable when AI service is offline. Planned under RR-014/RR-015.
