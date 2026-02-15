import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    UseGuards,
    UsePipes,
    ValidationPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { BakongPaymentService } from './bakong-payment.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateBakongPaymentDto } from './bakong-payment.dto';

/**
 * Bakong Payment Controller
 *
 * All endpoints are JWT-protected. The user's ID is extracted from the JWT token,
 * preventing any user from creating payments for or checking status of other users.
 *
 * Endpoints:
 * - POST /bakong-payment/create   → Create payment + get QR code
 * - GET  /bakong-payment/status/:md5Hash → Check payment status
 * - GET  /bakong-payment/plans    → Get available plans + pricing
 * - GET  /bakong-payment/subscription → Get user's current subscription
 */
@Controller('bakong-payment')
@UseGuards(AuthGuard('jwt'))
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
export class BakongPaymentController {
    constructor(private readonly bakongPaymentService: BakongPaymentService) { }

    /**
     * Create a new Bakong payment and receive QR code.
     * User ID is extracted from JWT — no user ID in request body.
     */
    @Post('create')
    async createPayment(
        @CurrentUser() user: any,
        @Body() dto: CreateBakongPaymentDto,
    ) {
        return this.bakongPaymentService.createPayment(
            user.id,
            dto.planType,
            dto.appName,
        );
    }

    /**
     * Check payment status by MD5 hash.
     * If payment is PAID, auto-upgrades subscription.
     */
    @Get('status/:md5Hash')
    async checkPaymentStatus(
        @CurrentUser() user: any,
        @Param('md5Hash') md5Hash: string,
    ) {
        return this.bakongPaymentService.checkPaymentStatus(user.id, md5Hash);
    }

    /**
     * Get available subscription plans and payment methods.
     * Public info but still requires auth to prevent scraping.
     */
    @Get('plans')
    async getPlans() {
        return this.bakongPaymentService.getPlans();
    }

    /**
     * Get current user's subscription status (from main DB).
     */
    @Get('subscription')
    async getSubscription(@CurrentUser() user: any) {
        return this.bakongPaymentService.getSubscription(user.id);
    }
}
