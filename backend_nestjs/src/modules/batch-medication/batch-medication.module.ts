import { Module } from '@nestjs/common';
import { BatchMedicationController } from './batch-medication.controller';
import { BatchMedicationService } from './batch-medication.service';

@Module({
  controllers: [BatchMedicationController],
  providers: [BatchMedicationService],
  exports: [BatchMedicationService],
})
export class BatchMedicationModule {}
