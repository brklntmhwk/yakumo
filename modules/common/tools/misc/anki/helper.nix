# Based on:
# https://github.com/nix-community/home-manager/blob/c6fe2944ad9f2444b2d767c4a5edee7c166e8a95/modules/programs/anki/helper.nix
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.yakumo.tools.misc.anki;
in
{
  # This script bootstraps the Anki SQLite DB with a user-configured Anki settings
  # and sync profiles by leveraging the Anki Python API.
  bootstrapperScript = pkgs.writeText "anki-bootstrapper.py" ''
    import sys
    import json
    import os
    import traceback

    from typing import Any

    from aqt.profiles import ProfileManager, VideoDriver
    from aqt.theme import Theme, WidgetStyle
    from aqt.toolbar import HideMode
    from anki.collection import Collection

    def main():
        if len(sys.argv) < 3:
            print("Usage: anki-bootstrapper.py <anki_base_folder> <config_json_path>")
            sys.exit(1)

        base_folder: str = sys.argv[1]
        config_file: str = sys.argv[2]

        # Load Nix-generated JSON configuration.
        with open(config_file, 'r') as f:
            nix_cfg: dict[str, Any] = json.load(f)

        # Init Anki's profile manager.
        pm: ProfileManager = ProfileManager(base_folder)
        pm.setupMeta()

        lang_str: str | None = nix_cfg.get("language")
        if lang_str is not None:
            pm.setLang(lang_str)

        style_str: str | None = nix_cfg.get("style")
        if style_str is not None:
            style: WidgetStyle = {
              "anki": WidgetStyle.ANKI,
              "native": WidgetStyle.NATIVE
            }[style_str]
            theme_manager.apply_style = lambda: None
            pm.set_widget_style(style)

        theme_str: str | None = nix_cfg.get("theme")
        if theme_str is not None:
            theme: Theme = {
                "system": Theme.FOLLOW_SYSTEM,
                "light": Theme.LIGHT,
                "dark": Theme.DARK
            }[theme_str]
            pm.set_theme(theme)

        ui_scale: float | None = nix_cfg.get("uiScale")
        if ui_scale is not None:
            pm.setUiScale(ui_scale)

        # https://github.com/ankitects/anki/blob/2d44d4d6bc486803f9236033ad840df203c87036/qt/aqt/profiles.py
        video_driver_str: str | None = nix_cfg.get("videoDriver")
        if video_driver_str is not None:
            driver_map: dict[str, VideoDriver] = {
                "angle": VideoDriver.ANGLE,
                "auto": VideoDriver.Auto,
                "d3d11": VideoDriver.Direct3D,
                "metal": VideoDriver.Metal,
                "opengl": VideoDriver.OpenGL,
                "vulkan": VideoDriver.Vulkan,
                "software": VideoDriver.Software,
            }
            if video_driver_str in driver_map:
                pm.set_video_driver(driver_map[video_driver_str])

        minimalist_mode: bool | None = nix_cfg.get("minimalistMode")
        if minimalist_mode is not None:
            pm.set_minimalist_mode(minimalist_mode)

        reduce_motion: bool | None = nix_cfg.get("reduceMotion")
        if reduce_motion is not None:
            pm.set_reduce_motion(reduce_motion)

        legacy_import_export: bool | None = nix_cfg.get("legacyImportExport")
        if legacy_import_export is not None:
            pm.set_legacy_import_export(legacy_import_export)

        spacebar_rates_card: bool | None = nix_cfg.get("spacebarRatesCard")
        if spacebar_rates_card is not None:
            pm.set_spacebar_rates_card(spacebar_rates_card)

        hide_top_bar: bool | None = nix_cfg.get("hideTopBar")
        if hide_top_bar is not None:
            pm.set_hide_top_bar(hide_top_bar)

        hide_bottom_bar: bool | None = nix_cfg.get("hideBottomBar")
        if hide_bottom_bar is not None:
            pm.set_hide_bottom_bar(hide_bottom_bar)

        def get_hide_mode(mode_str) -> HideMode:
            return HideMode.FULLSCREEN if mode_str == "fullscreen" else HideMode.ALWAYS

        hide_top_bar_mode_str: str | None = nix_cfg.get("hideTopBarMode")
        if hide_top_bar_mode_str is not None:
            pm.set_top_bar_hide_mode(get_hide_mode(hide_top_bar_mode_str))

        hide_bottom_bar_mode_str: str | None = nix_cfg.get("hideBottomBarMode")
        if hide_bottom_bar_mode_str is not None:
            pm.set_bottom_bar_hide_mode(get_hide_mode(hide_bottom_bar_mode_str))

        answer_keys_list: list[dict[str, Any]] | None = nix_cfg.get("answerKeys")
        if answer_keys_list:
            answer_keys_dict: dict[int, str] = { item["ease"]: item["key"] for item in answer_keys_list }
            for ease, key in answer_keys_dict.items():
                pm.set_answer_key(ease, key)

        # Declaratively add profiles and setup sync keys.
        profiles: dict[str, Any] = nix_cfg.get("profiles", {})

        for prof_name, prof_cfg in profiles.items():
            if prof_name not in pm.profiles():
                pm.create(prof_name)

            pm.openProfile(prof_name)

            # Without this, the collection DB won't get automatically optimized.
            pm.profile["lastOptimize"] = None

            sync_cfg: dict[str, Any] = prof_cfg.get("sync", {})

            auto_sync: bool | None = sync_cfg.get("autoSync")
            if auto_sync is not None:
                pm.profile["autoSync"] = auto_sync

            sync_media: bool | None = sync_cfg.get("syncMedia")
            if sync_media is not None:
                pm.profile["syncMedia"] = sync_media

            media_sync_minutes: int | None = sync_cfg.get("autoSyncMediaMinutes")
            if media_sync_minutes is not None:
                pm.set_periodic_sync_media_minutes(media_sync_minutes)

            network_timeout: int | None  = sync_cfg.get("networkTimeout")
            if network_timeout is not None:
                pm.set_network_timeout(network_timeout)

            # Set as default profile if configured.
            default_profile: bool | None = prof_cfg.get("default")
            if default_profile:
                pm.set_last_loaded_profile_name(prof_name)

            custom_sync_url: str | None = sync_cfg.get("url")
            if custom_sync_url is not None:
                pm.set_custom_sync_url(custom_sync_url)

            username: str | None = sync_cfg.get("username")
            pw_file: str | None = sync_cfg.get("passwordFile")

            # Execute sync login only if credentials exist and no syncKey is present.
            if username and pw_file and not pm.profile.get("syncKey"):
                if os.path.exists(pw_file):
                    with open(pw_file, 'r') as pf:
                        password = pf.read().strip()

                    if password:
                        try:
                            col_path: str = pm.collectionPath()
                            col: Collection = Collection(col_path)

                            endpoint: str = custom_sync_url if custom_sync_url else pm.sync_endpoint()
                            # https://github.com/ankitects/anki/blob/2d44d4d6bc486803f9236033ad840df203c87036/pylib/anki/collection.py
                            auth = col.sync_login(
                                username=username,
                                password=password,
                                endpoint=endpoint
                            )

                            pm.set_sync_key(auth.hkey)
                            pm.set_sync_username(username)

                            col.close()
                            print(f"[Anki Bootstrapper] Sync key setup successful for {prof_name}.")
                        except Exception as e:
                            print(f"[Anki Bootstrapper] Sync login failed: {e}", file=sys.stderr)
                            traceback.print_exc()
                else:
                    print(f"[Anki Bootstrapper] Warning: Password file not found at {pw_file}", file=sys.stderr)

        # Persist all changes to prefs21.db.
        pm.save()

    if __name__ == "__main__":
        main()
  '';
}
