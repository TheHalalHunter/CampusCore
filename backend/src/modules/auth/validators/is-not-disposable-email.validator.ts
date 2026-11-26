import { registerDecorator, ValidationOptions } from 'class-validator';

/**
 * List of known disposable / temporary email domains.
 * Keep in sync with DISPOSABLE_DOMAINS in auth.service.ts.
 */
const DISPOSABLE_DOMAINS = new Set([
  'deadaddress.com',
  'discard.email',
  'discardmail.com',
  'discardmail.de',
  'dispostable.com',
  'fakeinbox.com',
  'filzmail.com',
  'filzmail.de',
  'getairmail.com',
  'grr.la',
  'guerrillamail.biz',
  'guerrillamail.com',
  'guerrillamail.de',
  'guerrillamail.info',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamailblock.com',
  'haltospam.com',
  'inoutmail.de',
  'inoutmail.eu',
  'inoutmail.info',
  'inoutmail.net',
  'mailinator.com',
  'maildrop.cc',
  'mailnesia.com',
  'mailnull.com',
  'mailscrap.com',
  'sharklasers.com',
  'spam4.me',
  'spambog.com',
  'spamex.com',
  'spamgob.com',
  'spamgourmet.com',
  'spamgourmet.net',
  'spamgourmet.org',
  'spamhole.com',
  'spamoff.de',
  'spamthisplease.com',
  'spamfree24.org',
  'temp-mail.org',
  'tempinbox.com',
  'tempmail.com',
  '10minutemail.com',
  '10minutemail.net',
  '10minutemail.org',
  'throwam.com',
  'trashdevil.com',
  'trashdevil.de',
  'trashmail.com',
  'trashmail.me',
  'trashmail.net',
  'uggsrock.com',
  'yopmail.com',
]);

/**
 * Rejects well-known disposable/temporary email domains.
 * Apply on any email field where you want to enforce real addresses.
 */
export function IsNotDisposableEmail(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isNotDisposableEmail',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown): boolean {
          if (typeof value !== 'string') return false;
          const atIndex = value.lastIndexOf('@');
          if (atIndex === -1) return false;
          const domain = value.slice(atIndex + 1).toLowerCase();
          return !DISPOSABLE_DOMAINS.has(domain);
        },
        defaultMessage(): string {
          return 'Disposable email addresses are not allowed. Please use a real email address.';
        },
      },
    });
  };
}
