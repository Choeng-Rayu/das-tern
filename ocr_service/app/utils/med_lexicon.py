"""
med_lexicon.py - Fuzzy matching loader and matcher for medication names.

Loads medication lexicons (English and Khmer) from text files and provides
fuzzy matching, brand-to-generic mapping, and therapeutic class lookup.
"""

from __future__ import annotations

import os
from typing import Optional

from rapidfuzz import fuzz, process


# ---------------------------------------------------------------------------
# Brand-name to generic-name mapping
# ---------------------------------------------------------------------------
BRAND_TO_GENERIC: dict[str, str] = {
    # Analgesics / NSAIDs
    "Celcoxx": "Celecoxib",
    "Celebrex": "Celecoxib",
    "Tylenol": "Acetaminophen",
    "Panadol": "Paracetamol",
    "Advil": "Ibuprofen",
    "Motrin": "Ibuprofen",
    "Nurofen": "Ibuprofen",
    "Voltaren": "Diclofenac",
    "Cataflam": "Diclofenac",
    "Aleve": "Naproxen",
    "Mobic": "Meloxicam",
    "Feldene": "Piroxicam",
    "Arcoxia": "Etoricoxib",
    "Toradol": "Ketorolac",
    "Ultram": "Tramadol",
    # Antibiotics
    "Augmentin": "Co-Amoxiclav",
    "Amoxil": "Amoxicillin",
    "Zithromax": "Azithromycin",
    "Ciprobay": "Ciprofloxacin",
    "Flagyl": "Metronidazole",
    "Klacid": "Clarithromycin",
    "Biaxin": "Clarithromycin",
    "Vibramycin": "Doxycycline",
    "Keflex": "Cefalexin",
    "Rocephin": "Ceftriaxone",
    "Suprax": "Cefixime",
    "Zinnat": "Cefuroxime",
    "Bactrim": "Cotrimoxazole",
    "Tavanic": "Levofloxacin",
    "Avelox": "Moxifloxacin",
    # Gastrointestinal
    "Losec": "Omeprazole",
    "Prilosec": "Omeprazole",
    "Nexium": "Esomeprazole",
    "Prevacid": "Lansoprazole",
    "Protonix": "Pantoprazole",
    "Pariet": "Rabeprazole",
    "Zantac": "Ranitidine",
    "Pepcid": "Famotidine",
    "Motilium": "Domperidone",
    "Imodium": "Loperamide",
    "Buscopan": "Butylscopolamine",
    "Carafate": "Sucralfate",
    "Cytotec": "Misoprostol",
    # Cardiovascular
    "Norvasc": "Amlodipine",
    "Lipitor": "Atorvastatin",
    "Zocor": "Simvastatin",
    "Crestor": "Rosuvastatin",
    "Cozaar": "Losartan",
    "Diovan": "Valsartan",
    "Atacand": "Candesartan",
    "Micardis": "Telmisartan",
    "Vasotec": "Enalapril",
    "Zestril": "Lisinopril",
    "Prinivil": "Lisinopril",
    "Altace": "Ramipril",
    "Capoten": "Captopril",
    "Inderal": "Propranolol",
    "Tenormin": "Atenolol",
    "Lopressor": "Metoprolol",
    "Toprol": "Metoprolol",
    "Concor": "Bisoprolol",
    "Adalat": "Nifedipine",
    "Cardizem": "Diltiazem",
    "Isoptin": "Verapamil",
    "Lasix": "Furosemide",
    "Aldactone": "Spironolactone",
    "Coumadin": "Warfarin",
    "Plavix": "Clopidogrel",
    "Lanoxin": "Digoxin",
    "Imdur": "Isosorbide Mononitrate",
    # Diabetes
    "Glucophage": "Metformin",
    "Amaryl": "Glimepiride",
    "Diamicron": "Gliclazide",
    "Glucotrol": "Glipizide",
    "Januvia": "Sitagliptin",
    "Trajenta": "Linagliptin",
    "Forxiga": "Dapagliflozin",
    "Actos": "Pioglitazone",
    # CNS / Psychiatric
    "Prozac": "Fluoxetine",
    "Paxil": "Paroxetine",
    "Zoloft": "Sertraline",
    "Effexor": "Venlafaxine",
    "Remeron": "Mirtazapine",
    "Elavil": "Amitriptyline",
    "Seroquel": "Quetiapine",
    "Zyprexa": "Olanzapine",
    "Risperdal": "Risperidone",
    "Haldol": "Haloperidol",
    "Valium": "Diazepam",
    "Xanax": "Alprazolam",
    "Ativan": "Lorazepam",
    "Klonopin": "Clonazepam",
    "Ambien": "Zolpidem",
    "Neurontin": "Gabapentin",
    "Tegretol": "Carbamazepine",
    "Depakote": "Divalproex",
    "Keppra": "Levetiracetam",
    "Dilantin": "Phenytoin",
    "Trileptal": "Oxcarbazepine",
    "Aricept": "Donepezil",
    "Namenda": "Memantine",
    # Respiratory
    "Ventolin": "Salbutamol",
    "Proventil": "Albuterol",
    "Singulair": "Montelukast",
    "Zyrtec": "Cetirizine",
    "Xyzal": "Levocetirizine",
    "Claritin": "Loratadine",
    "Allegra": "Fexofenadine",
    "Benadryl": "Diphenhydramine",
    "Piriton": "Chlorpheniramine",
    "Mucosolvan": "Ambroxol",
    "Bisolvon": "Bromhexine",
    "Pulmicort": "Budesonide",
    "Flixotide": "Fluticasone",
    # Antifungals
    "Diflucan": "Fluconazole",
    "Nizoral": "Ketoconazole",
    "Sporanox": "Itraconazole",
    "Lamisil": "Terbinafine",
    # Antivirals
    "Zovirax": "Acyclovir",
    "Tamiflu": "Oseltamivir",
    # Corticosteroids
    "Medrol": "Methylprednisolone",
    "Deltasone": "Prednisone",
    # Thyroid
    "Synthroid": "Levothyroxine",
    "Eltroxin": "Levothyroxine",
    # Urological
    "Flomax": "Tamsulosin",
    # Antiparasitics
    "Vermox": "Mebendazole",
    "Zentel": "Albendazole",
    "Stromectol": "Ivermectin",
    # Vitamins (alternate spellings)
    "Multivitamine": "Multivitamin",
}


