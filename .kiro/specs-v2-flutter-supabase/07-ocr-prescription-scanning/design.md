# Design: OCR Prescription Scanning (Hybrid Pipeline)

## 1. Pipeline overview

```
┌──────────────┐
│ Capture/Pick │  camera + image_picker
└──────┬───────┘
       ▼
┌──────────────┐
│ Preprocess   │  rotate, crop, perspective fix, contrast
└──────┬───────┘
       ▼
┌────────────────────────┐
│ ML Kit Latin           │  on-device, fast
│ avg confidence: c1     │
└──────┬─────────────────┘
       │
       │ if c1 < 0.6 OR Khmer chars present
       ▼
┌────────────────────────┐
│ Tesseract Khmer + Eng  │  on-device, slower
│ avg confidence: c2     │
└──────┬─────────────────┘
       │
       │ merge by line: prefer Khmer engine for lines
       │ with U+1780–U+17FF, ML Kit for Latin lines
       ▼
┌────────────────────────┐
│ Merged result          │  total confidence: c
└──────┬─────────────────┘
       │
       │ if c < 0.5 OR user taps "Try better OCR"
       ▼
┌────────────────────────┐
│ Edge: ocr-cloud-vision │  Google Cloud Vision, networked
│ best-effort highest    │
└──────┬─────────────────┘
       ▼
┌────────────────────────┐
│ Field Extractor        │  pure Dart heuristics
└──────┬─────────────────┘
       ▼
┌────────────────────────┐
│ Review Screen          │  user confirms/edits
└──────┬─────────────────┘
       ▼
┌────────────────────────┐
│ Save: 03-prescription  │  creates prescription + meds + doses
└────────────────────────┘
```

## 2. Module structure

```
lib/features/ocr/
├── data/
│   ├── ocr_pipeline.dart                  # orchestrates engines
│   ├── mlkit_engine.dart
│   ├── tesseract_engine.dart
│   ├── cloud_vision_client.dart           # invokes Edge Function
│   ├── field_extractor.dart               # heuristics
│   └── medication_dictionary.dart         # local dictionary lookup
├── domain/
│   ├── ocr_result.dart                    # freezed
│   ├── medication_candidate.dart
│   └── usecases/
│       ├── scan_prescription.dart
│       └── extract_fields.dart
└── presentation/
    ├── pages/
    │   ├── scan_intro_page.dart
    │   ├── camera_capture_page.dart
    │   ├── crop_preview_page.dart
    │   ├── ocr_progress_page.dart
    │   └── ocr_review_page.dart
    └── widgets/
        ├── confidence_chip.dart
        ├── medication_candidate_card.dart
        └── original_image_pane.dart
```

## 3. Dependencies

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.15.1
  flutter_tesseract_ocr: ^0.4.31      # or `flusseract` if better support
  camera: ^0.11.0
  image_picker: ^1.1.0
  image: ^4.1.0                       # cropping/perspective
  cunning_document_scanner: ^1.2.4    # optional native doc scanner
  path_provider: ^2.1.0
  http: ^1.2.0                        # Edge Function invocation if not via supabase_flutter
```

Bundle assets:

```yaml
flutter:
  assets:
    - assets/tessdata/khm.traineddata
    - assets/tessdata/eng.traineddata
    - assets/medications/dictionary.json   # curated medication-name dictionary
```

## 4. ML Kit engine

```dart
class MlKitEngine implements OcrEngine {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrEngineResult> recognize(File image) async {
    final input = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(input);

    final blocks = <OcrBlock>[];
    var totalChars = 0;
    var weightedConf = 0.0;

    for (final b in recognized.blocks) {
      var blockConf = 0.0;
      var blockChars = 0;
      for (final l in b.lines) {
        for (final el in l.elements) {
          // ML Kit confidence per element is not always available; use length as weight
          blockConf += (el.confidence ?? 0.85) * el.text.length;
          blockChars += el.text.length;
        }
      }
      blocks.add(OcrBlock(
        text: b.text,
        confidence: blockChars == 0 ? 0 : blockConf / blockChars,
        boundingBox: b.boundingBox,
        languageHint: 'en',
      ));
      weightedConf += blockConf;
      totalChars += blockChars;
    }
    return OcrEngineResult(
      engine: 'mlkit_latin',
      blocks: blocks,
      averageConfidence: totalChars == 0 ? 0 : weightedConf / totalChars,
    );
  }

