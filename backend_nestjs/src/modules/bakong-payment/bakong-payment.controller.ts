import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    UseGuards,
    UsePipes,
    ValidationPipe,
    Headers,
    HttpCode,
    HttpStatus,
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
 * - POST /bakong-payment/create          → Create payment + get QR code
 * - GET  /bakong-payment/status/:md5Hash → Check payment status
 * - GET  /bakong-payment/plans           → Get available plans + pricing
 * - GET  /bakong-payment/subscription    → Get user's current subscription
 * - POST /bakong-payment/webhook         → Internal callback from bakong_payment service (HMAC-secured, no JWT)
 */
@Controller('bakong-payment')
export class BakongPaymentController {
    constructor(private readonly bakongPaymentService: BakongPaymentService) { }

    /**
     * Internal webhook — called by the bakong_payment microservice when a payment is confirmed PAID.
     * NOT JWT-protected; secured by HMAC-SHA256 signature verification instead.
     * Idempotent: safe to call multiple times for the same transaction.
     */
    @Post('webhook')
    @HttpCode(HttpStatus.OK)
    async handlePaymentWebhook(
        @Body() body: any,
        @Headers('authorization') auth: string,
        @Headers('x-timestamp') timestamp: string,
        @Headers('x-signature') signature: string,
    ) {
        return this.bakongPaymentService.handlePaymentWebhook(body, auth, timestamp, signature);
    }

    /**
     * Create a new Bakong payment and receive QR code.
     * User ID is extracted from JWT — no user ID in request body.
     */
    @Post('create')
    @UseGuards(AuthGuard('jwt'))
    @UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
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
    @UseGuards(AuthGuard('jwt'))
    async checkPaymentStatus(
        @CurrentUser() user: any,
        @Param('md5Hash') md5Hash: string,
    ) {
        return this.bakongPaymentService.checkPaymentStatus(user.id, md5Hash);
    }

    /**
     * Get available subscription plans and payment methods.
     */
    @Get('plans')
    @UseGuards(AuthGuard('jwt'))
    async getPlans() {
        return this.bakongPaymentService.getPlans();
    }

    /**
     * Get current user's subscription status (from main DB).
     */
    @Get('subscription')
    @UseGuards(AuthGuard('jwt'))
    async getSubscription(@CurrentUser() user: any) {
        return this.bakongPaymentService.getSubscription(user.id);
    }
}
