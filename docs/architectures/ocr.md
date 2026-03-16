# OCR Service

```mermaid
flowchart LR
    IMG[Prescription photo] --> BE[Main Backend]
    BE --> OCR[OCR Service]
    OCR --> PREP[Clean image]
    PREP --> READ[Read text]
    READ --> JSON[Structured prescription data]
    JSON --> BE
```

## Simple explanation

- This service reads prescription photos.
- It cleans the image, reads the text, and extracts useful medicine details.
- It sends the result back as structured data.

## Main idea

- It changes paper prescriptions into digital information.
- The OCR service reads the image.
- The backend decides what to do with the result next.