  Future<void> dispose() async => _recognizer.close();
}
```

## 5. Tesseract engine

```dart
class TesseractEngine implements OcrEngine {
  Future<void> ensureInitialized() async {
    final dir = await getApplicationSupportDirectory();
    final tessdata = Directory('${dir.path}/tessdata');
    if (!tessdata.existsSync()) {
      tessdata.createSync(recursive: true);
      for (final lang in const ['khm', 'eng']) {
        final data = await rootBundle.load('assets/tessdata/$lang.traineddata');
        await File('${tessdata.path}/$lang.traineddata').writeAsBytes(data.buffer.asUint8List());
      }
    }
  }

  @override
  Future<OcrEngineResult> recognize(File image) async {
    await ensureInitialized();
    final raw = await FlutterTesseractOcr.extractText(
      image.path,
      language: 'khm+eng',
      args: {'preserve_interword_spaces': '1', 'psm': '4'},
    );
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty);
    final blocks = lines.map((l) => OcrBlock(
      text: l,
      confidence: 0.7,    // Tesseract no longer exposes per-line confidence directly via this plugin
      boundingBox: null,
      languageHint: _looksKhmer(l) ? 'km' : 'en',
    )).toList();
    return OcrEngineResult(engine: 'tesseract_khm_eng', blocks: blocks,
      averageConfidence: 0.7);
  }
}

bool _looksKhmer(String s) {
  for (final r in s.runes) {
    if (r >= 0x1780 && r <= 0x17FF) return true;
  }
  return false;
}
```

## 6. Pipeline orchestrator

```dart
class OcrPipeline {
  OcrPipeline(this._mlkit, this._tesseract, this._cloudClient);

  Future<OcrResult> recognize(File image, {bool forceCloud = false}) async {
    if (forceCloud) {
      return _cloudClient.recognize(image);
    }

    final mlkit = await _mlkit.recognize(image);
    final hasKhmer = mlkit.blocks.any((b) => _hasKhmerChars(b.text));
    final lowConfidence = mlkit.averageConfidence < 0.6;

    OcrEngineResult? tesseract;
    if (hasKhmer || lowConfidence) {
      tesseract = await _tesseract.recognize(image);
    }

    final merged = _mergeByLine(mlkit, tesseract);

    if (merged.averageConfidence < 0.5) {
      try {
        final cloud = await _cloudClient.recognize(image);
        if (cloud.averageConfidence > merged.averageConfidence) {
          return OcrResult(
            primary: cloud,
            sources: [mlkit, if (tesseract != null) tesseract, cloud],
          );
        }
      } on _NetworkOrQuotaError {
        // fall back silently to merged result
      }
    }

    return OcrResult(
      primary: merged,
      sources: [mlkit, if (tesseract != null) tesseract],
    );
  }

  OcrEngineResult _mergeByLine(OcrEngineResult mlkit, OcrEngineResult? tess) {
    if (tess == null) return mlkit;
    final mergedBlocks = <OcrBlock>[];
    // Naive line alignment: use Tesseract for lines that contain Khmer chars
    final tessByLanguage = tess.blocks.where((b) => b.languageHint == 'km').toList();
    final mlByLanguage = mlkit.blocks.where((b) => b.languageHint == 'en').toList();
    mergedBlocks.addAll(mlByLanguage);
    mergedBlocks.addAll(tessByLanguage);
    final avg = mergedBlocks.isEmpty ? 0.0 :
      mergedBlocks.map((b) => b.confidence).reduce((a, b) => a + b) / mergedBlocks.length;
    return OcrEngineResult(engine: 'merged', blocks: mergedBlocks, averageConfidence: avg);
  }
}
```

## 7. Cloud Vision Edge Function

```ts
// supabase/functions/ocr-cloud-vision/index.ts
import { serve } from "https://deno.land/std@0.217.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { sign as jwtSign } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("GCP_SERVICE_ACCOUNT_JSON")!);
const VISION_ENDPOINT = "https://vision.googleapis.com/v1/images:annotate";

interface Body { storage_path?: string; image_base64?: string; }

