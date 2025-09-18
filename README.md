# Credit Phone Qatar mobile app

This Flutter application consumes the WooCommerce API hosted at
`https://creditphoneqatar.com`. The store requires authenticated requests, so
each build must provide a WooCommerce consumer key and secret.

## Environment configuration

The application reads credentials from a `.env` file via
[`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv). Copy the example
file and fill in the values provided by the WooCommerce backend team:

```bash
cp .env.example .env
```

Update the generated `.env` file so it contains the correct keys:

```text
WOO_CONSUMER_KEY=ck_live_value
WOO_CONSUMER_SECRET=cs_live_value
```

The file is ignored by Git, ensuring secrets remain local to your machine.

### Alternative: CI/CD environments

CI pipelines that should not manage files can pass the credentials with
`--dart-define` flags. The application falls back to these at runtime when the
`.env` file is unavailable:

```bash
flutter run \
  --dart-define=WOO_CONSUMER_KEY=ck_live_value \
  --dart-define=WOO_CONSUMER_SECRET=cs_live_value
```

When using CI, ensure the job exports these flags for any `flutter run`,
`flutter test`, or `flutter build` invocation so HTTP requests are authorized.

## Running the app locally

1. Install Flutter (version 3.6.0 or newer) and the platform SDKs required for
   your target (Android/iOS/etc.).
2. Create the `.env` file or set `--dart-define` flags as described above.
3. Fetch dependencies and launch the app:

   ```bash
   flutter pub get
   flutter run
   ```

On first launch the catalog should populate again—check the debug console for
HTTP 200 responses from the WooCommerce `/products` and `/categories` routes.

## Troubleshooting

- `dotenv: Unable to load asset: .env`: ensure the `.env` file exists at the
  project root or provide credentials via `--dart-define`.
- Empty catalog: verify both `WOO_CONSUMER_KEY` and `WOO_CONSUMER_SECRET` are
  provided. The app only attempts authenticated requests when both values are
  non-empty.
