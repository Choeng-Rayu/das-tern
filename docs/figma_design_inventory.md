# Figma Design Inventory - DasTern (ដាស់តឿន)

> **Source**: [Figma File](https://www.figma.com/design/zdfPXv7BbGNKPfBPAAwg5p/%E1%9E%8A%E1%9E%B6%E1%9E%9F%E1%9F%8B%E1%9E%8F%E1%9E%BF%E1%9E%93)
> **Extracted**: 2026-02-07

---

## 1. Figma File Structure

### Pages

| Page | Description |
|------|-------------|
| **01. Getting Started** | All app screens and flows |
| **02. Foundation** | Design tokens (Border, Breakpoint, Colors, Effects, Motion, Space, Typography) |
| **03. Components** | Reusable UI component library |
| **04. Misc** | File thumbnails, Time Machine |

---

## 2. Screen Inventory (01. Getting Started)

### 2.1 Authentication Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Starting page | `3:38` | Welcome/landing page with "បង្កើតគណនីថ្មី" (Create New Account), "បានបង្កើតគណនីពីមុន" (Already have account), "ចូលប្រើប្រាស់ជាគ្រូពេទ្យ" (Login as Doctor) |
| Sign up (Step 1) | `33:19` | Registration form: នាមត្រកូល (Last name), នាមខ្លួន (First name), ភេទ (Gender), ថ្ងៃ ខែ ឆ្នាំ កំណើត (DOB), លេខអត្តសញ្ញាណប័ណ្ណ (ID Number) |
| Sign up (Step 1 - duplicate) | `1530:680` | Same as above (variant/copy) |
| Sign up-2 (Step 2) | `33:63` | Phone, password, confirm password, 4-digit code, terms & conditions |
| Log in | `33:213` | Login with phone number (លេខទូរស័ព្ទ) and password (លេខកូខសម្ងាត់), forgot password link |

### 2.2 Survey / Meal Time Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Morning Meal Time page | `229:112` | "តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលព្រឹក?" - Time slots: 6-7AM, 7-8AM, 8-9AM, 9-10AM |
| Afternoon Meal Time page | `234:187` | "តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលរសៀល?" - Time slots: 12-1PM, 1-2PM, 2-3PM, 4-5PM |
| Night Meal Time page | `242:243` | "តើអ្នកទទួលទានអារហារជាធម្មតាម៉ោងប៉ុន្មាននៅពេលយប់?" - Evening time slots |
| Night Meal Time page (variant) | `795:561` | Duplicate/variant |

### 2.3 Patient Homepage & Dashboard

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Homepage | `33:279` | Patient main screen: greeting, reminders (morning/afternoon/night), overview (23 days tracker), medication duration progress, key features (family, reminders, scan prescription) |
| Homepage-Notifications | `860:589` | Homepage with notification popup: "សូមទទួលទានថ្នាំពេលរសៀរនេះ" with "យល់ព្រម" and "ចាំ 15 នាទីទៀត" |
| Medicine schedule | `290:146` | Medicine analysis page with daily schedule, calendar, time-based grouping |

### 2.4 Medicine Detail Screens (Morning - ពេលព្រឹក)

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Pel prik p1 | `303:159` | Morning medicine list: ថ្នាំបារ៉ា, អ៊ីប៊ុយប្រូហ្វេន, ឡូរ៉ាតាឌីន (1 គ្រាប់ each), status: "មិនទាន់រួចរាល់" |
| Pel prik p2 | `313:137` | Morning medicine list with "រួចរាល់" (completed) status |
| Prek Detail 1 | `314:281` | Morning medicine detail view |
| Prek Detail 2 | `365:155` | Morning medicine detail view |
| Prek Detail 3 | `406:189` | Morning medicine detail view |
| Prek Detail 5 | `507:331` | Morning medicine detail view |
| Calender Detail 4 | `481:302` | Calendar with medicine detail |

### 2.5 Medicine Detail Screens (Afternoon - ពេលថ្ងៃ)

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| pel tngai p1 | `406:240` | Afternoon medicine list |
| pel tngai p2 | `406:407` | Afternoon medicine list (11:00 ថ្ងៃ) |
| tngai Detail 1 | `406:621` | Afternoon medicine detail |
| tngai Detail 2 | `406:659` | Afternoon medicine detail |

### 2.6 Medicine Detail Screens (Night - ពេលយប់)

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| pel yub p1 | `406:286` | Night medicine list |
| pel yub p2 | `406:346` | Night medicine list (7:00 យប់) |
| pel yub detail 1 | `406:498` | Night medicine detail |
| pel yub detail 2 | `406:544` | Night medicine detail |
| pel yub detail 3 | `406:582` | Night medicine detail |
| pel yub detail 6 | `1049:1311` | Night medicine detail |

### 2.7 Prescription Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Presciption for Patient | `333:239` | Prescription document: "បទបញ្ជាលេបថ្នាំសម្រាប់ សុខឡាង" |
| Presciption for Patient (v2) | `787:416` | Updated prescription view |
| Presciption for Patient (v3) | `811:515` | Another prescription variant |
| scanning | `75:50` | QR/barcode scanning screen |
| scanning (v2) | `570:352` | Scanning variant |

### 2.8 Family Feature Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Family Feature- homePage | `565:326` | Family feature introduction with description of benefits and "ចូលប្រើប្រាស់" / "យល់ដឹងបន្ថែម" buttons |
| Family Feature- Code scan | `570:424` | QR scan/code entry for family connection: "abc-23-04-2005" code format |
| FamiyPage | `1084:625` | Family page with connected patient list (search, patient cards with medication status) |
| FaimlyPage-patient detail | `1189:632` | Connected patient detail view: info, current prescription, missed medication alerts, "ផ្ដាច់ដំណរភ្ជាប់" (disconnect) |
| FamilyPage_PatientDetail | `1036:926` | Patient detail component |
| FamilyPage-Notifications | `1044:847` | Family page with notifications |
| Family-ConnectFamilyLink | `1044:1056` | Family connection link screen |

### 2.9 Doctor Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Doctor-Home page | `600:353` | Doctor dashboard: greeting, notifications (missed medication alerts), statistics (04 missed patients, 20 in treatment), weekly chart, bottom nav |
| Doctor- Patient Follow up | `634:406` | Patient follow-up list: search, patient cards with name, symptoms, medication status |
| Doctor- Patient Follow up- Patient Information | `773:571` | Patient detail: personal info, missed count, current prescription (medicines, dosage, timing) |
| Doctor- Patient Record | `782:811` | Patient records list with search |
| Doctor- Patient Follow up- Patient Record- detail | `782:953` | Patient record detail: prescription history, download data option |
| Doctor-Prescription | `822:542` | Create prescription form: patient info (name, symptoms, gender, age), medicines (name, frequency, duration, quantity, timing) |
| Doctor- Setting | `792:506` | Doctor settings: ប្រវត្តិរូប, ការជូនដំណឹង, ភាសា, សុវត្ថិភាព, អំពីពួកយើង, ចាកចេញ |
| Doctor- Setting- Persoanl Account | `792:700` | Profile editing: phone, photo, DOB |
| Doctor- Setting-​Notification | `792:864` | Notification settings with toggles |
| Doctor- Setting-​Security | `792:921` | Security: change password (old password, new password) |

### 2.10 User Settings Screens

| Screen Name | Figma ID | Description |
|-------------|----------|-------------|
| Usersetting-khmer | `840:581` | Patient settings: ប្រវត្តិរូប, ការជូនដំណឹង, ភ្ជាប់ជាមួយសមាជិកគ្រួសារ, ពេលវេលាកំណតការហូបអាហារ, ភាសា, សុវត្ថិភាព, អំពីពួកយើង, ចាកចេញ |
| Usersetting- family link-khmer | `837:560` | Family link settings |
| ProfileInfo | `438:303` | Profile info (English) |
| ProfileInfo- Khmer | `770:371` | Profile info (Khmer) |
| ProfileInfo-phonenumber | `465:281` | Phone number edit |
| Notification-turn off | `454:363` | Notifications disabled (English) |
| Notification-turn off-khmer | `779:389` | Notifications disabled (Khmer) |
| Notification-turn in | `495:368` | Notifications enabled (English) |
| Notification-turn in-khmer | `779:435` | Notifications enabled (Khmer): toggles for medication reminders, missed dose alerts, family member notifications |
| User- Setting-​Security | `840:700` | User security settings |
| Usersetting-aboutus-english | `478:316` | About Us (English) |
| about us -khmer | `779:518` | About Us (Khmer) |
| language-khmer choice | `854:782` | Language selection |
| choice-khmer | `839:577` | Choice/selection screen |
| mealtime when not set yet-khmer | `795:461` | Meal time settings (not set) |
| after set meal time-khmer | `823:551` | Meal time settings (set) |
| breakfast-khmer | `860:761` | Breakfast time picker |
| after pick breakfast-khmer | `806:652` | After breakfast time selected |
| bay​ tngai-khmer | `797:523` | Lunch time picker |
| after pick lunch-khmer | `806:547` | After lunch time selected |
| bay yub-khmer | `797:584` | Dinner time picker |
| ater pick dinner-khmer | `806:515` | After dinner time selected |
| user role | `781:562` | User role selection |
| Phonenumber-info | `471:290` | Phone number info |
| Phonenumber-info-khmer | `779:482` | Phone number info (Khmer) |

---

## 3. Navigation Structure

### Patient Bottom Navigation (5 tabs)

| Tab | Icon | Label (Khmer) | Label (English) |
|-----|------|---------------|-----------------|
| 1 | 🏠 | ទំព័រដើម | Home |
| 2 | 📊 | ការវិភាគថ្នាំ | Medicine Analysis |
| 3 | 📷 | ស្កេនវេជ្ជបញ្ជា | Scan Prescription |
| 4 | 👨‍👩‍👧 | មុខងារគ្រួសារ | Family Feature |
| 5 | ⚙️ | ការកំណត់ | Settings |

### Doctor Bottom Navigation (5 tabs)

| Tab | Icon | Label (Khmer) | Label (English) |
|-----|------|---------------|-----------------|
| 1 | 🏠 | ទំព័រដើម | Home |
| 2 | 👥 | តាមដានអ្នកជំងឺ | Patient Follow-up |
| 3 | 📝 | បង្កើតវេជ្ជបញ្ជា | Create Prescription |
| 4 | 📋 | ប្រវិត្តវេជ្ជបញ្ជារ | Prescription History |
| 5 | ⚙️ | ការកំណត់ | Settings |

---

## 4. Design Tokens (from Figma)

### Frame Size
- **Target Device**: iPhone 14 & 15 Pro Max
- **Frame Size**: 430 x 932 (standard), some screens extend to 1102–1495 (scrollable)

### Typography (extracted from screens)

| Usage | Size | Weight | Example |
|-------|------|--------|---------|
| Page Title | 30-36px | 700-800 | "ការវិភាគថ្នាំ", "មុខងារគ្រួសារ" |
| Section Header | 20-24px | 400-700 | "ទិដ្ឋភាពទូទៅ", "ការរំលឹក (ថ្ងៃនេះ)" |
| App Name | 20px | 700 | "ដាស់តឿន" |
| Greeting | 30px | 800 | "សួស្តី​ សុខឡាង !" |
| Card Title | 16px | 300-400 | "ថ្នាំបារ៉ា", "ពេលព្រឹក" |
| Body Text | 16px | 300 | Form labels, descriptions |
| Small Text | 12px | 300 | Status, details |
| Caption | 10px | 200-400 | Navigation labels, timestamps |
| Button Text | 20px | 700 | "បន្ត", "ចូលគណនី" |
| Large Button | 32px | 700 | "បន្ត" (survey) |
| Large Stats | 48px | 800 | "04", "20" (dashboard counters) |
| Stats Label | 24px | 800 | "23 ថ្ងៃ" |
| Placeholder | 16px | 200 | Input placeholders |

### Key UI Patterns

| Pattern | Description |
|---------|-------------|
| **Header** | Logo "ដាស់តឿន" (20px bold) + notification badge + profile |
| **Greeting** | "សួស្តី​ [Name] !" (30px, 800 weight) |
| **Card Layout** | Rounded rectangle with image, name, details, action |
| **Status Badge** | "ទទួលទានថ្នាំ" (green) / "មិនបានទទួលទានថ្នាំ" (red) |
| **Notification Popup** | Overlay with message, "យល់ព្រម" and "ចាំ 15 នាទីទៀត" |
| **Bottom Nav** | 5 tabs with icon + Khmer label |

---

## 5. Component Library (03. Components)

### Actions
- Button, Button Group, Page Actions

### Data Visualisation
- Charts and Graphs

### Feedback Indicators
- Annotation, Badge, Banner, Progress Bar, Scrollbar, Spinner, Stepper, Toast

### Image & Icons
- Avatar, Icon, Thumbnail

### Layout & Structure
- Accordion, Card, Divider, Empty State, Form Layout, Grid, Layout, Tables

### Navigation
- Breadcrumb, Footer Help, Link, Navigation, Pagination, Tabs, Top Bar

### Overlays
- Drawer, Modal, Popover, Tooltip

### Selection & Input
- Checkbox, Color Picker, Combobox, Date Picker, Dropdown, Drop Zone, Filters, Inline Error, Radio Button, Range Slider, Select, Switch, Tag, Text Input, Time Picker

---

## 6. Key Differences from Current Documentation

### Login Screen
- **Figma**: Uses "លេខទូរស័ព្ទ" (Phone) and "លេខកូខសម្ងាត់" (Password/PIN) — NOT email
- **Current Doc**: References phone/email — needs update to match Figma (phone-only)
- **Figma**: Forgot password text is "ភ្លេចលេខកូខសម្ងាត់" (Forgot PIN code)

### Registration
- **Figma**: 2-step process:
  - Step 1: នាមត្រកូល (Last name), នាមខ្លួន (First name), ភេទ (Gender), ថ្ងៃ ខែ ឆ្នាំ កំណើត (DOB), លេខអត្តសញ្ញាណប័ណ្ណ (ID number)
  - Step 2: លេខទូរស័ព្ទ (Phone), លេខកូខសម្ងាត់ (Password), បញ្ជាក់លេខកូខសម្ងាត់ (Confirm), លេខកូខ៤ខ្ទង់ (4-digit PIN), Terms
- **Current Doc**: Different field set — needs update

### Bottom Navigation (Patient)
- **Figma**: 5 tabs: ទំព័រដើម, ការវិភាគថ្នាំ, ស្កេនវេជ្ជបញ្ជា, មុខងារគ្រួសារ, ការកំណត់
- **Current Doc**: 4 tabs — needs update to 5 tabs

### Bottom Navigation (Doctor)
- **Figma**: 5 tabs: ទំព័រដើម, តាមដានអ្នកជំងឺ, បង្កើតវេជ្ជបញ្ជា, ប្រវិត្តវេជ្ជបញ្ជារ, ការកំណត់
- **Current Doc**: 4 tabs — needs update to 5 tabs

### Patient Homepage
- **Figma**: Includes overview section with medication duration tracker, key features section (family, reminders, scan prescription)
- **Current Doc**: Missing overview and key features sections

### Survey/Meal Time
- **Figma**: Full meal time survey flow (morning/afternoon/night) — not well documented

---

*Generated from Figma API extraction on 2026-02-07*
