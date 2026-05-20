# Conversation History

A log of Claude Code sessions for this project, intended as a quick way to recover context when resuming closed sessions.

## How to use

- Append a new entry at the top of the **Sessions** list for each meaningful session.
- Keep entries short: what was worked on, decisions made, files touched, and open follow-ups.
- To resume a prior session in the terminal: `claude --resume` (interactive picker) or `claude --continue` (most recent in this directory).

## Entry template

```
### YYYY-MM-DD — <short title>
- **Goal:** <what the user wanted>
- **Changes:** <files/areas modified>
- **Decisions:** <non-obvious choices and why>
- **Open items:** <follow-ups, TODOs, blockers>
```

## Sessions

### 2026-05-20 — Notice under top island + focus-panel re-fit bug + stale banner overlay

- **Goal:** From the rider's screenshot — (1) notice banner was sitting at the very top, overlapping the dispatch top island; (2) accepting a job still cropped the Navigate button (previous re-fit attempt didn't actually move the panel); (3) the "no internet / showing cached" banner pushed the top bar down instead of floating.
- **Changes:**
  - **`dispatch_notice_service.dart`** — `DispatchNoticeController` gained `RxDouble topInsetExtra` (default 0). `DispatchNoticeHost` reads it via `Obx` and adds it to the SafeArea's top padding, so any screen with its own floating top bar can push the global banner *underneath* it. Also extracted the AnimatedSwitcher into `_animatedBanner(notice, onDismiss)` to keep the host build readable.
  - **`dispatch_jobs_page.dart`** —
    - `initState` schedules `topInsetExtra = _kTopBarTop + _kTopBarHeight + 8` (= 72); `dispose` resets it to 0. Banner now floats just under the island on this page only.
    - **Focus-panel re-fit bug fixed.** In `_openToFitContent({keepFracIfDragged})`, the "rider hasn't dragged" check used to read `(_frac - _fitFrac).abs() < 0.02` *after* `_fitFrac` was overwritten with the new target — so once the content grew (Accept adds the "Started" row + Finish/Navigate buttons), the diff was always > 0.02 and `_frac` was never updated. Captured `wasAtPreviousFit` *before* the setState; the panel now correctly snaps to the new fit when the underlying job changes.
    - **Stale-cache banner moved off the Column.** Was a top-anchored Material strip in a `Column` that pushed the top bar down. Now a `Positioned(bottom:)` overlay inside the map Stack — bottom-anchored, floating above the carousel (or above the focused panel when one is open, via `_panelFracLive` + `selectedJobId`), with a side margin so it reads as a floating pill. Restyled to `palette.card` with a hairline border, amber cloud-off icon, brand-green Retry — matches the dispatch notice banner. The outer Column wrapping map + banner is gone; the page is now just the map Stack.
- **Decisions:**
  - `topInsetExtra` is global state rather than a per-screen prop because the notice host is mounted by `GetMaterialApp.builder` above the route — there's no clean way to thread a screen-specific prop in. The per-screen `initState`/`dispose` pattern is the contract; legacy/profile/history screens leave it at 0 and the banner sits at the status bar like before.
  - Anchoring the stale banner to `_panelFracLive` (live drag value) rather than `_panelFrac` (settle-only) so it tracks the panel edge during the drag — same trick already used for the recenter button.
  - `flutter analyze` on both touched files: clean.
- **Open items:**
  - If the profile or history pages later add their own floating top bars, they should follow the same `topInsetExtra` pattern on init/dispose.

### 2026-05-20 — Finish-job inputs un-wrapped + required-field gating + focus-panel re-fit on accept

- **Goal:** Drop the redundant card wrappers around the finish-job inputs; require ≥2 photos + a meter number before submit (notes still optional); keep the focused-job panel the same visual size after Accept so the rider doesn't have to scroll for the Navigate button; sharpen the post-accept notice.
- **Changes:**
  - **`dispatch_constants.dart`** — new `DispatchConstants.minPhotos = 2` for the client-side proof-of-work threshold.
  - **`dispatch_finish_job_page.dart`** — removed the three `_DetailCard` wrappers from the Proof / Meter / Notes sections; the inputs themselves are the boxes now. New `_PhotoCounter` (turns brand-green once the rider hits the minimum, "min N" hint) replaces the plain `n/max photos` text. New `_canSubmit` getter — `Submit` is disabled unless `_photos.length ≥ minPhotos` *and* meter is non-empty (a `_meterCtrl.addListener` triggers live rebuilds). `_submit()` now early-returns a `_notices.info(...)` if either rule is violated as a belt-and-braces guard. `_MissingRequirementsHint` shows beneath the disabled button explaining what's missing. Removed `_DetailCard` class.
  - **`dispatch_jobs_page.dart`** —
    - `_FocusedJobPanelState` gained `didUpdateWidget`: when the job's actionable state changes (`isOnTheWay`/`actualArrival`/`finishWhen`/`isReschedulePending` flip, or `hasOtherActive`/`isNextInQueue` change), it schedules a post-frame `_openToFitContent(keepFracIfDragged: true)`. The new flag means a rider who has dragged the panel away from the previous fit anchor keeps their chosen height; otherwise the panel re-snaps to the freshly-measured fit. This is the fix for the "Accept → Navigate is below the fold" report.
    - `_startJob` notice changed `'Job accepted.'` → `'Job accepted — you are on the way.'` (the post-accept state in one line).
- **Decisions:**
  - Validation lives in the page, not the controller: the contract still accepts photo-less finish (server-side), but the rider workflow requires it. Centralising the minimum in `DispatchConstants.minPhotos` so the threshold is changed in one place.
  - The `Submit` button is *visibly* disabled when requirements aren't met (palette-aware faded fill) and the missing-requirements hint sits directly below it — this is more obvious than a silent disable, and avoids needing an inline red error on the fields themselves.
  - Re-measuring on `didUpdateWidget` instead of on a controller `ever()`: the panel already gets a fresh `widget.job` whenever the parent's `Obx(jobs)` rebuilds, so this is the natural seam — and it stays self-contained inside the panel widget.
  - `flutter analyze` on the three touched files: clean.
- **Open items:**
  - The previous re-measure was only ever called once on first open, which is why the post-accept overflow existed in the first place — keeping this in mind for any future panel content that grows after open.

### 2026-05-20 — Pinned home_widget to 0.7.x to restore Android build

