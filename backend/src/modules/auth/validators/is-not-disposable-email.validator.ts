import { registerDecorator, ValidationOptions } from 'class-validator';

/**
 * List of known disposable / temporary email domains.
 * Add more entries as needed; keep it sorted for readability.
 */
const DISPOSABLE_DOMAINS = new Set([
  'discard.email',
  'dispostable.com',
  'fakeinbox.com',
  'getairmail.com',
  'grr.la',
  'guerrillamail.biz',
  'guerrillamail.com',
  'guerrillamail.de',
  'guerrillamail.info',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamailblock.com',
  'mailinator.com',
  'maildrop.cc',
  'mailnesia.com',
  'mailnull.com',
  'sharklasers.com',
  'spam4.me',
  'spambog.com',
  'spamgourmet.com',
  'temp-mail.org',
  'tempmail.com',
  'throwam.com',
  'trashmail.com',
  'trashmail.me',
  'trashmail.net',
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