serve(async (req) => {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);

  // Identify caller
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  // Quota check
  const { data: usage } = await supabase
    .from("ocr_usage").select("count").eq("user_id", user.id)
    .gte("window_start", new Date(Date.now() - 86400_000).toISOString());
  const used = usage?.[0]?.count ?? 0;
  const tier = await getTier(user.id);
  const limit = tier === "FREEMIUM" ? 30 : 200;
  if (used >= limit) return json({ error: "quota_exceeded", resets_at: ... }, 429);

  // Resolve image bytes
  const body = await req.json() as Body;
  let bytes: Uint8Array;
  if (body.storage_path) {
    const { data, error } = await supabase.storage
      .from("prescription-images").download(body.storage_path);
    if (error) return json({ error: "storage_fetch_failed" }, 500);
    bytes = new Uint8Array(await data.arrayBuffer());
  } else if (body.image_base64) {
    bytes = decodeBase64(body.image_base64);
  } else {
    return json({ error: "missing_image" }, 400);
  }

  // Build OAuth token from service account
  const accessToken = await getServiceAccountAccessToken();

  // Call Vision API
  const resp = await fetch(VISION_ENDPOINT, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      requests: [{
        image: { content: encodeBase64(bytes) },
        features: [{ type: "DOCUMENT_TEXT_DETECTION" }],
        imageContext: { languageHints: ["km", "en"] },
      }],
    }),
  });
  if (!resp.ok) return json({ error: "vision_api_failed", detail: await resp.text() }, 502);
  const result = await resp.json();
  const annotation = result.responses?.[0]?.fullTextAnnotation;
  if (!annotation) return json({ blocks: [], average_confidence: 0 });

  // Increment usage
  await supabase.rpc("increment_ocr_usage", { p_user_id: user.id });

  // Convert to engine-agnostic format
  const blocks = annotation.pages?.flatMap((page: any) =>
    page.blocks.map((b: any) => ({
      text: blockText(b),
      confidence: b.confidence,
      bounding_box: b.boundingBox,
      language_hint: dominantLanguage(b),
    }))
  ) ?? [];
  const avgConfidence = blocks.length === 0 ? 0
    : blocks.reduce((s: number, b: any) => s + b.confidence, 0) / blocks.length;
  return json({ engine: "google_vision", blocks, average_confidence: avgConfidence });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { "content-type": "application/json" },
  });
}
async function getServiceAccountAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/cloud-vision",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const privateKey = await importPrivateKey(SERVICE_ACCOUNT.private_key);
  const jwt = await jwtSign(claims, privateKey, "RS256");
  const tokenResp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const j = await tokenResp.json();
  return j.access_token;
}
```

```sql
-- supabase/migrations/20260601000700_ocr_usage.sql
create table public.ocr_usage (
  user_id      uuid not null references public.profiles(id) on delete cascade,
  window_start timestamptz not null default now(),
  count        integer not null default 0,
  primary key (user_id, window_start)
);
alter table public.ocr_usage enable row level security;
alter table public.ocr_usage force row level security;
create policy "ocr_usage_self_select" on public.ocr_usage
  for select using (user_id = auth.uid());

create or replace function public.increment_ocr_usage(p_user_id uuid)
returns void language plpgsql security definer as $$
begin
  insert into public.ocr_usage(user_id, window_start, count)
  values (p_user_id, date_trunc('day', now()), 1)
  on conflict (user_id, window_start) do update set count = ocr_usage.count + 1;
end;
$$;
```

## 8. Field extractor heuristics

```dart
class FieldExtractor {
  FieldExtractor(this._dictionary);
  final MedicationDictionary _dictionary;

  List<MedicationCandidate> extract(OcrResult ocr) {
    final lines = ocr.primary.blocks.expand((b) => b.text.split('\n')).toList();
    final candidates = <MedicationCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 1) Try to match medication name from dictionary
      final nameMatch = _dictionary.bestMatch(line);
      if (nameMatch == null || nameMatch.score < 0.4) continue;

      // 2) Look at adjacent lines (this + next 2) for dosage / frequency
      final ctx = lines.sublist(i, math.min(i + 3, lines.length)).join(' ');
      final dosage = _extractDosage(ctx);
      final freq = _extractFrequency(ctx);
      final beforeMeal = _extractMealRelation(ctx);
      final duration = _extractDuration(ctx);