# ---------------------------------------------------------------------------
# Therapeutic class mapping
# ---------------------------------------------------------------------------
THERAPEUTIC_CLASSES: dict[str, str] = {
    # Analgesics / Antipyretics
    "Acetaminophen": "Analgesic / Antipyretic",
    "Paracetamol": "Analgesic / Antipyretic",
    # NSAIDs
    "Aspirin": "NSAID / Antiplatelet",
    "Celecoxib": "NSAID (COX-2 Inhibitor)",
    "Celcoxx": "NSAID (COX-2 Inhibitor)",
    "Diclofenac": "NSAID",
    "Etoricoxib": "NSAID (COX-2 Inhibitor)",
    "Ibuprofen": "NSAID",
    "Indomethacin": "NSAID",
    "Ketoprofen": "NSAID",
    "Ketorolac": "NSAID",
    "Meloxicam": "NSAID",
    "Naproxen": "NSAID",
    "Piroxicam": "NSAID",
    # Opioid Analgesics
    "Codeine": "Opioid Analgesic",
    "Fentanyl": "Opioid Analgesic",
    "Morphine": "Opioid Analgesic",
    "Oxycodone": "Opioid Analgesic",
    "Tramadol": "Opioid Analgesic",
    # Antibiotics - Penicillins
    "Amoxicillin": "Antibiotic (Penicillin)",
    "Ampicillin": "Antibiotic (Penicillin)",
    "Co-Amoxiclav": "Antibiotic (Penicillin + Beta-lactamase Inhibitor)",
    "Cloxacillin": "Antibiotic (Penicillin)",
    "Penicillin V": "Antibiotic (Penicillin)",
    # Antibiotics - Cephalosporins
    "Cefalexin": "Antibiotic (Cephalosporin)",
    "Cefaclor": "Antibiotic (Cephalosporin)",
    "Cefadroxil": "Antibiotic (Cephalosporin)",
    "Cefazolin": "Antibiotic (Cephalosporin)",
    "Cefdinir": "Antibiotic (Cephalosporin)",
    "Cefixime": "Antibiotic (Cephalosporin)",
    "Cefotaxime": "Antibiotic (Cephalosporin)",
    "Cefpodoxime": "Antibiotic (Cephalosporin)",
    "Ceftazidime": "Antibiotic (Cephalosporin)",
    "Ceftriaxone": "Antibiotic (Cephalosporin)",
    "Cefuroxime": "Antibiotic (Cephalosporin)",
    # Antibiotics - Macrolides
    "Azithromycin": "Antibiotic (Macrolide)",
    "Clarithromycin": "Antibiotic (Macrolide)",
    "Erythromycin": "Antibiotic (Macrolide)",
    # Antibiotics - Fluoroquinolones
    "Ciprofloxacin": "Antibiotic (Fluoroquinolone)",
    "Levofloxacin": "Antibiotic (Fluoroquinolone)",
    "Moxifloxacin": "Antibiotic (Fluoroquinolone)",
    "Norfloxacin": "Antibiotic (Fluoroquinolone)",
    "Ofloxacin": "Antibiotic (Fluoroquinolone)",
    # Antibiotics - Tetracyclines
    "Doxycycline": "Antibiotic (Tetracycline)",
    "Tetracycline": "Antibiotic (Tetracycline)",
    # Antibiotics - Other
    "Amikacin": "Antibiotic (Aminoglycoside)",
    "Chloramphenicol": "Antibiotic",
    "Clindamycin": "Antibiotic (Lincosamide)",
    "Cotrimoxazole": "Antibiotic (Sulfonamide)",
    "Gentamicin": "Antibiotic (Aminoglycoside)",
    "Imipenem": "Antibiotic (Carbapenem)",
    "Metronidazole": "Antibiotic / Antiprotozoal",
    "Neomycin": "Antibiotic (Aminoglycoside)",
    "Nitrofurantoin": "Antibiotic (Urinary)",
    "Trimethoprim": "Antibiotic",
    "Vancomycin": "Antibiotic (Glycopeptide)",
    # Antifungals
    "Clotrimazole": "Antifungal",
    "Fluconazole": "Antifungal",
    "Griseofulvin": "Antifungal",
    "Itraconazole": "Antifungal",
    "Ketoconazole": "Antifungal",
    "Miconazole": "Antifungal",
    "Nystatin": "Antifungal",
    "Terbinafine": "Antifungal",
    "Voriconazole": "Antifungal",
    # Antivirals
    "Acyclovir": "Antiviral",
    "Lamivudine": "Antiviral (Antiretroviral)",
    "Nevirapine": "Antiviral (Antiretroviral)",
    "Oseltamivir": "Antiviral",
    "Ritonavir": "Antiviral (Antiretroviral)",
    "Tenofovir": "Antiviral (Antiretroviral)",
    "Zidovudine": "Antiviral (Antiretroviral)",
    # Antiparasitics
    "Albendazole": "Anthelmintic",
    "Ivermectin": "Antiparasitic",
    "Mebendazole": "Anthelmintic",
    "Praziquantel": "Anthelmintic",
    # Antimalarials
    "Artemether": "Antimalarial",
    "Artesunate": "Antimalarial",
    "Chloroquine": "Antimalarial",
    "Hydroxychloroquine": "Antimalarial / DMARD",
    "Lumefantrine": "Antimalarial",
    "Mefloquine": "Antimalarial",
    "Primaquine": "Antimalarial",
    "Quinine": "Antimalarial",
    # Anti-TB
    "Ethambutol": "Anti-Tuberculosis",
    "Isoniazid": "Anti-Tuberculosis",
    "Pyrazinamide": "Anti-Tuberculosis",
    "Rifampicin": "Anti-Tuberculosis",
    # Gastrointestinal
    "Butylscopolamine": "Antispasmodic",
    "Domperidone": "Prokinetic / Antiemetic",
    "Esomeprazole": "Proton Pump Inhibitor",
    "Famotidine": "H2 Receptor Antagonist",
    "Lactulose": "Laxative",
    "Lansoprazole": "Proton Pump Inhibitor",
    "Loperamide": "Antidiarrheal",
    "Metoclopramide": "Prokinetic / Antiemetic",
    "Misoprostol": "Prostaglandin Analogue",
    "Omeprazole": "Proton Pump Inhibitor",
    "Ondansetron": "Antiemetic (5-HT3 Antagonist)",
    "Pantoprazole": "Proton Pump Inhibitor",
    "Rabeprazole": "Proton Pump Inhibitor",
    "Ranitidine": "H2 Receptor Antagonist",
    "Sucralfate": "Mucosal Protectant",
    "Bisacodyl": "Laxative",
    "Oral Rehydration Salts": "Oral Rehydration Therapy",
    # Cardiovascular - Antihypertensives
    "Amlodipine": "Calcium Channel Blocker",
    "Atenolol": "Beta Blocker",
    "Benazepril": "ACE Inhibitor",
    "Bisoprolol": "Beta Blocker",
    "Candesartan": "Angiotensin II Receptor Blocker",
    "Captopril": "ACE Inhibitor",
    "Carvedilol": "Beta Blocker",
    "Clonidine": "Antihypertensive (Central Alpha-2 Agonist)",
    "Diltiazem": "Calcium Channel Blocker",
    "Enalapril": "ACE Inhibitor",
    "Felodipine": "Calcium Channel Blocker",
    "Hydralazine": "Vasodilator",
    "Hydrochlorothiazide": "Diuretic (Thiazide)",
    "Indapamide": "Diuretic (Thiazide-like)",
    "Irbesartan": "Angiotensin II Receptor Blocker",
    "Lisinopril": "ACE Inhibitor",
    "Losartan": "Angiotensin II Receptor Blocker",
    "Methyldopa": "Antihypertensive",
    "Metoprolol": "Beta Blocker",
    "Nebivolol": "Beta Blocker",
    "Nicardipine": "Calcium Channel Blocker",
    "Nifedipine": "Calcium Channel Blocker",
    "Prazosin": "Alpha Blocker",
    "Propranolol": "Beta Blocker",
    "Ramipril": "ACE Inhibitor",
    "Telmisartan": "Angiotensin II Receptor Blocker",
    "Trandolapril": "ACE Inhibitor",
    "Valsartan": "Angiotensin II Receptor Blocker",
    "Verapamil": "Calcium Channel Blocker",
    # Cardiovascular - Lipid Lowering
    "Atorvastatin": "Statin (HMG-CoA Reductase Inhibitor)",
    "Fenofibrate": "Fibrate",
    "Fluvastatin": "Statin (HMG-CoA Reductase Inhibitor)",
    "Lovastatin": "Statin (HMG-CoA Reductase Inhibitor)",
    "Rosuvastatin": "Statin (HMG-CoA Reductase Inhibitor)",
    "Simvastatin": "Statin (HMG-CoA Reductase Inhibitor)",
    # Cardiovascular - Other
    "Amiodarone": "Antiarrhythmic",
    "Clopidogrel": "Antiplatelet",
    "Digoxin": "Cardiac Glycoside",
    "Enoxaparin": "Anticoagulant (LMWH)",
    "Glyceryl Trinitrate": "Nitrate (Vasodilator)",
    "Heparin": "Anticoagulant",
    "Isosorbide Dinitrate": "Nitrate (Vasodilator)",
    "Isosorbide Mononitrate": "Nitrate (Vasodilator)",
    "Nitroglycerin": "Nitrate (Vasodilator)",
    "Warfarin": "Anticoagulant",
    # Diuretics
    "Amiloride": "Diuretic (Potassium-Sparing)",
    "Bumetanide": "Diuretic (Loop)",
    "Furosemide": "Diuretic (Loop)",
    "Spironolactone": "Diuretic (Potassium-Sparing)",
    # Diabetes
    "Dapagliflozin": "Antidiabetic (SGLT2 Inhibitor)",
    "Gliclazide": "Antidiabetic (Sulfonylurea)",
    "Glimepiride": "Antidiabetic (Sulfonylurea)",
    "Glipizide": "Antidiabetic (Sulfonylurea)",
    "Insulin": "Antidiabetic (Insulin)",
    "Linagliptin": "Antidiabetic (DPP-4 Inhibitor)",
    "Metformin": "Antidiabetic (Biguanide)",
    "Pioglitazone": "Antidiabetic (Thiazolidinedione)",
    "Sitagliptin": "Antidiabetic (DPP-4 Inhibitor)",
    # Respiratory
    "Albuterol": "Bronchodilator (Beta-2 Agonist)",
    "Aminophylline": "Bronchodilator (Methylxanthine)",
    "Beclomethasone": "Inhaled Corticosteroid",
    "Budesonide": "Inhaled Corticosteroid",
    "Fluticasone": "Inhaled Corticosteroid",
    "Ipratropium": "Bronchodilator (Anticholinergic)",
    "Montelukast": "Leukotriene Receptor Antagonist",
    "Salbutamol": "Bronchodilator (Beta-2 Agonist)",
    "Salmeterol": "Bronchodilator (LABA)",
    "Terbutaline": "Bronchodilator (Beta-2 Agonist)",
    "Theophylline": "Bronchodilator (Methylxanthine)",
    # Antihistamines
    "Cetirizine": "Antihistamine (2nd Generation)",
    "Chlorpheniramine": "Antihistamine (1st Generation)",
    "Clemastine": "Antihistamine (1st Generation)",
    "Diphenhydramine": "Antihistamine (1st Generation)",
    "Fexofenadine": "Antihistamine (2nd Generation)",
    "Hydroxyzine": "Antihistamine (1st Generation)",
    "Levocetirizine": "Antihistamine (2nd Generation)",
    "Loratadine": "Antihistamine (2nd Generation)",
    "Promethazine": "Antihistamine / Antiemetic",
    # Mucolytics / Expectorants
    "Acetylcysteine": "Mucolytic",
    "Ambroxol": "Mucolytic",
    "Bromhexine": "Mucolytic",
    "Dextromethorphan": "Antitussive",
    "Guaifenesin": "Expectorant",
    # Corticosteroids
    "Betamethasone": "Corticosteroid",
    "Clobetasol": "Corticosteroid (Topical)",
    "Dexamethasone": "Corticosteroid",
    "Fludrocortisone": "Corticosteroid (Mineralocorticoid)",
    "Hydrocortisone": "Corticosteroid",
    "Methylprednisolone": "Corticosteroid",
    "Prednisolone": "Corticosteroid",
    "Prednisone": "Corticosteroid",
    "Triamcinolone": "Corticosteroid",
    # CNS - Antidepressants
    "Amitriptyline": "Antidepressant (TCA)",
    "Fluoxetine": "Antidepressant (SSRI)",
    "Mirtazapine": "Antidepressant (NaSSA)",
    "Nortriptyline": "Antidepressant (TCA)",
    "Paroxetine": "Antidepressant (SSRI)",
    "Sertraline": "Antidepressant (SSRI)",
    "Venlafaxine": "Antidepressant (SNRI)",
    # CNS - Antipsychotics
    "Chlorpromazine": "Antipsychotic (Typical)",
    "Haloperidol": "Antipsychotic (Typical)",
    "Olanzapine": "Antipsychotic (Atypical)",
    "Quetiapine": "Antipsychotic (Atypical)",
    "Risperidone": "Antipsychotic (Atypical)",
    # CNS - Anxiolytics / Sedatives
    "Alprazolam": "Benzodiazepine (Anxiolytic)",
    "Buspirone": "Anxiolytic",
    "Clonazepam": "Benzodiazepine (Anticonvulsant)",
    "Diazepam": "Benzodiazepine",
    "Lorazepam": "Benzodiazepine",
    "Midazolam": "Benzodiazepine (Sedative)",
    "Zolpidem": "Sedative-Hypnotic",
    # CNS - Anticonvulsants
    "Carbamazepine": "Anticonvulsant",
    "Divalproex": "Anticonvulsant",
    "Gabapentin": "Anticonvulsant / Neuropathic Pain",
    "Lamotrigine": "Anticonvulsant",
    "Levetiracetam": "Anticonvulsant",
    "Oxcarbazepine": "Anticonvulsant",
    "Phenobarbital": "Anticonvulsant (Barbiturate)",
    "Phenytoin": "Anticonvulsant",
    "Valproic Acid": "Anticonvulsant",
    # CNS - Dementia
    "Donepezil": "Cholinesterase Inhibitor",
    "Memantine": "NMDA Receptor Antagonist",
    # Musculoskeletal
    "Allopurinol": "Antigout (Xanthine Oxidase Inhibitor)",
    "Baclofen": "Muscle Relaxant",
    "Colchicine": "Antigout",
    "Probenecid": "Uricosuric",
    # Thyroid
    "Levothyroxine": "Thyroid Hormone",
    # Oncology
    "Cisplatin": "Antineoplastic",
    "Cyclophosphamide": "Antineoplastic",
    "Doxorubicin": "Antineoplastic",
    "Methotrexate": "Antineoplastic / DMARD",
    "Tamoxifen": "Antineoplastic (SERM)",
    # Other
    "Acetazolamide": "Carbonic Anhydrase Inhibitor",
    "Atropine": "Anticholinergic",
    "Bupivacaine": "Local Anesthetic",
    "Dapsone": "Anti-Leprosy",
    "Dimenhydrinate": "Antiemetic",
    "Dorzolamide": "Carbonic Anhydrase Inhibitor (Ophthalmic)",
    "Epinephrine": "Sympathomimetic",
    "Hyoscine": "Antispasmodic",
    "Lidocaine": "Local Anesthetic",
    "Meclizine": "Antiemetic / Antivertigo",
    "Oxymetazoline": "Nasal Decongestant",
    "Phenylephrine": "Decongestant",
    "Prochlorperazine": "Antiemetic / Antipsychotic",
    "Sildenafil": "PDE-5 Inhibitor",
    "Tamsulosin": "Alpha Blocker (Urological)",
    "Timolol": "Beta Blocker (Ophthalmic)",
    "Tranexamic Acid": "Antifibrinolytic",
    # Supplements / Vitamins
    "Calcium Carbonate": "Calcium Supplement",
    "Calcium Gluconate": "Calcium Supplement",
    "Cholecalciferol": "Vitamin D3",
    "Ferrous Sulfate": "Iron Supplement",
    "Folic Acid": "Vitamin B9",
    "Iron Dextran": "Iron Supplement (Injectable)",
    "Multivitamin": "Vitamin / Mineral Supplement",
    "Multivitamine": "Vitamin / Mineral Supplement",
    "Potassium Chloride": "Potassium Supplement",
    "Pyridoxine": "Vitamin B6",
    "Sodium Bicarbonate": "Alkalinizing Agent",
    "Thiamine": "Vitamin B1",
    "Ursodeoxycholic Acid": "Bile Acid",
    "Vitamin A": "Vitamin Supplement",
    "Vitamin B Complex": "Vitamin Supplement",
    "Vitamin B12": "Vitamin Supplement",
    "Vitamin C": "Vitamin Supplement",
    "Vitamin D": "Vitamin Supplement",
    "Vitamin E": "Vitamin Supplement",
    "Vitamin K": "Vitamin Supplement",
    "Zinc Sulfate": "Mineral Supplement",
    # Dermatological
    "Benzoyl Peroxide": "Acne Treatment",
    "Calamine": "Skin Protectant",
    "Mupirocin": "Topical Antibiotic",
    "Permethrin": "Scabicide / Pediculicide",
    "Silver Sulfadiazine": "Topical Anti-Infective (Burns)",
    # ORS
    "Oral Rehydration Salts": "Oral Rehydration Therapy",
    # Anti-leprosy
    "Sulfasalazine": "DMARD / Anti-Inflammatory",
    "Alendronate": "Bisphosphonate",
}


