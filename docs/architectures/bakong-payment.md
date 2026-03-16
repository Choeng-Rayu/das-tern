# Bakong Payment

```mermaid
flowchart LR
    APP[Das Tern App] --> BE[Main Backend]
    BE --> PAY[Bakong Payment Service]
    PAY --> QR[Create KHQR code]
    QR --> USER[User pays]
    PAY --> BAKONG[Check Bakong status]
    BAKONG --> PAY
    PAY --> BE
    BE --> SUB[Activate subscription]
```

## Simple explanation

- This service handles premium plan payments.
- It creates the payment QR code.
- It checks whether the payment is complete.
- It tells the backend when the subscription should be activated.

## Main idea

- Payment work is separated from medical data work.
- The app still talks through the main backend.
- This keeps payment handling more secure and easier to manage.