- **Goal:** `flutter run` was failing `:app:checkDebugAarMetadata` — alpha transitive deps (`androidx.glance:glance-appwidget:1.3.0-alpha01`, `androidx.compose.remote:remote-creation-android:1.0.0-alpha11`) required compileSdk 37 / AGP 9.1.0, but the project is on compileSdk 36 / AGP 8.9.1.
- **Changes:**
  - **`pubspec.yaml`** — `home_widget: ^0.8.1` → `^0.7.0` (resolved to `0.7.0+1`). 0.8.x is the version that started pulling the alpha glance/compose-remote deps; 0.7.x is the last stable release that compiles cleanly against compileSdk 36.
  - `flutter pub get` + `flutter build apk --debug`: **green** (`Built build\app\outputs\flutter-apk\app-debug.apk`).
- **Decisions:**
  - User picked the pin over a Gradle `resolutionStrategy.force` or an AGP/compileSdk upgrade — the pin is the lowest-risk fix and avoids needing Java 17 locally for the AGP 9.x upgrade path.
  - Remaining build output includes `JobIntentService is deprecated` and one `unnecessary !!` warning from `home_widget-0.7.0+1` — non-fatal upstream warnings, ignored.
- **Open items:**
  - If `home_widget` features beyond what 0.7.x ships are needed later, the proper fix is bumping AGP to 9.1+ and compileSdk to 37 (and Java 17+ on dev machines).

### 2026-05-20 — Finish-job page palette pass + themed logout modal + notice on finish

- **Goal:** Redesign the finish-job page to the profile/history/overview standard; restyle the log-out confirmation modal so its colours follow the dispatch palette; route the finish-job feedback through the existing `DispatchNoticeController` instead of the legacy `SnackBar`.
- **Changes:**
  - **`dispatch_finish_job_page.dart`** — rewritten palette-driven: `palette.pageSurface` scaffold, hairline-bordered app bar matching the history page, all-caps `_SectionLabel`s ("Proof of work" / "Meter number" / "Notes"), bordered `_DetailCard` blocks. New `_PhotoPickButton` (palette outline, brand-green icon), `_PaletteTextField` (filled `pageSurface`, hairline border, green focus ring, `palette.subtle` counter), themed empty-photo state. Submit is a 50 px brand-green `FilledButton`. The `_toast`/`ScaffoldMessenger.showSnackBar` calls are all replaced with `Get.find<DispatchNoticeController>().success/info/error` — including the "Job finished." / "Saved offline." / API error paths — so the new top banner is the one in use.
  - **`dispatch_profile_page.dart`** — replaced the default `AlertDialog` `_confirmLogout` with a new `_LogoutConfirmDialog`: `Dialog(palette.card)` surface, hairline `cardBorder`, ink/subtle text, a danger-tinted circular logout icon, an outlined Cancel + red `FilledButton` Log out. `showDialog` now also dims the barrier (`Colors.black @45%`) for consistency.
- **Decisions:**
  - The notice banner already exists app-wide (`DispatchNoticeHost` via `GetMaterialApp.builder`) and is what the dispatch jobs page uses — the finish page was the lingering screen still on `ScaffoldMessenger`. Hooking it up here means the "Job finished" toast now drops in from the top with the themed card design instead of a black Material snackbar.
  - Logout modal kept as a `Dialog` (not a bottom sheet) since the user's wording was "modal"; the danger affordance is a red `FilledButton` matching the `_ActionRow(danger: true)` colour already used in the row that opens it.
  - `flutter analyze` on both files: clean.
- **Open items:**
  - `dispatch_job_detail_page.dart` is the remaining unredesigned dispatch screen — same palette pattern applies.

### 2026-05-19 — Animated route preview + distance-flicker fix

- **Goal:** Animate the all-jobs route preview (drawing stop 1→2→…); stop the job-card distance flickering blank.
- **Changes (`dispatch_jobs_controller.dart`):**
  - Route-preview animation: new `previewRevealCount` `RxInt` + `_previewAnimTimer`/`_previewAnimClock` + `_startPreviewAnim`/`_stopPreviewAnim` (1.7 s reveal). `_fetchPreviewRoute({animate})` — `animate: true` from `toggleRoutePreview` draws the line on stop-by-stop; the silent refetch from `_onJobsChanged` snaps to the full line. New `_clearPreview()` helper used by `selectJob`/`recenterOnRider`/preview-off.
  - Distance flicker: removed every eager `etaMeters.value = null` — from `selectJob`, `clearSelection`, and `_maybeFetchEta`'s no-target branch. `etaMeters` is now only ever *set* to a real OSRM distance, never blanked.
  - **`dispatch_jobs_page.dart`** — `_routePreviewMapData` takes a `revealCount` and `sublist`s the preview polyline; `_buildMapArea` reads `previewRevealCount` reactively.
- **Decisions:**
  - The flicker's root cause was the periodic poll: a momentarily un-geocoded ETA target (backend geocoding race) hit `_maybeFetchEta`'s no-target branch and nulled a good distance. Keeping the last value (like the earlier OSRM-miss fix) trades a brief staleness on job-switch for no flicker — the better deal.
  - Preview reveal re-uses the focused-route reveal pattern; it animates only on toggle-on, snaps on background refetches.
  - `flutter analyze`: clean.
- **Open items:** none for this set.

### 2026-05-19 — App-wide notice banner + auth/detail page redesigns

- **Goal:** Promote the notice banner app-wide (dispatch only, not legacy); redesign the history detail, welcome, dispatch login, and activate pages to the dispatch palette standard.
- **Changes:**
  - **New `service/dispatch_notice_service.dart`** — `DispatchNoticeController` (GetxController, app-wide), `DispatchNotice`/`DispatchNoticeKind`, and `DispatchNoticeHost` (the banner overlay). `main.dart` registers the controller and wraps every screen via `GetMaterialApp.builder` → `DispatchNoticeHost`, so the banner floats at the top of any screen.
  - **`dispatch_jobs_page.dart`** — removed its local notice classes/state; now calls `Get.find<DispatchNoticeController>()` (`.success/.info/.error`).
  - **New `widget/dispatch_auth_widgets.dart`** — shared `DispatchBrandHeader` (green branded header), `DispatchTextField` (palette field, green focus ring), `DispatchErrorText`, `DispatchPrimaryButton`.
  - **`dispatch_login_page.dart` / `dispatch_activate_page.dart`** — rewritten: green brand header + palette form + green primary button; dropped the legacy `AuthButton`/`AuthTextField`.
  - **`login_chooser_page.dart`** (welcome) — palette-driven: brand-tinted logo, ink/subtle text, palette choice cards.
  - **`dispatch_job_history_page.dart`** — the detail page (`DispatchJobHistoryDetailPage`) redesigned to match the history list: pageSurface scaffold, hairline app bar, flat section-labelled `_DetailCard` blocks (details / timeline / photos), palette colours throughout. Replaced the old `Card`/`_StatusChip`/`Colors.grey` widgets.
