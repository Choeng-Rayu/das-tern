src/modules/batch-medication/batch-medication.service.ts:99:13 - error TS2353: Object literal may only specify known properties, and 'afternoonDosage' does not exist in type 'Without<MedicationCreateInput, MedicationUncheckedCreateInput> & MedicationUncheckedCreateInput'.

99             afternoonDosage: hours >= 12 && hours < 17 ? dosage : Prisma.DbNull,
               ~~~~~~~~~~~~~~~

  node_modules/.prisma/client/index.d.ts:9207:5
    9207     data: XOR<MedicationCreateInput, MedicationUncheckedCreateInput>
             ~~~~
    The expected type comes from property 'data' which is declared here on type '{ select?: MedicationSelect<DefaultArgs> | null | undefined; include?: MedicationInclude<DefaultArgs> | null | undefined; data: (Without<...> & MedicationUncheckedCreateInput) | (Without<...> & MedicationCreateInput); }'

src/modules/batch-medication/batch-medication.service.ts:325:9 - error TS2353: Object literal may only specify known properties, and 'afternoonDosage' does not exist in type 'Without<MedicationCreateInput, MedicationUncheckedCreateInput> & MedicationUncheckedCreateInput'.

325         afternoonDosage: hours >= 12 && hours < 17 ? dosage : Prisma.DbNull,
            ~~~~~~~~~~~~~~~

  node_modules/.prisma/client/index.d.ts:9207:5
    9207     data: XOR<MedicationCreateInput, MedicationUncheckedCreateInput>
             ~~~~
    The expected type comes from property 'data' which is declared here on type '{ select?: MedicationSelect<DefaultArgs> | null | undefined; include?: MedicationInclude<DefaultArgs> | null | undefined; data: (Without<...> & MedicationUncheckedCreateInput) | (Without<...> & MedicationCreateInput); }'

src/modules/doses/doses.service.ts:42:38 - error TS2367: This comparison appears to be unintentional because the types 'TimePeriod' and '"AFTERNOON"' have no overlap.

42             doses: doses.filter(d => d.timePeriod === 'AFTERNOON').map(d => this.formatDose(d)),
                                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

src/modules/doses/doses.service.ts:47:38 - error TS2367: This comparison appears to be unintentional because the types 'TimePeriod' and '"EVENING"' have no overlap.

47             doses: doses.filter(d => d.timePeriod === 'EVENING').map(d => this.formatDose(d)),
                                        ~~~~~~~~~~~~~~~~~~~~~~~~~~

src/modules/doses/doses.service.ts:151:64 - error TS2339: Property 'afternoonDosage' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; prescriptionId: string; rowNumber: number; batchId: string | null; medicineName: string; medicineNameKhmer: string | null; imageUrl: string | null; ... 13 more ...; beforeMeal: boolean; }'.

151       dosage: dose.medication.morningDosage || dose.medication.afternoonDosage || dose.medication.eveningDosage || dose.medication.nightDosage,
                                                                   ~~~~~~~~~~~~~~~

src/modules/doses/doses.service.ts:151:99 - error TS2339: Property 'eveningDosage' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; prescriptionId: string; rowNumber: number; batchId: string | null; medicineName: string; medicineNameKhmer: string | null; imageUrl: string | null; ... 13 more ...; beforeMeal: boolean; }'.

151       dosage: dose.medication.morningDosage || dose.medication.afternoonDosage || dose.medication.eveningDosage || dose.medication.nightDosage,
                                                                                                      ~~~~~~~~~~~~~

src/modules/medicines/medicines.service.ts:66:9 - error TS2353: Object literal may only specify known properties, and 'afternoonDosage' does not exist in type 'Without<MedicationCreateInput, MedicationUncheckedCreateInput> & MedicationUncheckedCreateInput'.

66         afternoonDosage: hasTimes ? (afternoonDosage || Prisma.DbNull) : Prisma.DbNull,
           ~~~~~~~~~~~~~~~

  node_modules/.prisma/client/index.d.ts:9207:5
    9207     data: XOR<MedicationCreateInput, MedicationUncheckedCreateInput>
             ~~~~
    The expected type comes from property 'data' which is declared here on type '{ select?: MedicationSelect<DefaultArgs> | null | undefined; include?: MedicationInclude<DefaultArgs> | null | undefined; data: (Without<...> & MedicationUncheckedCreateInput) | (Without<...> & MedicationCreateInput); }'

src/modules/medicines/medicines.service.ts:376:35 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

376     const eveningHour = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[0]) : 17;
                                      ~~~~~~~~~~~

src/modules/medicines/medicines.service.ts:376:67 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

376     const eveningHour = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[0]) : 17;
                                                                      ~~~~~~~~~~~

src/modules/medicines/medicines.service.ts:377:34 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

377     const eveningMin = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[1]) : 0;
                                     ~~~~~~~~~~~

src/modules/medicines/medicines.service.ts:377:66 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

377     const eveningMin = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[1]) : 0;
                                                                     ~~~~~~~~~~~

src/modules/prescriptions/prescriptions.service.ts:611:35 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

611     const eveningHour = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[0]) : 17;
                                      ~~~~~~~~~~~

src/modules/prescriptions/prescriptions.service.ts:611:67 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

611     const eveningHour = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[0]) : 17;
                                                                      ~~~~~~~~~~~

src/modules/prescriptions/prescriptions.service.ts:612:34 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

612     const eveningMin = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[1]) : 0;
                                     ~~~~~~~~~~~

src/modules/prescriptions/prescriptions.service.ts:612:66 - error TS2339: Property 'eveningMeal' does not exist on type '{ id: string; createdAt: Date; updatedAt: Date; userId: string; morningMeal: string | null; afternoonMeal: string | null; nightMeal: string | null; }'.

612     const eveningMin = mealPref?.eveningMeal ? parseInt(mealPref.eveningMeal.split(':')[1]) : 0;
                                                      