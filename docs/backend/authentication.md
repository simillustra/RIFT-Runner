# Authentication
Offline single-player must not require authentication. Future Nakama identity (RR-012) must document guest/account linking, token refresh, logout, expiry, device change and recovery. Use TLS; store tokens in platform secure storage; never log tokens. Authentication and authorization differ: server validates every protected operation.
