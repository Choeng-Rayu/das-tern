export const DEFAULT_THRESHOLDS: Record<string, { min: number | null; max: number | null; minSecondary?: number | null; maxSecondary?: number | null }> = {
  BLOOD_PRESSURE: { min: 90, max: 140, minSecondary: 60, maxSecondary: 90 },
  GLUCOSE: { min: 70, max: 180 },
  HEART_RATE: { min: 50, max: 120 },
  WEIGHT: { min: null, max: null },
  TEMPERATURE: { min: 35.5, max: 38.0 },
  SPO2: { min: 92, max: 100 },
};

export const VITAL_UNITS: Record<string, string> = {
  BLOOD_PRESSURE: 'mmHg',
  GLUCOSE: 'mg/dL',
  HEART_RATE: 'bpm',
  WEIGHT: 'kg',
  TEMPERATURE: '°C',
  SPO2: '%',
};
