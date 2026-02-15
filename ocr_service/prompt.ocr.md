Phase 1: first read #file:docs #file:ocr_service #file:ocr-prescription-scanning  for more understanding 
phase 2: do not scan the image #file:images  by your selft to understand how it image is hard for extract the prescription and think what technology and match with that image inlcuding imrpove blue, imrpove image quality and analyze layout  and more to make ocr service is scaning with the best result.   consider the all the image and store the result in the #file:final.result.format.expected.json with bbox(you must scaning by yourself first to define the formart with bbox)
phase 3: after already impelmentation all the result is must compare with this reulst that you scanned by yourself  because i assume that your seult you scan by your is the perfect result  so is the result impelemnt can't like the same your expected result must improve it test again again until it see the same your result.(but the implement is  not yet start understand you completed the phase 4)
phase 4: use browser to deep  research  follow my below design and improve it to make it bettern and auccurate and good performace is fast and smooth and reliable 

text stack is usingpython  and the image to implement this use to scan the prescription like this the image i past to you  but n the fromart in that presscription is not only one formart it have many formart. 
1 — High level pipeline (text)

Receive image upload (API endpoint).

Pre-check image quality (blur, brightness, skew, crop). If low quality, run enhancement and re-check. Flag for manual review if still bad.

Layout analysis -> detect table / header / signature regions. Crop medicine table.

Per-cell OCR using PaddleOCR (primary).

If Khmer text has low confidence, run Kiri OCR (Khmer-specialized) on Khmer cells.

Fallback: run Tesseract (khm+eng+fra) on whole image or on problem cells.

Post-process: normalize text, map columns (name, qty, route, schedule), use rules to compute doses/duration.

Compute reminders and persist prescription JSON + reminders in DB.

Human verification UI (show low-confidence fields). Confirm, then schedule reminders.

2 — Architecture (components & flow)
[Client App] --> [API Gateway / Upload Endpoint]
                    |
               Preprocessor (OpenCV)
  (blur check, denoise, deskew, crop, contrast)
                    |
             Layout Analyzer (layoutparser / Paddle Table)
                    |
         ┌──────────┴──────────┐
         |                     |
   Table Cells OCR         Header OCR
(PaddleOCR primary)   (PaddleOCR / Tesseract)
         |
  Khmer low-conf? --> Kiri OCR (Khmer)
         |
   Post-processing (spellfix, med lexicon)
         |
  Validation UI (human-in-loop)
         |
  Store JSON -> Reminder generator -> notification service

3 — Quality checks & image preprocessing (code patterns)

Install dependencies (example):

pip install opencv-python pillow pytesseract paddlepaddle paddleocr layoutparser
# Kiri OCR: follow its repo / install requirements or clone and use its inference script


Key helper functions (Python / OpenCV):

import cv2
import numpy as np
from pytesseract import pytesseract

def is_blurry(img_gray, thresh=100.0):
    # variance of Laplacian
    return cv2.Laplacian(img_gray, cv2.CV_64F).var() < thresh

def adjust_contrast_brightness(img):
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l,a,b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    cl = clahe.apply(l)
    limg = cv2.merge((cl,a,b))
    return cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)

def denoise(img):
    return cv2.fastNlMeansDenoisingColored(img,None,10,10,7,21)

def deskew(img_gray):
    coords = np.column_stack(np.where(img_gray < 255))
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90+angle)
    else:
        angle = -angle
    (h,w) = img_gray.shape
    M = cv2.getRotationMatrix2D((w//2,h//2), angle, 1.0)
    return cv2.warpAffine(img_gray, M, (w,h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)


Preprocess workflow:

Load image, convert to RGB and gray.

If is_blurry(gray) → apply denoise, sharpen (unsharp mask), then recheck.

Brightness/contrast → adjust_contrast_brightness.

Deskew. Resize to max dimension ~1600 px to preserve detail while staying CPU-friendly.

4 — Layout / table detection

Options:

Quick: use OpenCV line detection to find table grid, then cut rows/cols.

Better: use layoutparser with a table detection model (fast and reliable on documents).

Best: PaddleOCR table detection model (if you can load the table model weights) or pretrained table detector.

Example (conceptual):

# use layoutparser to detect table bbox then split to rows/cols -> crop each cell
import layoutparser as lp
model = lp.Detectron2LayoutModel('lp://PubLayNet/faster_rcnn_R_50_FPN_3x/config')
layout = model.detect(image)
# find the table element, then segment into cells with line detection


If table detection fails, fallback to OCR on whole image then infer rows using Y coordinate clustering of text boxes.

5 — OCR + fallback strategy

Primary: PaddleOCR (best accuracy for mixed languages & tables)

Use PaddleOCR Python API with use_gpu=False.

If you have a Khmer recognition model, point rec_model_dir to the Khmer model for the recognition step.

Pseudocode:

from paddleocr import PaddleOCR
ocr = PaddleOCR(use_angle_cls=True, lang='en')  # base; customize or use multilingual/custom Khmer rec model

def run_paddle_on_crop(crop_img):
    result = ocr.ocr(crop_img, cls=True)
    # result: list of [bbox, (text, conf)]
    return result


If cell text confidence for Khmer < 0.75:

Run Kiri OCR on that cell (Khmer-specialized). Use its inference script — feed the cropped cell image and parse output.

If still low/confident < 0.6, run Tesseract (pytesseract) as last fallback:

import pytesseract
txt = pytesseract.image_to_string(crop_img, lang='khm+eng+fra', config='--oem 1 --psm 6')


Confidence thresholds:

Accept automatically if conf >= 0.80.

If 0.60 <= conf < 0.80 → mark for auto-suggest and show in verification UI.

If conf < 0.60 → send to manual review.

6 — Post-processing / domain knowledge

Normalize medication names: lowercasing + remove punctuation.

Use small medical lexicon (local list of common drug names, local spellcheck for Khmer pharmacy terms) to map OCR variants to canonical names (fuzzy matching, Levenshtein).

Quantity parsing: regex for digits.

Route detection: search for PO, oral, Khmer equivalents.

Schedule mapping: map the table columns to time slots (07:00, 11:30, 17:30) as earlier.

Duration: duration_days = round(quantity / doses_per_day). If not integer, set needs_review=True.

7 — Reminder generation & data model

Use the JSON schema we made earlier. Example compute reminders algorithm:

For each med, generate events from start_date to start_date + duration_days - 1 at each time in times[].

Persist events to DB and push to scheduler (e.g., Celery beat, cron, or native scheduler).

8 — Deployment & CPU optimization

Containerize (Docker) the service. Give more CPU shares and set OMP_NUM_THREADS to available cores.

For Paddle Inference: enable MKL-DNN / OpenBLAS; consider converting recognition model to ONNX and quantizing to int8 using onnxruntime + quantization for faster CPU inference. Also consider OpenVINO for Intel CPUs.

For Tesseract: use --oem 1 (LSTM) and set --psm according to input (6 for single block).

Use batching only for offline bulk processing; for per-image low-latency, process single image.

9 — Monitoring & human-in-loop

Log OCR confidences and errors.

Provide verification UI that highlights low-confidence fields and shows original cropped cell for quick edit.

Track accuracy metrics (manual corrections) to create retraining dataset.

10 — Testing plan & rollout

Unit tests for preprocessing functions (blur detection, deskew).

Evaluate pipeline on 100 sample prescriptions (measure field-level accuracy).

Tune confidence thresholds, add words to lexicon, expand Khmer training data for Kiri OCR.

Rollout to a small pilot (10 users) with mandatory verification for first 2 prescriptions.