# Implementation Plan - Social APIs & Robust Parsing

Fix existing parsing errors and implement the new Social APIs (Matches, Friends, Unfriend).

## User Review Required

> [!IMPORTANT]
> - I will implement a robust user parsing helper in `LinkupApiService` to handle cases where the API returns a Map with numeric keys instead of a List for `users`. This will fix the current error when navigating to "Likes".
> - I will switch the "Who Likes Me" page to use the new API instead of Firebase.

## Proposed Changes

### Data Layer

#### [MODIFY] [linkup_api_service.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/services/linkup_api_service.dart)
- Add a helper method `_usersFromDynamic(dynamic data)` to extract `List<UserModel>` from either a `List` or a `Map`.
- Refactor `_usersFromBody` to use this helper.
- Implement `fetchAllMatches()` using `ApiEndpoints.allMatches`.
- Implement `fetchFriends()` using `/api/regular-user/friend`.
- Implement `unfriend(int userId)` using `/api/regular-user/friend/$userId/unfriend`.

#### [MODIFY] [likes_response.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/model/likes_response.dart)
- Update to use the new robust parsing helper from `LinkupApiService` (or replicate it) to avoid the `Map` vs `List` cast error.

### UI Layer

#### [MODIFY] [likes_me_page.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/ui/likes_me_page.dart)
- Replace `FirebaseFirestore` StreamBuilder with a `FutureBuilder` or `GetBuilder` that calls `LinkupApiService.fetchLikes()`.
- Match the UI to use the data returned from the API.

## Verification Plan

### Manual Verification
1. Navigate to the "Who Likes Me" page. Verify that it loads without the "type Map is not a subtype of type List" error.
2. Verify that user details (name, avatar) are correctly displayed from the API.
3. Test the "Unfriend" functionality if a UI exists for it.