- **Decisions:**
  - The notice host wraps all routes but is dormant unless `show()` is called — legacy screens never call it, satisfying "don't attach to legacy". The banner now sits at the screen top (over the island/app bar) rather than below the jobs-page island, since it's global.
  - `flutter analyze` on `lib/page/dispatch`, the chooser, and `main.dart`: clean.
- **Open items:**
  - Other dispatch pages (finish-job, disabled, job-detail in `dispatch_job_detail_page.dart`) not yet redesigned — same palette pattern applies.

### 2026-05-19 — Top notice banner + route button disabled when no jobs

- **Goal:** Disable the route-viewer button when there are no jobs; replace the plain bottom snackbars with a designed top notice banner.
- **Changes (`dispatch_jobs_page.dart`):**
  - Route-preview toggle in the top island: greyed out (`subtle @40%`) and `onPressed: null` when there are no unfinished jobs; tooltip "No jobs to route".
  - New in-app notice system replacing `SnackbarUtils` on this page: `_DispatchNotice` + `_NoticeKind` (success/error/info), an `Rxn<_DispatchNotice>` on the page state, `_showNotice()` (auto-dismiss after 4 s, restarts on replace) / `_dismissNotice()`, timer cancelled in a new `dispose()`.
  - `_NoticeBanner` — a themed `palette.card` banner (kind-coloured icon, message, close button) shown in a `Positioned` just below the top island, via an `AnimatedSwitcher` with a `ClipRect` + slide-from-top + fade transition: it drops in from the top and always exits *upward*. Swipe-up (`onVerticalDragEnd`, negative velocity) or the close icon dismisses it.
  - The 5 `_startJob`/`_select` snackbar calls now use `_showNotice`; `snackbar_utils.dart` import removed.