      candidates.add(MedicationCandidate(
        medicineName: nameMatch.canonicalName,
        medicineNameKhmer: nameMatch.khmerName,
        dosageAmount: dosage?.amount,
        unit: dosage?.unit,
        frequency: freq,
        beforeMeal: beforeMeal,
        duration: duration,
        confidence: (nameMatch.score
                   + (dosage != null ? 1 : 0)
                   + (freq != null ? 1 : 0)) / 3,
        sourceText: ctx,
      ));
    }
    return _dedupe(candidates);
  }

  Dosage? _extractDosage(String s) {
    final r = RegExp(r'(\d+(?:\.\d+)?)\s*(mg|mcg|ml|tab(?:let)?s?|cap(?:sule)?s?|drops?|គ្រាប់|មីលីក្រាម|មីលីលីត្រ)',
                     caseSensitive: false);
    final m = r.firstMatch(s);
    if (m == null) return null;
    return Dosage(amount: double.parse(m.group(1)!), unit: _normalizeUnit(m.group(2)!));
  }

  String? _extractFrequency(String s) {
    final patterns = [
      (RegExp(r'\bBID\b|twice\s*daily|2\s*x\s*day|ពីរដងក្នុងមួយថ្ងៃ', caseSensitive: false), 'twice daily'),
      (RegExp(r'\bTID\b|three\s*times\s*daily|3\s*x\s*day|បីដងក្នុងមួយថ្ងៃ', caseSensitive: false), 'three times daily'),
      (RegExp(r'\bQID\b|four\s*times\s*daily|4\s*x\s*day', caseSensitive: false), 'four times daily'),
      (RegExp(r'\bOD\b|once\s*daily|1\s*x\s*day|មួយដងក្នុងមួយថ្ងៃ', caseSensitive: false), 'once daily'),
      (RegExp(r'\bPRN\b|as\s*needed|when\s*needed|នៅពេលចាំបាច់', caseSensitive: false), 'as needed'),
    ];
    for (final (re, label) in patterns) {
      if (re.hasMatch(s)) return label;
    }
    return null;
  }
  ...
}
```

## 9. Review screen UI

```dart
class OcrReviewPage extends ConsumerStatefulWidget {
  ...
}

class _State extends ConsumerState<OcrReviewPage> {
  late List<MedicationCandidate> _candidates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Expanded(child: OriginalImagePane(imagePath: widget.imagePath)),
        Expanded(child: ListView(
          children: [
            for (var i = 0; i < _candidates.length; i++)
              MedicationCandidateCard(
                candidate: _candidates[i],
                onChanged: (next) => setState(() => _candidates[i] = next),
                onRemove: () => setState(() => _candidates.removeAt(i)),
              ),
            FilledButton.icon(icon: Icon(Icons.add),
                              label: Text('Add medication manually'),
                              onPressed: _addBlank),
            const SizedBox(height: 24),
            FilledButton(child: Text('Save prescription'), onPressed: _onSave),
            TextButton(child: Text('Reject all and enter manually'), onPressed: _onReject),
          ],
        )),
      ]),
    );
  }
}
```

## 10. Performance optimization

- Run ML Kit + Tesseract in parallel using `compute` (Dart isolate) when possible.
- Cache Tesseract engine instance across scans.
- Show partial UI: show "1 medication found" while still extracting.
- Resize image to max 2000px before any engine to avoid memory pressure.

## 11. Testing

- Unit: dosage regex, frequency keyword detection, language heuristic.
- Unit: pipeline routing decisions (low conf → Khmer engine; both low → cloud).
- Widget: Review screen renders candidates with confidence chips, edit works.
- Integration: known fixture image in assets → expected candidate set.
- Edge Function: mocked Vision response returns expected blocks; quota limit returns 429.

## 12. Privacy decisions

- All Storage paths scoped per `patient_id`.
- Cloud OCR opt-in: a setting "Allow cloud OCR fallback" defaults to ON but can be turned off; when off, the pipeline never calls the Edge Function.
- Raw OCR text stored in `ocr_metadata.raw_text` is truncated to 5000 chars and never logged.

## 13. Open issues

- Tesseract Flutter packages have varying maintenance status; final pick (`flutter_tesseract_ocr` vs `flusseract`) tracked in `00-overview/design.md` decision log.
- Vision API costs scale with calls; monitor usage in production and tune the cloud-fallback threshold.
- `cunning_document_scanner` provides a much better UX but only works on Android with ML Kit Document Scanner; iOS uses VisionKit. Track as enhancement.
