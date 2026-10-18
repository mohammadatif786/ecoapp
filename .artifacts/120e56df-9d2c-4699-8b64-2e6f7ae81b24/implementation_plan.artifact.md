# Refine Individual Chat API and User Data Integration

This plan focuses on perfectly aligning the individual chat integration with the provided real API response, ensuring that user profile data is correctly updated when entering a chat.

## Proposed Changes

### 1. New Model for Chat Results
- **[NEW] [chat_detail_result.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/model/chat_detail_result.dart)**:
    - Create a wrapper class `ChatDetailResult` to hold both the list of `MessageModel` and the `UserModel` for the other party.

### 2. Update `LinkupApiService`
- **[MODIFY] [linkup_api_service.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/services/linkup_api_service.dart)**:
    - Update `fetchChatDetail` to return `Future<ChatDetailResult>`.
    - Correctly parse the root `receiver` object into a `UserModel`.
    - Enhance `MessageModel` parsing to extract attachment URLs from the `meta` field for `image`, `pdf`, and `gif` types.
    - Handle `chatmessages` Map structure robustly.

### 3. Update `ChatController`
- **[MODIFY] [ChatController.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/get_controller/ChatController.dart)**:
    - Update `getChatHistory` to handle the new `ChatDetailResult`.
    - Automatically update `endUser` with the profile data returned from the API, ensuring "proper related data of user" is displayed.

### 4. UI Adjustments in `ChatHomePage`
- **[MODIFY] [chat_home_page.dart](file:///Users/admksol/Documents/admk_projects/Link_Up_Mobile/lib/ui/chat_home_page.dart)**:
    - Ensure `_buildChatThreadView` reacts to potential changes in `endUser` (like updated distance or popularity level).
    - Fix the chat composer to correctly pass the `_activeChatId` which is confirmed to be the UID.

## Verification Plan

### Manual Verification
- **Individual Chat**: Navigate to a chat with a specific user. Verify that their full name, distance, and "coins earned" (popularity level) update based on the individual chat API response.
- **Message Content**: Verify that images and PDFs sent/received are correctly identified using the `meta.url` field.
- **Data Integrity**: Ensure messages are sorted correctly (newest at bottom or top depending on UI layout).