- **Decisions:**
  - Used a swipe-up *gesture → dismiss* rather than a `Dismissible`, so every exit path (swipe, tap-close, auto-timeout) runs the same upward `AnimatedSwitcher` animation — consistent and avoids Dismissible/AnimatedSwitcher double-animation.
  - Notice system is scoped to the dispatch jobs page (it anchors to that page's top island). Other pages still use `SnackbarUtils`.
  - `flutter analyze`: clean.
- **Open items:**
  - If a top notice is wanted app-wide, the `_DispatchNotice`/`_NoticeBanner` could be promoted to a shared overlay service.

### 2026-05-19 — Job history list redesigned to match the overview page

- **Goal:** Refactor the job history list to match the overview page's flat, theme-aware design.
- **Changes (`dispatch_job_history_page.dart`):**
  - `DispatchJobHistoryPage` — `Scaffold`/`AppBar` now palette-driven and dark-aware (white→`pageSurface`, hairline-bordered app bar, bold title), mirroring `DispatchJobsOverviewPage`. Loading spinner is brand green; error/empty states use `palette.subtle`.
  - Replaced the elevated `_HistoryCard` (icon rows, bordered card) with `_HistoryRow` — a flat, divider-separated row matching `_OverviewJobRow`: 4 px green accent bar + `COMPLETED` label + finish timestamp + customer/address. List is `ListView.separated` with indented `Divider`s.
- **Decisions:**
  - Only the history *list* page was redesigned (as asked). The reached-from-it `DispatchJobHistoryDetailPage` was left as-is — still uses `Card`/`Theme` + some hardcoded greys, so it's only partially dark-aware.
  - `flutter analyze`: clean.
- **Open items:**
  - `DispatchJobHistoryDetailPage` could get the same palette pass for full dark consistency.

### 2026-05-19 — Dropped the dark-mode map feature

- **Goal:** Remove the dark-mode map basemap feature (none of the options satisfied; revisit later).
- **Changes:**
  - **`flutter_map_widget.dart`** — removed `_basemapUrl`, the `isDark` lookup, the `AppConfig` import; `TileLayer` is back to plain OpenStreetMap tiles always.
  - **`google_map_widget.dart`** — removed `_kDarkMapStyle` and the `GoogleMap.style` dark styling.
  - **`app_config.dart`** — removed `stadiaApiKey`/`hasStadiaKey`.
- **Decisions:**
  - Only the *map basemap* dark feature was dropped. The rest of dark mode stays — app theme, the System/Light/Dark profile toggle, the `DispatchPalette` light/dark neutrals, and the dark-aware dispatch chrome. The map just always shows light OSM tiles now.
  - `flutter analyze`: clean.
- **Open items:** dark map can be revisited (keyless Esri / vector OpenFreeMap, or a paid Stadia/MapTiler tier) if wanted later.

### 2026-05-19 — Dark basemap → Stadia "Alidade Smooth Dark"

- **Goal:** Swap the dark basemap to Stadia (MapTiler's 100k/mo free tier was too small).
- **Changes:**
  - **`app_config.dart`** — `maptilerApiKey`/`hasMaptilerKey` replaced with `stadiaApiKey`/`hasStadiaKey` (`--dart-define=STADIA_API_KEY=…`).
  - **`flutter_map_widget.dart`** — `_basemapUrl(dark)`: dark → Stadia `alidade_smooth_dark` (`tiles.stadiamaps.com/tiles/alidade_smooth_dark/...?api_key=`) when a key is set, else CARTO `dark_all` keyless fallback.
- **Decisions:**
  - User picked Stadia (200k/mo free, best Google-like look) after rejecting MapTiler's 100k limit; Esri Dark Gray and vector OpenFreeMap were the other options offered.
  - `flutter analyze`: clean.
- **Open items:**
  - Needs a free Stadia account + `--dart-define=STADIA_API_KEY=…`; without it dark mode falls back to CARTO dark.
  - **Stadia free tier is non-commercial only** — a commercial fleet deployment needs a paid Stadia plan (or switch to a keyless option).
  - Tile attribution (Stadia/OSM) still not shown — add before public release.

### 2026-05-19 — True dark map tiles (CARTO dark basemap)

- **Goal:** Replace the greyscale-invert dark map (looked like a photo negative) with a real dark basemap.
- **Changes (`flutter_map_widget.dart`):** dropped the `_darkModeTile` `ColorFilter` invert + `tileBuilder`. The `TileLayer` now swaps its `urlTemplate` by brightness — `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png` (CARTO dark cartography, `subdomains: a–d`) in dark mode, standard OSM tiles in light.
- **Decisions:**
  - CARTO dark basemap = genuine dark cartography (dark land, muted roads) vs the inverted-grey hack; no API key needed, no new dependency.
  - Google Maps path already uses a real night style — only the flutter_map/OSM path needed this. (Reminder: `AdaptiveMap` only uses `GoogleMapWidget` when `--dart-define=GOOGLE_MAPS_API_KEY` is set; otherwise everyone is on flutter_map/OSM.)
  - `flutter analyze`: clean.
- **Open items:**
  - CARTO basemap tiles want attribution ("© OpenStreetMap contributors, © CARTO"); the map currently shows no attribution overlay at all (pre-existing) — fine for an internal app, worth adding for a public release.

### 2026-05-19 — Dark map tiles, honest job counter, no empty card

- **Goal:** Dark mode for the map itself; fix the misleading bar job counter; drop the redundant empty-job card.
- **Changes:**
  - **`flutter_map_widget.dart`** — `TileLayer.tileBuilder` recolours OSM tiles into an inverted grey-scale dark basemap (`ColorFilter.matrix`) when `Theme.brightness == dark`; markers/routes drawn above keep their colours. (Also fixed the `userAgentPackageName` typo `quetra`→`querta`.)
  - **`google_map_widget.dart`** — added a `_kDarkMapStyle` night-style JSON, applied via `GoogleMap.style` in dark mode.
  - **`dispatch_jobs_page.dart`** — bar centre counter changed from `"$done of $total jobs done"` (which only shrank, since finished jobs leave the list) to a plain remaining count: `"N jobs remaining"` / `"1 job remaining"` / `"No pending jobs"`. Removed the `_EmptyJobCard` (and `_JobCarousel`'s empty branch); when there are no jobs the carousel renders `SizedBox.shrink` — the bar already states it. Map `bottomInset` and the recenter button's offset now collapse to no-carousel height when the job list is empty. Stale-banner text given an explicit dark-amber colour so it stays legible on its pale background in dark mode.
- **Decisions:**
  - Map dark mode for flutter_map done via per-tile `ColorFilter` (grey-scale invert) — no third-party tile provider / dependency, and overlays stay full-colour. Google uses the standard night-style JSON.
  - Counter: finished jobs drop out of `jobs`, so "done/total" is structurally misleading — a remaining-count is the honest signal. Stop numbers (route order) already convey sequence on the cards.
  - `flutter analyze` on all touched files: clean.
- **Open items:**
  - If a route-position counter ("Stop 3 of 8") is wanted instead of a remaining-count, that needs the route's original total — not derivable once finished jobs leave the list (would need the backend to include them or send a route length).

### 2026-05-19 — Centralised palette + dark-aware dispatch screens + profile redesign

- **Goal:** Dark-aware colour pass on the dispatch screens; redesign the profile page on-brand; make re-skinning a one-file change.
- **Changes:**
  - **New `core/theme/dispatch_palette.dart`** — the single source of truth. `DispatchColors` holds mode-independent brand colours (brand green, accent yellow, route hexes); `DispatchPalette` is a `ThemeExtension` with theme-dependent neutrals (`pageSurface`, `card`, `cardBorder`, `control`, `ink`, `subtle`, `divider`) as `light`/`dark` instances. `context.dispatch` extension for concise access.
  - **`app_theme.dart`** — registers `DispatchPalette.light`/`.dark` via `ThemeData.extensions`.
  - **`dispatch_jobs_overview_page.dart`** — fully palette-driven (scaffold/appbar/rows/dividers): proper light + dark. Status now a coloured accent bar + neutral label.
  - **`dispatch_profile_page.dart`** — redesigned: branded green header (avatar, name, role chip), all-caps section labels, custom theme-aware tiles (`_InfoRow`, `_ActionRow`, `_ThemeModeTile`), palette colours throughout.
  - **`dispatch_jobs_page.dart`** — neutral chrome (top island, sync chip, recenter FAB, empty-job card) now reads `context.dispatch`; route hexes + the card green sourced from `DispatchColors`. Brand-green elements (job cards, focus panel) intentionally stay green in both modes.
- **Decisions:**
  - Two-tier palette: brand colours are plain `const`s (no `context` needed, mode-independent); only neutrals are a `ThemeExtension` (need light/dark + `context`). Re-skin = edit `dispatch_palette.dart` only.
  - Brand-green cards/panel are a deliberate identity element — kept green in dark mode rather than turned neutral.
  - `flutter analyze` on all touched files: clean. (Repo-wide 118 pre-existing `info` lints are all in legacy `page/profile` & `page/vehicles` — untouched.)
- **Open items:**
  - Secondary dispatch pages (finish-job, job-history, job-detail, login, activate, disabled) not yet palette-passed — they inherit the now dark-aware `Scaffold`/`AppBar`/`Card`/`Theme`, so they partially adapt, but any hard-coded colours in them remain. Same `context.dispatch` pattern applies.
  - Rider-marker blue is still hard-coded in the map painters (a map overlay — fine in either mode).

### 2026-05-19 — Dark mode (system-default + profile toggle)

- **Goal:** Add a dark mode that initially follows the OS setting, with a user override in the profile page.
- **Changes:**
  - **New `core/theme/theme_controller.dart`** — `ThemeController` (GetxController): `Rx<ThemeMode>` defaulting to `system`; `load()` restores the persisted choice from SharedPreferences (`app.theme_mode`); `setThemeMode()` applies via `Get.changeThemeMode` and persists.
  - **`core/theme/app_theme.dart`** — added `AppTheme.dark()` mirroring `light()` (dark surface/card/border/text palette, `Brightness.dark` colour scheme).
  - **`main.dart`** — loads `ThemeController` before `runApp` (no wrong-theme flash); `GetMaterialApp` now has `darkTheme` + `themeMode`.
  - **`dispatch_profile_page.dart`** — new `_AppearanceCard` with a `SegmentedButton` (System / Light / Dark) wired to the controller.
- **Decisions:**
  - `ThemeController` loaded synchronously-awaited in `main` so the first frame is already correct.
  - **Coverage caveat:** the dispatch screens (jobs map, focus panel, cards, overview, top island) use hard-coded colours (`Colors.white`, brand greens, `0xFF…`), so they will NOT restyle under dark mode — only theme-aware widgets (legacy screens, `Scaffold`/`AppBar`/`Card`/inputs, the profile page) adapt. Full dark coverage of the dispatch UI needs per-screen dark variants.
  - `flutter analyze` on all four files: clean.
- **Open items:**
  - Dispatch surfaces need a dark-aware colour pass for complete dark-mode coverage; the toggle/mechanism is in place.

### 2026-05-19 — Focus panel opens sized to its content (no scroll needed)

- **Goal:** The focused job panel opened at a fixed 40 % and clipped the action buttons below the fold — make everything visible on open without scrolling.
- **Changes (`dispatch_jobs_page.dart`, `_FocusedJobPanelState`):**
  - Replaced the fixed `_midFrac` anchor with a measured `_fitFrac`: a `GlobalKey` (`_contentKey`) on the content column; after the first frame `_openToFitContent` reads `contentH` and opens the panel at `(_handleHeight + contentH + bottomSafe + 6) / screenH`, clamped to `[_minFrac, _maxFrac]`.
  - The header was moved *inside* the scrollable content column (previously pinned above it) so the one `_contentKey` measures the whole panel content in a single pass.
  - Snap anchors are now `[_minFrac, _fitFrac, _maxFrac]` (instance getter); `_onHandleTap` toggles content-fit ↔ near-full. Grow-from-card entry preserved — it now expands to the fitted height instead of a flat 40 %.
- **Decisions:**
  - Content-measurement chosen over just bumping `_midFrac`: panel content varies (job-name lines, notes, the accept-blocked notice), so a fixed fraction would still clip some jobs. The `SingleChildScrollView` remains as a fallback only — engaged when content genuinely exceeds `_maxFrac` (0.88) or the panel is dragged shorter.
  - `flutter analyze`: clean.
- **Open items:**
  - The panel measures once on open; if job content changes afterwards (e.g. notes edited live) it won't re-fit — the scroll fallback covers that.

### 2026-05-19 — Bar centring + overview page redesign

- **Goal:** Truly centre the bar's status readout; drop its tap-to-open behaviour; redesign the overview page so it no longer looks like a delivery-app (Grab) list; header just "Overview".
- **Changes:**
  - **`dispatch_jobs_page.dart`** — the bar content is now a `Stack` (alignment centre) instead of a `Row` with an `Expanded`: the date/progress summary is centred over the *whole* bar width regardless of the uneven edge controls, and wrapped in `IgnorePointer` (no longer an `InkWell` opening the overview). Edge controls (job-list, route, profile) sit in an overlaid `Row`.
  - **`dispatch_jobs_overview_page.dart`** — full redesign away from the bordered-card / pill / chevron look: white `AppBar` titled "Overview" with a hairline bottom border; a flat `ListView` of rows separated by indented dividers; each row is a slim status-coloured accent bar + "STOP n" label + status word + customer/address. New `_statusOf` record helper drives the per-status accent/label colours (green / yellow accent / amber / grey).
- **Decisions:**
  - Bar summary kept as a live readout but display-only — the job-list button already opens the overview, so the centre tap target was redundant.
  - Overview redesign: removed elevated cards, status pills, circular numbered badges and chevrons (the "Grab" cues); replaced with a flat divided list and a left accent bar — reads as a utility/list screen.
  - `flutter analyze` on both files: clean.
- **Open items:** none outstanding for this set.

### 2026-05-19 — Top island: squarish profile, route-clearance, progress summary

- **Goal:** Profile button back to a squarish shape; stop the route view hiding behind the new top island; fill the island's empty middle with something functional.
- **Changes (`dispatch_jobs_page.dart`):**
  - Profile button changed from `CircleBorder` to a `borderRadius: 12` rounded square, matching the bar.
  - Route-clearance fix: new `_kTopBarTop` (8) / `_kTopBarHeight` (56) constants; the island is now a fixed-height `SizedBox`. The map's `topInset` (was just `mq.padding.top`) is now `mapTopInset = statusBar + _kTopBarTop + _kTopBarHeight + 8`, so `CameraFit` padding keeps framed routes below the island instead of behind it. Sync chip repositioned off the same constants.
  - Filled the island's blank centre with a tap-through summary: today's date (`EEE, MMM d`) over a live "`$done of $total jobs done`" count, wrapped in an `InkWell` that opens `DispatchJobsOverviewPage`.
- **Decisions:**
  - The blank space was called out as purposeless — made it a live status readout + secondary entry point to the job list, rather than just shrinking the bar.
  - `flutter analyze`: clean.
- **Open items:** none outstanding for this set.

### 2026-05-19 — Recenter lag fix, white button, floating top bar, overview page

- **Goal:** Stop the recenter button lagging behind the panel mid-drag; make the button plain white; add a floating top island (job-list + route toggle, profile circle); add a job overview list page.
- **Changes:**
  - **`dispatch_jobs_page.dart`:**
    - Recenter lag fix — new `_panelDragging` `RxBool`; `_FocusedJobPanel` takes a `panelDragging` `RxBool` and flips it in `_onDragStart`/`_onDragEnd`. The recenter `AnimatedPadding` now uses `Duration.zero` while dragging (tracks the finger frame-for-frame) and 260 ms on settle.
    - Recenter FAB `backgroundColor: Colors.white` (was the themed light-blue `primaryContainer`); icon colour left as-is.
    - New floating top island: `Positioned` white rounded `Material` — left side a job-list button (→ `DispatchJobsOverviewPage`) and the route-preview toggle; right side the profile entry as a green circle. The standalone top-right profile FAB and the bottom route-preview FAB were removed; the pending-sync chip moved to sit just below the island.
    - Removed the now-unused `_kOrmecoGreen` constant (green now sourced from `_DispatchJobCard._kCardGreen`, `#2d9353`).
  - **New `dispatch_jobs_overview_page.dart`:** a plain scrollable list of today's jobs (route-order sorted) with pull-to-refresh; green app bar, white tiles, grey secondary text, green stop-number discs and status pills. Tapping a tile calls `selectJob` and pops back to the map.
- **Decisions:**
  - The drag-vs-settle split is why the lag existed: `AnimatedPadding` was always easing (220 ms) even mid-drag. Gating the duration on `_panelDragging` keeps the button glued during the drag and smooth on release (matching the panel's own 260 ms `AnimatedContainer`).
  - `flutter analyze` on both files: clean.
  - Dispatch palette clarified by the user: green `#2d9353`, yellow accent `#e8e241`, white `#ffffff`, grey. The yellow accent is applied in `dispatch_jobs_overview_page.dart` — the in-progress ("on the way") job's tile gets a 2 px `#e8e241` border and its status pill uses `#e8e241` fill with dark text.
- **Open items:**
  - Overview page tile tap selects even a no-coordinate job (which won't open a map panel) — currently silent; could add a notice.

### 2026-05-19 — Carousel position fix + sticky recenter button

- **Goal:** Stop the carousel jumping to mid-screen when closing an enlarged focus panel; make the recenter button stick to the panel's top edge; make recenter re-frame the route (not the rider) while a job is focused.
- **Changes (`dispatch_jobs_page.dart`):**
  - `AnimatedSwitcher` given a `layoutBuilder` with `Alignment.bottomCenter` — the default centres in/out children, so the short carousel floated to mid-screen while a tall panel faded out. Now both are bottom-pinned; the carousel never leaves its resting position.
  - New `_panelFracLive` `RxDouble` — updated continuously during the drag (vs `_panelFrac`, settle-only). `_FocusedJobPanel` gained an `onFracLive` callback fired from `_onDragUpdate`/`_onDragEnd`/`_onHandleTap`/entry; `_panelFrac` is left settle-only so the map camera doesn't re-frame every drag frame.
  - The recenter + route-preview FABs (previously two fixed `Positioned`s anchored to `_kCarouselHeight`) are now one `Positioned.fill` → `Obx` → `Align(bottomRight)` → `AnimatedPadding`. Bottom offset = `screenH * _panelFracLive + 12` when focused, else the carousel offset. Fades out (`AnimatedOpacity` + `IgnorePointer`) once `frac > 0.8`. Route-preview FAB shown in the overview only.
  - **`dispatch_jobs_controller.dart`** — `recenterOnRider` now sets `followRider = (selectedJobId == null)`: focused → leaves `followRider` false so the focused map data's route bounds survive and the bumped `recenterTick` re-fits them; overview → follows the rider as before.
- **Decisions:**
  - Two separate fractions (live vs settle) deliberately: feeding live drag values to the map's bottom-inset would re-fit the camera every frame (thrash). The button reads live; the camera reads settle.
  - `flutter analyze` on both files: clean.
- **Open items:** none outstanding for this set.

### 2026-05-19 — Focused job panel restyled to grow from the card

- **Goal:** Make the focused job panel flow naturally from the carousel card — ideally the card appears to enlarge into the detail panel.
- **Changes (`dispatch_jobs_page.dart`):**
  - `_FocusedJobPanel` restyled from a white `scheme.surface` sheet to the same green (`#2d9353`) as the carousel card: rounded top corners, white-translucent drag handle, header mirroring the card (white stop-number disc, white bold name, close button), a `DESTINATION` block + hairline divider, then the white-on-green detail rows.
  - Grow-from-card entry: `_FocusedJobPanelState` gained an `_entered` flag — first build opens the panel at `~_kCarouselHeight/screenH` and a post-frame `setState` expands it to `_midFrac`, so the `AnimatedContainer` animates the height growth (snap duration 220→260ms).
  - `AnimatedSwitcher` transition simplified from fade+slide to a plain cross-fade — green-card→green-panel, the growth carries the motion.
  - `_PanelActions` reworked for the green background: primary Accept/Finish button is now white-fill / green-label, Navigate is white-outlined, the accept-blocked notice is a white-translucent box.
  - `_InfoRow` text recoloured white/white-muted. Removed the now-unused top-level `_primaryButtonStyle` and `_DispatchJobCard._kMeta`.
- **Decisions:**
  - Kept the existing draggable bottom-sheet behaviour (min/mid/max anchors) — only restyled. A true Hero/container-transform was avoided: the panels are GetX/`Obx`-driven, not route-based, so matching the green identity + animating the height growth gives the "card enlarging" feel without that complexity.
  - `flutter analyze` on the file: clean.
- **Open items:**
  - Panel *close* still just cross-fades back to the carousel (it doesn't visually shrink into the card) — acceptable, but a reverse animation could be added if desired.

### 2026-05-19 — Job card name wrapping + distance-estimate blanking fix

- **Goal:** Show the full job name on the carousel card (was truncated to one line), and stop the card's distance estimate from intermittently blanking out.
- **Changes:**
  - **`dispatch_jobs_controller.dart`** — `_maybeFetchEta` no longer assigns `etaMeters.value = result?.distanceMeters` directly: it only writes when the OSRM distance is non-null, otherwise keeps the last good value and clears `_lastEtaKey` so the next poll retries. The `catch` block now also clears the memo key.
  - **`dispatch_jobs_page.dart`** — `_DispatchJobCard` name `Text` changed `maxLines: 1` → `maxLines: 3` (header `Row` now `crossAxisAlignment: start` so the stop-number/pill align to the top of a wrapped name). `_kCarouselHeight` 212 → 240 so a three-line name can't overflow the fixed-height card.
- **Decisions:**
  - Root cause of the blanking: the demo OSRM server intermittently returns no route; `_maybeFetchEta` was overwriting `etaMeters` with `null` on those misses (correlated with the user's `[map] ... polylineZones=0` log). `_maybeFetchRoute` already preserved its last good polyline on failure — `_maybeFetchEta` now mirrors that for the distance.
  - `flutter analyze` on the 2 touched files: clean.
- **Open items:**
  - Intermittent OSRM misses themselves remain (rate-limited public/demo server) — the UI now degrades gracefully, but a self-hosted/proxied OSRM with caching would remove the misses entirely.

### 2026-05-19 — Blue active route + Google-Maps-style rider cone pin

- **Goal:** Revert the active driver route to blue (keep the preview line orange), and replace the rider arrow with a blue location dot carrying a Google-Maps-style view cone.
- **Changes:**
  - **`dispatch_jobs_page.dart`** — split the route colour back into two constants: `_kRouteHex = '#1976D2'` (blue) for the active focused/overview routes, `_kPreviewRouteHex = '#F59E0B'` (amber) for the all-jobs preview line.
  - **`flutter_map_widget.dart`** — `_buildRiderMarker` now renders a `CustomPaint` (`_RiderMarkerPainter`): a blue dot (shadow + white ring + blue core) with a translucent radial-gradient direction cone fanning 64° wide, shown only when a heading is known. Rider marker box bumped 46→54px.
  - **`google_map_widget.dart`** — replaced the single arrow bitmap with two rasterised bitmaps, `_riderCone` (dot + cone) and `_riderDot` (plain dot), via a shared `_buildRiderBitmap({withCone})`. Marker picks cone when `m.rotation != null`, plain dot otherwise; both 54px, centre-anchored, rotated natively.
- **Decisions:**
  - Cone is drawn pointing north and oriented by rotation (`Transform.rotate` for flutter_map, native `Marker.rotation` for Google) — both backends kept visually identical.
  - Cone shows only when a heading exists; with none, it's a plain blue dot — matching Google Maps behaviour and the "regular blue pin + cone" request. Heading is still GPS-course-only (see below), so the cone appears once the driver moves.
  - `flutter analyze` on the 3 touched files: clean.
- **Open items:**
  - Still no compass — the cone only orients from GPS course, so it won't rotate while the driver is stationary. `flutter_compass` (throttled) remains the offered upgrade for true stationary direction sensitivity.

### 2026-05-19 — Orange route lines + always-on directional driver pin

- **Goal:** Make all route polylines yellow/orange, and fix the rider pin showing as a plain blue pin instead of a directional arrow.
- **Changes:**
  - **`dispatch_jobs_page.dart`** — replaced the per-mode route colours (active `#1976D2` blue, preview `#7C3AED` violet) with a single shared `_kRouteHex = '#F59E0B'` amber/orange used by the focused, overview, and preview polylines.
  - **`google_map_widget.dart`** — `useArrow` no longer requires `m.rotation != null`; the rasterised arrow bitmap is used for the rider marker unconditionally (still rotates via `Marker.rotation`, defaults to north).
  - **`flutter_map_widget.dart`** — `_buildRiderMarker` dropped the null-heading blue-dot fallback; always renders the `Icons.navigation` arrow, rotating by `heading ?? 0`.
- **Decisions:**
  - Root cause of the "blue pin": the arrow was gated on a non-null heading, but `riderHeading` only gets set from a GPS *course*, which Android reports only while moving (`speed >= 0.7 m/s`). A stationary driver therefore always hit the plain-pin fallback. Removing the gate means the arrow is always shown; it rotates once the driver moves and the controller retains that heading across later stationary fixes.
  - True *stationary* direction sensitivity (arrow turning as a parked driver rotates the phone) needs the magnetometer/compass — deferred: it requires a sensor package (`flutter_compass`), which is a dependency call and has known Android Gradle build risks. Flagged to the user.
  - `flutter analyze` on the 3 touched files: clean.
- **Open items:**
  - Compass-based heading not added — pin only rotates from GPS course (i.e. while moving). Offered `flutter_compass` integration (with update throttling to avoid map-rebuild storms) pending user go-ahead.

### 2026-05-19 — Dispatch connectivity fixes + job card redesign

- **Goal:** Resolve the "stuck loading / no internet" symptom and redesign the dispatch job carousel card per a ride-hailing reference screenshot.
- **Changes:**
  - **`dispatch_constants.dart`** — `DISPATCH_BASE_URL` default moved off the emulator-only `10.0.2.2` alias to the dev machine's current LAN IP `172.31.55.206:8000`.
  - **`variables.dart`** — legacy `BASE_URL` default updated `10.109.233.206` → `172.31.55.206` (the old IP was a stale DHCP lease).
  - **`dispatch_api_client.dart`** — added request timeouts: `_timeout` 15s for GET/POST, `_uploadTimeout` 60s for multipart; all three methods now catch `TimeoutException`. Reworded the `SocketException` message from the misleading "No internet connection" to "Couldn't reach the server. Check your connection and try again."
  - **`dispatch_jobs_page.dart`** — job carousel redesign: `_DispatchJobCard` is now a green (`#2d9353`) ride-style card with white text — header (stop no. + customer + status pill), `DESTINATION` address block, hairline divider, and a `SCHEDULED`/`DISTANCE` metadata row. Removed the cyan "next job" highlight border + arrow (and the `isNext`/`selected`/`_kNextBorder` members). `_JobCarousel` converted `StatelessWidget`→`StatefulWidget` using a `PageView` with `viewportFraction: 0.9` so cards are larger and snap to screen-centre. New `_kCarouselHeight = 212` constant (was inline `132`) wired into the map bottom-inset and FAB positions. Added `_CardLabel`/`_CardMetric` helpers and a `_compactTime` HH:mm formatter; `_StopNumber` gained `backgroundColor`/`foregroundColor` overrides; removed the now-unused `_CarouselConnector`.
- **Decisions:**
  - Root cause of the hang was twofold: (1) dispatch base URL pointed at the emulator alias, unreachable from a physical device; (2) no request timeout, so an unreachable host hung on the OS TCP timeout (1-2+ min) — the spinner looked "stuck". Timeouts make it fail fast regardless.
  - LAN IP is a DHCP lease and will drift — recommended the user pass `--dart-define=BASE_URL=…`/`DISPATCH_BASE_URL=…` at run time rather than relying on the committed defaults.
  - `flutter analyze` on the two touched files: clean.
- **Open items:**
  - Committed defaults still carry a machine-specific IP (`172.31.55.206`) — ideally revert these to production before merging and rely on `--dart-define` for local dev.
  - Legacy login (`auth_remote_datasource.dart:32`) and the app-wide `ApiClient` still have **no timeouts** — same hang risk; not yet addressed.
  - Earlier session's map-jank optimization (slow the route-reveal tick / split the `_buildMapArea` Obx) still not applied.

### 2026-05-19 — Investigate dispatch map jank / slow load

- **Goal:** User reported the app loads/feels slower than previous versions on an Android device; diagnose the cause.
- **Changes:** None — investigation only. Reviewed `dispatch_jobs_controller.dart`, `dispatch_jobs_page.dart`, `adaptive_map.dart`, `flutter_map_widget.dart`, `google_map_widget.dart`, `app_config.dart`, `dispatch_osrm_datasource.dart`.
- **Decisions:**
  - User clarified: symptom is "general jank/lag" inside the dispatch screens, running via plain `flutter run` (**debug build**). Debug mode is 3–10× slower (JIT, asserts live, no AOT) and especially janky with native platform-view maps — likely the dominant factor. Recommended measuring with `flutter run --profile` before optimizing.
  - Identified real rebuild-churn bugs worth fixing regardless: (1) route-reveal animation `_routeAnimTick = 16ms` over 800ms bumps `routeRevealCount`, and the broad `Obx` in `_buildMapArea` rebuilds the entire `AdaptiveMap` + all marker/zone model lists ~50× per route; (2) that same `Obx` also rebuilds the whole map on every `riderHeading`/`riderPos` poll and `recenterTick`; (3) debug-only `debugPrint` asserts fire on each rebuild.
  - Also noted: `AdaptiveMap` falls back to OSM `flutter_map` when `GOOGLE_MAPS_API_KEY` dart-define is absent (plain `flutter run` passes none) — OSM public tiles are rate-limited/slow; user-agent typo `com.quetra.fms` in `flutter_map_widget.dart:186` vs real package `com.querta.fms`.
- **Open items:**
  - Awaiting user decision: (a) apply targeted fixes — slow reveal tick to ~30fps + split the `_buildMapArea` `Obx` so markers don't rebuild during route animation; or (b) confirm jank in `--profile` mode first.
  - Fix the `userAgentPackageName` typo in `flutter_map_widget.dart` (`com.quetra.fms` → `com.querta.fms`).

### 2026-05-11 — Dispatch UI build-out on `main`

- **Goal:** Implement the full dispatch rider surface per `dispatch-mobile-api-contract.md` and `dispatch-mobile-app-flow.md`, side-by-side with the existing legacy app (no legacy backend changes).
- **Changes:**
  - **Local backend default**: [variables.dart](lib/core/constants/variables.dart) — `BASE_URL` defaults to `http://10.0.2.2:8000/myapi` for emulator dev against local Laravel + `efms` DB.
  - **Dispatch infrastructure**: [lib/core/dispatch/](lib/core/dispatch/) — `dispatch_constants.dart` (endpoints, prefs keys, contract limits), `dispatch_api_client.dart` (bearer + idempotency + `{data,meta,errors}` envelope + `DispatchApiException`), `dispatch_idempotency.dart` (persistent UUID v4 keys per action), `dispatch_uuid.dart` (RFC 4122 v4, no `uuid` pkg).
  - **Data layer**: [lib/data/dispatch/](lib/data/dispatch/) — `DispatchJob`/`DispatchRider`/`DispatchCompany`/`DispatchJobPhoto` models, `DispatchAuthDatasource` (activate/login/logout/me/refresh-fcm), `DispatchJobsDatasource` (today/detail/start/finish), `DispatchPositionDatasource`, `DispatchQueueRepository` (offline queue with photo copies in `<docs>/dispatch_queue_photos/`).
  - **Controllers**: [lib/page/dispatch/controller/](lib/page/dispatch/controller/) — `DispatchAuthController` (cold-start `/me`, 401/403-disabled handlers, persistent token/rider/company), `DispatchJobsController` (jobsToday + cache + foreground refresh via `WidgetsBindingObserver`, idempotency rules, network-failure enqueue throwing `DispatchQueuedException`).
  - **Services**: [lib/page/dispatch/service/](lib/page/dispatch/service/) — `DispatchFcmService` (`onTokenRefresh` → `/devices/refresh-fcm` + `onMessage`/`onMessageOpenedApp`/`getInitialMessage` → refresh jobs when `data.job_id` present), `DispatchPositionService` (45s GPS pings only while foregrounded + authed + ≥1 active job; suppresses on first 404), `DispatchSyncService` (drains offline queue FIFO on reconnect/auth-flip per §8.3).
  - **UI**: [lib/page/dispatch/presentation/](lib/page/dispatch/presentation/) — `DispatchLoginPage`, `DispatchActivatePage`, `DispatchJobsPage` (with stale-cache banner + pending-sync chip), `DispatchJobDetailPage` (status-gated Start/Finish + filename-only photos placeholder), `DispatchFinishJobPage` (≤5 photos × ≤4MB + notes ≤2000), `DispatchDisabledPage` (dead-end 403 screen).
  - **Integration**: [main.dart](lib/main.dart) registers `DispatchAuthController` + the three services as permanent; `RootGate` prefers dispatch (or `DispatchDisabledPage` when latched). [login_page.dart](lib/page/auth/presentation/login_page.dart) gained a "Rider sign-in (dispatch)" link.
  - **Polish**: Suppress Android 12+ stretch overscroll + bouncy physics globally via [no_stretch_scroll_behavior.dart](lib/core/widgets/no_stretch_scroll_behavior.dart) wired in `GetMaterialApp.scrollBehavior`.
  - **Dep**: Added `geolocator: ^13.0.2` to [pubspec.yaml](pubspec.yaml) for GPS pings; Android location permissions already present.
- **Decisions:**
  - **Side-by-side** legacy + dispatch (option B): both surfaces co-exist. `RootGate` prefers dispatch when both authed; legacy login screen has an explicit "Rider sign-in (dispatch)" entry point.
  - **No UUID dep**: hand-rolled v4 to keep `pubspec` lean.
  - **Photos display**: filenames-as-chips placeholder — backend has no rider-side image-serving endpoint yet (contract §9). Swap to network thumbnails once exposed.
  - **No optimistic UI** for start/finish (correctness over snappiness, per docs §8.4).
  - **Auth flip + nav unwind bug** fixed by `Get.offAll(() => const RootGate())` after login/activate instead of `popUntil` — the Obx swap was racing with route-stack manipulation.
  - **Persistent cache for `/jobs/today`** lives in SharedPreferences. On API failure, cached list stays visible with an amber "stale" banner instead of a blank error screen. Future refreshes overwrite on success.
- **Open items:**
  - **Backend bug**: `/jobs/today` currently returns 500 — `Call to member function toDateString() on string`. Fix in `laravel-fms` (cast `job_date`/`scheduled_arrival`/etc. as `date`/`datetime` on the dispatch Job model, or wrap with `Carbon::parse(...)`). Until then, first-ever launch on a fresh install still shows the error screen; once one successful fetch lands, the cache covers subsequent failures.
  - **Forgot-password** is admin-mediated only per contract; no app-side button.
  - **Photo thumbnails** pending backend signed-URL endpoint.
  - **Smoke test (contract §8)** end-to-end pending the toDateString fix.

### 2026-05-11 — Set up history.md
- **Goal:** Create a running log of Claude Code sessions to aid resuming closed conversations.
- **Changes:** Added `history.md` (this file).
- **Decisions:** Newest-first ordering; manual entries (not auto-generated) to keep them concise and meaningful.
