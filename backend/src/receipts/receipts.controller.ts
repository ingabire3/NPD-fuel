import {
  Controller,
  Post,
  Get,
  Param,
  UploadedFile,
  UseInterceptors,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ReceiptsService } from './receipts.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('receipts')
export class ReceiptsController {
  constructor(private receiptsService: ReceiptsService) {}

  @Get()
  findAll(@CurrentUser() user: any) {
    return this.receiptsService.findAll(user.id, user.role);
  }

  @Roles(Role.DRIVER, Role.SUPER_ADMIN)
  @Post(':requestId/upload')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
      fileFilter: (_, file, cb) => {
        if (!file.mimetype.match(/image\/(jpeg|png|jpg)/)) {
          return cb(new Error('Only JPG/PNG images allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  upload(
    @CurrentUser() user: any,
    @Param('requestId') requestId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.receiptsService.uploadReceipt(requestId, file, user.id, user.role);
  }

  @Get(':requestId')
  findOne(@Param('requestId') requestId: string) {
    return this.receiptsService.findByRequest(requestId);
  }
}
