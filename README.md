# Omarchy Music Card

A compact now-playing widget and a dark, translucent album-art card for Omarchy 4. The plugin uses Quickshell’s MPRIS service directly, so it works with media players that publish MPRIS metadata, including browsers and PWAs.

## Features

- Compact title and artist in the top bar.
- Open the card by hovering over the widget or clicking it.
- A narrow, rounded player card with centered album art and track details.
- Album art, title, artist, album, and a player or service label inferred from MPRIS metadata.
- A waveform-style progress bar tied to the real playback position, with click-to-seek when the player supports seeking.
- Previous, play/pause, and next controls.
- Shuffle and repeat controls are enabled only when the player reports support.
- YouTube Music receives a red accent; other players use the active Omarchy theme accent.
- Album art is sized for the display density. Google-hosted artwork URLs are requested at higher resolution when supported, with the original URL as a fallback.
- No playerctl dependency or background network service.

The waveform is a visual motif rather than a sampled audio waveform. MPRIS exposes the track position, but not the audio samples.

## Requirements

- Omarchy 4.0.4 or newer with its Quickshell shell.
- A media player that exports MPRIS over D-Bus.

For browser players, the card checks the current track URLs, artwork URL, and available album metadata to distinguish YouTube Music from YouTube. Browser MPRIS metadata varies: if it does not include enough information to identify the site, the card falls back to the player identity reported by MPRIS.

## Install from GitHub

After publishing this repository, install it with:

    omarchy plugin add https://github.com/natori-hrj/omarchy-music-card.git --enable

The widget defaults to the center section. If the built-in Omarchy media widget is already on your bar, disable it to avoid showing both:

    omarchy plugin disable omarchy.media

## Local development

This checkout is installed locally as a symlink at:

    ~/.config/omarchy/plugins/natori.music-card

The Omarchy shell configuration includes the widget in the same center slot where the built-in media widget was. To reproduce that setup on another machine:

    mkdir -p ~/.config/omarchy/plugins
    ln -s ~/repos/omarchy-music-card ~/.config/omarchy/plugins/natori.music-card
    omarchy plugin enable natori.music-card --section center

Validate the manifest and ask the running shell to rescan plugins:

    omarchy plugin validate ~/repos/omarchy-music-card
    omarchy-shell shell rescanPlugins

## Remove

Remove the local installation with:

    omarchy plugin remove natori.music-card

The command removes the plugin symlink and leaves the repository in ~/repos. To restore the built-in widget:

    omarchy plugin enable omarchy.media --section center

## License

MIT. See LICENSE.
