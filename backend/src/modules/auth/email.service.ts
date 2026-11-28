import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as https from 'https';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(private readonly config: ConfigService) {}

  async sendVerificationEmail(toEmail: string, token: string): Promise<void> {
    const appUrl = this.config.get<string>('APP_URL', 'http://localhost:3000');
    const verificationUrl = `${appUrl}/auth/verify-email?token=${token}`;

    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet" />
  <title>Verify your CampusCore email</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Nunito',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background-color:#1A2332;padding:36px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:800;letter-spacing:-0.5px;">CampusCore</h1>
              <p style="margin:6px 0 0;color:#94a3b8;font-size:14px;font-weight:600;">Learn. Connect. Achieve.</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="background-color:#ffffff;padding:40px;">
              <h2 style="margin:0 0 16px;color:#1A2332;font-size:22px;font-weight:800;">Verify your email address</h2>
              <p style="margin:0 0 24px;color:#475569;font-size:15px;line-height:1.6;">
                Welcome to CampusCore! Please verify your email address to activate your account and start learning.
                This link expires in <strong>24 hours</strong>.
              </p>
              <!-- CTA Button -->
              <table cellpadding="0" cellspacing="0" style="margin:0 auto 32px;">
                <tr>
                  <td align="center" style="border-radius:8px;background-color:#1A2332;">
                    <a href="${verificationUrl}"
                       style="display:inline-block;padding:14px 36px;color:#ffffff;font-family:'Nunito',Arial,sans-serif;font-size:15px;font-weight:700;text-decoration:none;border-radius:8px;">
                      Verify My Email
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 8px;color:#94a3b8;font-size:13px;">
                If the button doesn't work, copy and paste this link into your browser:
              </p>
              <p style="margin:0;word-break:break-all;">
                <a href="${verificationUrl}" style="color:#1A2332;font-size:13px;font-weight:600;">${verificationUrl}</a>
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color:#f8fafc;padding:24px 40px;text-align:center;border-top:1px solid #e2e8f0;">
              <p style="margin:0;color:#94a3b8;font-size:12px;line-height:1.6;">
                If you did not create a CampusCore account, you can safely ignore this email.<br/>
                &copy; ${new Date().getFullYear()} CampusCore. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const apiKey = this.config.get<string>('BREVO_API_KEY');

    const body = JSON.stringify({
      sender: { name: 'CampusCore', email: 'campuscore8@gmail.com' },
      to: [{ email: toEmail }],
      subject: 'Verify your CampusCore email address',
      htmlContent: html,
    });

    try {
      await new Promise<void>((resolve, reject) => {
        const req = https.request(
          {
            hostname: 'api.brevo.com',
            path: '/v3/smtp/email',
            method: 'POST',
            headers: {
              'api-key': apiKey,
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(body),
            },
          },
          (res) => {
            let data = '';
            res.on('data', (chunk) => (data += chunk));
            res.on('end', () => {
              if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                resolve();
              } else {
                reject(new Error(`Brevo API responded with ${res.statusCode}: ${data}`));
              }
            });
          },
        );
        req.on('error', reject);
        req.write(body);
        req.end();
      });
      this.logger.log(`Verification email sent to ${toEmail}`);
    } catch (err) {
      this.logger.error(`Failed to send verification email to ${toEmail}`, (err as Error).message);
      // Rethrow so the caller can roll back registration
      throw err;
    }
  }
}
