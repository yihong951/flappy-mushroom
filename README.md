# Flappy Mushroom

A Flappy Bird–style browser game for phones and desktops. Hop a toadstool through a night forest, absorb power caps (Giant, Zoom, Glow) and climb the daily, monthly and yearly rankings.

- Tap, Space or ↑ to hop.
- Everything is in `index.html`. It needs no build step.
- Rankings use [Supabase](https://supabase.com). Players are signed in anonymously in the background, scores save automatically after every run, and players can rename themselves on the rankings screen.

## 1. Turn on rankings (Supabase, free tier)

1. Create a project at supabase.com.
2. Go to **Authentication > Sign In / Providers** and turn on **Allow anonymous sign-ins**.
3. Go to **SQL Editor > New query**, paste the contents of `supabase/schema.sql` and click **Run**.
4. Go to **Project Settings > API** and copy the **Project URL** and the **anon public** key.
5. In `index.html`, replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with those values.

The anon key is meant to be public. The row level security rules in `schema.sql` let anyone read the rankings while each player can only add their own scores and rename themselves.

Rankings reset at midnight UTC (daily), on the 1st of each month (monthly) and on 1 January (yearly). Each board shows every player's best run in that period.

Limitation: scores are sent by the player's browser, so a determined cheater could post a fake score. The database caps scores at 9999 and allows one score every 3 seconds per player. To remove a fake entry, delete its row in Supabase under **Table Editor > scores**.

## 2. Publish on GitHub Pages

The site is served straight from the `main` branch root, so every push to `main` updates the live game at
`https://<username>.github.io/flappy-mushroom/`.

## 3. Publish on itch.io

1. Run `./build-itch.ps1`. It creates `dist/flappy-mushroom-itch.zip`.
2. On itch.io, choose **Upload new project**. Set **Kind of project** to **HTML** and upload the zip.
3. Tick **This file will be played in the browser**.
4. Under embed options, set the viewport to **360 × 640**, and tick **Mobile friendly** (orientation: portrait), **Fullscreen button** and **Automatically start on page load**.