class MedicationLexicon:
    """Loads medication lexicons and provides fuzzy matching capabilities."""

    def __init__(self, lexicon_dir: str) -> None:
        """
        Initialize the lexicon by loading medication names from text files.

        Args:
            lexicon_dir: Path to the directory containing lexicon files
                         (medications_en.txt, medications_km.txt, etc.)
        """
        self.lexicon_dir = lexicon_dir
        self.medications_en: list[str] = []
        self.medications_km: list[str] = []
        self.all_names: list[str] = []

        self._load_lexicons()

    def _load_lexicons(self) -> None:
        """Load all lexicon files from the lexicon directory."""
        en_path = os.path.join(self.lexicon_dir, "medications_en.txt")
        km_path = os.path.join(self.lexicon_dir, "medications_km.txt")

        if os.path.exists(en_path):
            with open(en_path, "r", encoding="utf-8") as f:
                self.medications_en = [
                    line.strip() for line in f if line.strip()
                ]

        if os.path.exists(km_path):
            with open(km_path, "r", encoding="utf-8") as f:
                self.medications_km = [
                    line.strip() for line in f if line.strip()
                ]

        # Also include brand names from the mapping as valid lookup entries
        brand_names = list(BRAND_TO_GENERIC.keys())

        self.all_names = list(
            dict.fromkeys(
                self.medications_en + brand_names + self.medications_km
            )
        )

    def match(
        self, text: str, threshold: int = 85
    ) -> Optional[dict]:
        """
        Fuzzy-match the given text against all known medication names.

        Args:
            text: The OCR-extracted text to match.
            threshold: Minimum similarity score (0-100) to accept a match.

        Returns:
            A dict with keys ``matched_name``, ``score``, and
            ``generic_name`` (which may be ``None``), or ``None`` if no
            match meets the threshold.
        """
        if not text or not text.strip():
            return None

        text = text.strip()

        # Try exact match first (case-insensitive)
        for name in self.all_names:
            if name.lower() == text.lower():
                return {
                    "matched_name": name,
                    "score": 100.0,
                    "generic_name": self.get_generic_name(name),
                }

        # Fuzzy match using rapidfuzz
        result = process.extractOne(
            text,
            self.all_names,
            scorer=fuzz.WRatio,
            score_cutoff=threshold,
        )

        if result is None:
            return None

        matched_name, score, _ = result
        return {
            "matched_name": matched_name,
            "score": round(score, 2),
            "generic_name": self.get_generic_name(matched_name),
        }

    def get_generic_name(self, brand_name: str) -> Optional[str]:
        """
        Return the generic / INN name for a given brand name.

        Performs a case-insensitive lookup in ``BRAND_TO_GENERIC``.

        Args:
            brand_name: A brand or trade name (e.g. ``"Celcoxx"``).

        Returns:
            The corresponding generic name (e.g. ``"Celecoxib"``), or
            ``None`` if the name is not a known brand.
        """
        if not brand_name:
            return None

        # Direct lookup
        generic = BRAND_TO_GENERIC.get(brand_name)
        if generic:
            return generic

        # Case-insensitive lookup
        lower = brand_name.lower()
        for brand, generic in BRAND_TO_GENERIC.items():
            if brand.lower() == lower:
                return generic

        return None

    def get_therapeutic_class(self, name: str) -> Optional[str]:
        """
        Return the therapeutic class for a given drug name.

        Checks both the supplied name and its generic equivalent (if the
        name is a known brand).

        Args:
            name: A drug name (brand or generic).

        Returns:
            The therapeutic class string, or ``None`` if not found.
        """
        if not name:
            return None

        # Direct lookup
        tc = THERAPEUTIC_CLASSES.get(name)
        if tc:
            return tc

        # Case-insensitive lookup
        lower = name.lower()
        for drug, cls in THERAPEUTIC_CLASSES.items():
            if drug.lower() == lower:
                return cls

        # Try via generic name
        generic = self.get_generic_name(name)
        if generic:
            tc = THERAPEUTIC_CLASSES.get(generic)
            if tc:
                return tc
            lower_generic = generic.lower()
            for drug, cls in THERAPEUTIC_CLASSES.items():
                if drug.lower() == lower_generic:
                    return cls

        return None
