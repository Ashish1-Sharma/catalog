# APP FLOW

## Navigation Map

```text
Splash (1)
 ├── (no user_id cached) ──> Onboarding (2) ──> Login/Signup (3) ──> Business Profile Setup (4) ──> Trial Popup (6) ──> Dashboard (5)
 └── (user_id cached) ─────> Dashboard (5)

Dashboard (5)
 ├── Tab 1: Categories (7) ──> Add/Edit Category (8) ──> back to Category List (7)
 ├── Tab 2: Products (9) ────> Add/Edit Product (10) ──> back to Product List (9)
 ├── Tab 3: Catalogs (22)
 │    ├── Select Catalog ──> Catalog Preview (15) ──> Export & Share (16)
 │    └── Create Catalog button ──> Catalog Step 1: Category Select (11)
 │                                    └──> Catalog Step 2: Product Select (12)
 │                                          └──> Catalog Step 3: Type Select (13)
 │                                                └──> Catalog Step 4: Style Select (14)
 │                                                      └──> Catalog Preview (15) ──> Export & Share (16)
 ├── Tab 4: Marketing (20) (placeholder screen)
 ├── Tab 5: Tutorial (21) (placeholder screen)
 ├── Subscription Banner / Action ──> Subscription Screen (17)
 └── Settings Icon ──> Settings Screen (18)
                        ├── Edit Business Profile (19) ──> back to Settings (18)
                        ├── Subscription Status (17) ───> back to Settings (18)
                        └── Logout ─────────────────────> Splash / Login (3)
```
