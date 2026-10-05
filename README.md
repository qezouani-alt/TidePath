# TidePath Fishing - Spot Finder

A premium Flutter fishing companion UI with a worldwide location picker and a fish guide. Home, Fishing Forecast, and Sea Conditions use location-based weather and marine forecasts when available, with sample data as a fallback.

## Run

```sh
flutter pub get
flutter run
```

For dependable nearby beach, marina, pier, and fishing-place search, create a
[Geoapify Places API key](https://apidocs.geoapify.com/docs/places/) and run:

```sh
flutter run --dart-define=GEOAPIFY_PLACES_API_KEY=YOUR_KEY
```

In VS Code, select **TidePath (Geoapify)** in Run and Debug. It reads the
ignored local `.secrets/geoapify.json` file through Flutter's
`--dart-define-from-file` option. Restart the app after changing that file;
hot reload does not update compile-time defines.

The key is compiled into a client app; for a production app, a small server
proxy can keep the key private. The
selected coordinates are sent to Geoapify only when the key is configured.
Without it, nearby search uses two public OpenStreetMap Overpass servers,
which can be unavailable or overloaded. Searches use a 20 km radius, cache
successful results for 12 hours, and show a retry control if providers fail.
Geoapify's free plan requires both Geoapify and OpenStreetMap attribution,
which appear with nearby results.

## Explore the demo

The five-tab navigation opens Home, Explore, Fish Guide, Learn Fishing, and Profile. On Home, tap **Use my location** to detect your position, or **Pick on map** to search for a place or select any point worldwide. The selected place appears on Home, Explore, Forecast, and Sea Conditions for the current app session. Maps and place search need an internet connection; GPS requires device location permission.

Fish Guide includes photographs of ten curated species. Open **Fish photo credits** in Profile for creator, license, and source details. Those photos are bundled, so the curated guide works offline. Its **Nearby** tab loads research-grade ray-finned fish observations within 30 km of the selected location from the public [iNaturalist API](https://www.inaturalist.org/pages/api+recommended+practices). Home shows the leading nearby species, and mapped spot details use the spot's own coordinates. The guide loads additional pages on demand. Nearby observation counts are historical records, not fishing probabilities, catch reports, or proof that fish can be caught at an exact spot. iNaturalist requires no key for these public read-only requests. When default photos for the first 12 nearby species cannot be reused, the app tries one batched taxon photo lookup and, if needed, one batched observation photo lookup. It displays only CC0, CC BY, or CC BY-SA photos with credit and source details; species without a suitable photo use the existing fish icon. Nearby results are cached for 12 hours, and the existing curated species remain available if a request fails.

In Fish Guide, **All** searches the worldwide iNaturalist fish catalog across ray-finned, cartilaginous, jawless, and lobe-finned fishes. It loads 20 species at a time; entering a common or scientific name searches the full catalog on the server. iNaturalist limits deep paging, so search is the way to reach species beyond the first 10,000 displayed entries. The Saltwater, Freshwater, Predator, Bottom Fish, and Popular chips continue to use the ten curated profiles and are labeled accordingly because those categories need verified habitat data before they can filter the worldwide catalog. Catalog pages are cached for 12 hours, and saved profiles appear if the catalog request fails. Global observation counts are historical records, not catch probabilities. The catalog shares the same licensed-photo lookup as Nearby.

The Home Fishing Conditions Today card contains a selectable 24-hour marine instrument, seven-day forecast, and sample best-time windows. Tap its title or **Details** to open **Fishing Conditions Details**, with Summary, Tides, and Sun tabs. The tabs share the selected day and hour and read the same cached conditions as Home. Pull down on Home, Details, or Fishing Forecast to refresh.

From Home you can also open the fishing forecast, sea conditions, fishing spots, and fish details. Profile opens My Catches, learning progress, settings, and the four-page introduction. The catch form saves entries for the current app session. Fish identification presents a labeled sample result until a camera and identification service are connected.

## Structure

- `lib/core/theme/`: colors and light/dark themes
- `lib/models/`: demo fishing data
- `lib/widgets/`: reusable cards, search, score, navigation, and buttons
- `lib/features/`: screen flows grouped by feature
- `assets/images/fish/`: bundled species photos and [attribution](assets/images/fish/ATTRIBUTION.md)
- `lib/features/location/`: map and device location picker
- `lib/services/location_service.dart`: GPS and place search
- `lib/services/nearby_spots_service.dart`: nearby place lookup, caching, and public Overpass fallback
- `lib/services/geoapify_nearby_spots_source.dart`: optional keyed places source
- `lib/services/nearby_fish_service.dart`: paged local fish observations and caching
- `lib/models/nearby_fish.dart`: local fish observation records
- `lib/models/fishing_conditions.dart`: typed weather, marine, tide, and outlook data
- `lib/services/weather_service.dart`, `marine_service.dart`: Open-Meteo weather and marine parsing
- `lib/services/condition_sources.dart`: shared client, source interfaces, and tide estimate
- `lib/services/fishing_conditions_repository.dart`: independent fallback for each source
- `lib/features/conditions/conditions_scope.dart`: refreshes conditions when the selected location changes
- `lib/features/home/widgets/`: interactive Home marine instrument and forecast selectors
- `lib/features/conditions/screens/fishing_conditions_details_screen.dart`: three-tab details screen
- `lib/features/conditions/widgets/`: summary, tide, and sun panels
- `lib/services/fishing_forecast_builder.dart`: combines cached weather and marine hours into seven selectable days
- `lib/services/fishing_score_service.dart`: isolated, explicitly demo fishing scores
- `lib/utils/wind_direction.dart`: sixteen-point wind direction labels
- `tool/generate_app_icons.py`: source for TidePath launcher icons (requires Pillow)
- `tool/fetch_fish_photos.py`: curated Wikimedia Commons photo downloader

The app requests device location only when **Use my location** or **Use my current location** is selected. Permission denial leaves the map picker usable. If reverse geocoding fails, the map keeps the exact coordinates and shows a neutral place label. Weather and marine requests run independently, so one can stay live while another uses sample values. Successful responses are cached for 15 minutes; pull-to-refresh bypasses the cache. A failed refresh retains the previous snapshot when available and shows a non-blocking message. The current 86/100 fishing score, future hourly and daily scores, best-time windows, and moon facts remain clearly labeled demo values. Tide state and height come from modeled sea level where available; otherwise they use labeled samples. Tide estimates are not navigation-grade tide tables.

The app uses [Open-Meteo weather](https://open-meteo.com/en/docs) and [marine](https://open-meteo.com/en/docs/marine-weather-api) without an API key. Its [free API terms](https://open-meteo.com/en/terms) allow non-commercial use. Review provider licensing before commercial release.

No new packages were added for the dashboard. Existing packages used by this feature: `http` sends the weather and marine requests; `geolocator` handles device location permission and coordinates; `geocoding` supplies readable place names; `latlong2` stores coordinates and checks proximity to marine model cells. `flutter_map` powers the existing map picker.

Fish probabilities, Moroccan spot distances, and moon metrics remain labeled sample values. Maps use OpenStreetMap's public tile server for this demo; configure a production tile provider before releasing an app with significant traffic. Account storage and live fish identification are future work.

## Check

```sh
flutter analyze
flutter test
```

## iOS AdMob ads

The real iOS AdMob app ID is configured in `ios/Runner/Info.plist`.
Configure the real app-open and interstitial ad unit IDs in
`lib/services/admob_config.dart`, or supply
`--dart-define=ADMOB_IOS_APP_OPEN_ID=...` and
`--dart-define=ADMOB_IOS_INTERSTITIAL_ID=...`.
Empty or invalid ad unit IDs disable the corresponding format. No test IDs are
included. Android, web, and desktop do not initialize the ads SDK.

App-open ads are attempted on returning launches before Home. First-launch
onboarding remains ad-free. Interstitials are attempted before tab changes and
opening detail pages. If no ad is ready, navigation proceeds immediately.
App-open ads expire after four hours; interstitials expire after one hour.

Real ad requests use the UMP consent flow and non-personalized requests.
Configure your privacy message in AdMob. ATT is requested on iOS before SDK
initialization. A full rebuild is required after native configuration changes.
