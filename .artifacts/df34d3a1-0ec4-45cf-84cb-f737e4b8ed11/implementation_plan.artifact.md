# Implementation Plan - Blue Wallet Card & Dialogs Update

This plan outlines the changes to replicate the new design for the primary blue card in the wallet, including its details and mobile wallet provisioning flows.

## User Review Required

> [!IMPORTANT]
> The "Order a Card" and "Freeze" options in the current menu will be moved or modified to make room for the new "Add to Mobile Wallet" flow shown in the screenshots.

## Proposed Changes

### Wallet Page (`lib/ui/wallet_page.dart`)

#### [MODIFY] `_visaCard`
- Update the styling of the card in the feature grid.
- Change "VISA" to "Mastercard".
- Update static number to `•••• 7560` and date to `07/29`.
- Add a yellow chip icon.
- Adjust colors and typography to match the screenshot background.

#### [MODIFY] `_showMyCard`
- Update the "Theme" selection area if needed (though user said "remaining everything remains as it is").
- Replace or add a button for "Add to Mobile Wallet".
- Background of the screenshot shows the card being interacted with.

#### [MODIFY] `_showCardDetails`
- Replicate Screenshot 1.
- Add the orange warning banner.
- Layout the labels (`CARD NUMBER`, `EXPIRES`, etc.) and values (`5189 8348 8329 7560`, etc.) exactly.
- Update the "Copy Card Number" button styling.

#### [NEW] `_showMobileWallet`
- Implement the "Add to Mobile Wallet" dialog (Screenshot 2).
- Add "Add to Apple Pay" and "Add to Google Pay" buttons with icons.
- Implement the "Ready to tap" state (Screenshot 3) with the green success box and "Remove from Mobile Wallet" button.

## Verification Plan

### Manual Verification
- Tap the blue card in the Wallet grid.
- Verify the "View Details" dialog matches Screenshot 1.
- Verify the "Add to Mobile Wallet" dialog matches Screenshot 2.
- Verify the success state in Screenshot 3 can be triggered/displayed.
