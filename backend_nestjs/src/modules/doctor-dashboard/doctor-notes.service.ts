import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { AuditService } from '../audit/audit.service';
import { CreateDoctorNoteDto, UpdateDoctorNoteDto } from './dto';

@Injectable()
export class DoctorNotesService {
  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
  ) {}

  /**
   * Create a doctor note for a patient.
   * Requires active connection between doctor and patient.
   */
  async create(doctorId: string, dto: CreateDoctorNoteDto) {
    // Verify active connection exists
    const connection = await this.prisma.connection.findFirst({
      where: {
        OR: [
          { initiatorId: doctorId, recipientId: dto.patientId },
          { initiatorId: dto.patientId, recipientId: doctorId },
        ],
        status: 'ACCEPTED',
      },
    });

    if (!connection) {
      throw new ForbiddenException('No active connection with patient');
    }

    const note = await this.prisma.doctorNote.create({
      data: {
        doctorId,
        patientId: dto.patientId,
        content: dto.content,
      },
      include: {
        doctor: { select: { id: true, fullName: true } },
      },
    });

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DOCTOR_NOTE_CREATE',
      resourceType: 'DoctorNote',
      resourceId: note.id,
      details: { patientId: dto.patientId },
    });

    return note;
  }

  /**
   * Get all notes for a patient by a specific doctor.
   */
  async findAll(doctorId: string, patientId: string) {
    return this.prisma.doctorNote.findMany({
      where: { doctorId, patientId },
      orderBy: { createdAt: 'desc' },
      include: {
        doctor: { select: { id: true, fullName: true } },
      },
    });
  }

  /**
   * Update a note. Only the doctor who created it can edit.
   */
  async update(noteId: string, doctorId: string, dto: UpdateDoctorNoteDto) {
    const note = await this.prisma.doctorNote.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw new NotFoundException('Note not found');
    }

    if (note.doctorId !== doctorId) {
      throw new ForbiddenException('Only the author can edit this note');
    }

    const updated = await this.prisma.doctorNote.update({
      where: { id: noteId },
      data: { content: dto.content },
      include: {
        doctor: { select: { id: true, fullName: true } },
      },
    });

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DOCTOR_NOTE_UPDATE',
      resourceType: 'DoctorNote',
      resourceId: noteId,
      details: { patientId: note.patientId },
    });

    return updated;
  }

  /**
   * Delete a note. Only the doctor who created it can delete.
   */
  async delete(noteId: string, doctorId: string) {
    const note = await this.prisma.doctorNote.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw new NotFoundException('Note not found');
    }

    if (note.doctorId !== doctorId) {
      throw new ForbiddenException('Only the author can delete this note');
    }

    await this.prisma.doctorNote.delete({
      where: { id: noteId },
    });

    // Audit log
    await this.auditService.log({
      actorId: doctorId,
      actorRole: 'DOCTOR',
      actionType: 'DOCTOR_NOTE_UPDATE',
      resourceType: 'DoctorNote',
      resourceId: noteId,
      details: { patientId: note.patientId, action: 'DELETE' },
    });

    return { success: true, id: noteId };
  }
}
