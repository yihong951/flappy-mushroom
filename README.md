# Flappy Mushroom 🍄

**Play:** https://yihong951.github.io/flappy-mushroom/

Hop a little toadstool through a moonlit forest and climb the daily rankings.

Flappy Mushroom is a one-tap arcade game. Guide a cheerful toadstool through gaps in fallen logs, and see how far you can go before you bonk.

Glowing power caps float through the forest. Grab one for 5 seconds of:

- 🟣 **Giant**: grow big and smash straight through logs
- 🔵 **Zoom**: speed up and earn double points
- 🟡 **Glow**: become invincible

Your score saves automatically to the **daily, monthly and yearly rankings**. Pick a nickname on the rankings screen and earn medals: Button, Chanterelle, Morel and Truffle.

**Controls:** tap the screen, press Space or press ↑ to hop. Plays in any phone or desktop browser, with no download.

## Files

| File | What it is |
| --- | --- |
| `index.html` | The whole game. It needs no build step. |
| `supabase/schema.sql` | Database setup for the rankings |
| `build-itch.ps1` | Builds the itch.io zip |
| `cover.png`, `og-image.png`, `icons/` | Cover art, share preview and app icons |
| `tools/` | Scripts that regenerate the images |

## Updating the game

Push to `main`. GitHub Pages serves the repo root, and the live site updates in about a minute.

## Rankings (Supabase)

Rankings use Supabase project `ttynjpmhqvgoykwpxfdn`. Its URL and public anon key are in `index.html`. The anon key is meant to be public.

- Keep **Allow anonymous sign-ins** turned on (Authentication > Sign In / Providers). Every player is signed in anonymously in the background, and scores can't save without it.
- Boards reset at midnight UTC (daily), on the 1st of the month (monthly) and on 1 January (yearly). Each board shows every player's best run in that period.
- Players can only add their own scores and rename themselves. Scores are capped at 9999, with at most one every 3 seconds per player.
- To remove a fake score, delete the row in **Table Editor > scores**. To remove a player and all their scores, delete them in **Table Editor > players**.

To use a new Supabase project:

1. Turn on anonymous sign-ins.
2. Run all of `supabase/schema.sql` in **SQL Editor**.
3. Put the new Project URL and anon key into `index.html`.

## Publishing on itch.io

1. Run `./build-itch.ps1`. It creates `dist/flappy-mushroom-itch.zip`.
2. Create a new itch.io project. Set **Kind of project** to **HTML**, upload the zip and tick **This file will be played in the browser**.
3. Set the embed size to **360 × 640**, and tick **Mobile friendly** (portrait), **Fullscreen button** and **Automatically start on page load**.
4. Upload `cover.png` as the cover image.
