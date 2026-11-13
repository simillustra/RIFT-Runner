# Data Ownership
| Data | Authority | Persistence |
|---|---|---|
| Character definitions/stats/ability metadata | Version-controlled Godot Resources | Shipped with game |
| Local settings | Player device | ConfigService |
| Offline save/profile | Player device | SaveService |
| Online identity/profile | Future Nakama | Server-owned |
| Co-op/competitive state | Future online server | Server-owned |
| AI credentials/config | AI service operator | Secret manager/environment |
| Generated content candidates | Content pipeline | Reviewed/versioned before shipping |
Never trust client economy/purchase/ranking values in future online systems. Resources are content, not a security boundary.
