## Kiri-OCR customization guide for prescription images

### 1) Understand the current confidence score
- Your `0.4343` score comes from Kiri-OCR raw line confidences.
- It does **not** mean the whole extraction failed.
- Khmer + English + tables often produce lower raw OCR confidences than simple printed text.

### 2) What I improved already
- Recomputed confidence from the **final selected medications**.
- Switched temporary OCR handoff images from **JPEG to PNG** to avoid text blurring.
- Verified OCR tests still pass.

### 3) What usually improves OCR most
1. Better image capture: flat page, no shadow, no finger, high resolution.
2. More training examples from your real clinics/hospitals.
3. Better annotations for Khmer/English mixed prescriptions.
4. Lexicon/post-processing for medicine names and Khmer quantity units.

### 4) Before training: do this first
Create a real dataset from your prescriptions:
- 200+ images = useful start
- 500+ images = much better
- 1000+ images = strong project base

Try to include variation:
- different hospitals/clinics
- different doctors and handwriting/print quality
- rotated/skewed images
- dark/bright images
- Khmer-only, English-only, mixed-language
- prescriptions with and without tables

### 5) Folder structure
Use this structure:
- `ocr/training_data/raw_images/train/`
- `ocr/training_data/raw_images/val/`
- `ocr/training_data/raw_images/test/`
- `ocr/training_data/annotations/train.jsonl`
- `ocr/training_data/annotations/val.jsonl`
- `ocr/training_data/annotations/test.jsonl`

### 6) Generate annotation templates
Run:
- `python ocr/scripts/prepare_training_manifest.py --images ocr/images_for_test --output ocr/training_data/annotations/train.jsonl --split train`

This creates one JSON line per image with blank fields to fill in.

### 7) What to label for each image
For each prescription image, fill these fields:
- full transcription text
- patient name, age, gender, code
- diagnoses
- medication rows
- quantity, form, morning/midday/evening/night doses
- duration and instructions

### 8) Recommended annotation workflow for beginners
1. Start with 30 images.
2. Fill the JSONL manually.
3. Review every label twice.
4. Expand to 100 images.
5. Split into train/val/test.
6. Only then start model customization.

### 9) Important note about Kiri-OCR training
The installed `kiri_ocr` package in this project is mainly an **inference library**.
In practice, customization usually happens in one of these ways:

1. **No-model-training path**
   - improve preprocessing
   - add medicine lexicons
   - add post-processing correction rules
   - best first step for production

2. **Model-training path**
   - fine-tune the detector/recognizer stack used by Kiri-OCR
   - requires the upstream training code or a compatible OCR training framework
   - best when you have enough labeled data

### 10) Beginner roadmap I recommend
#### Phase A — easiest and highest ROI
1. collect 200 real prescriptions
2. annotate them
3. build a Khmer/English medicine lexicon
4. add correction rules for common OCR mistakes
5. measure field accuracy

#### Phase B — only after Phase A
1. confirm upstream Kiri-OCR training support
2. export train/val/test datasets
3. fine-tune on your real prescriptions
4. compare against current baseline

### 11) What success metric to track
Track these separately:
- OCR text line accuracy
- medication name accuracy
- quantity accuracy
- dose-slot accuracy
- duration accuracy
- full-prescription exact match rate

### 12) My recommendation for you
Do **not** start with model fine-tuning first.
Start with:
- better labeled dataset
- lexicon correction
- confidence/error analysis
- preprocessing improvements

After you prepare 100–200 labeled real prescriptions, I can help you build the next step: a full train/val/test pipeline and conversion scripts for the exact training format you choose.