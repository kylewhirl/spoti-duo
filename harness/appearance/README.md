> Historical initial bridge fixture. Its restart-prompt expectations predate the live appearance implementation and are not the current acceptance suite. Use `harness/search-connection` for the consolidated live appearance regression and `harness/queue-confirmation` for queue presentation. Retained here as historical test material; do not treat its old expected behavior as a product requirement.

# Appearance regression fixture

This simulator-only app compiles the production appearance bridge, native Swift adapter, settings picker, AMOLED hook, tokens, glass and artwork field. An independent Objective-C wrapper mock and real pure-Swift class expose the two separate stores Spotify actually uses. This replaces the incomplete original wrapper-only mock.

    THEOS=$HOME/theos sh harness/appearance/build.sh
    sh harness/appearance/run.sh <SIMULATOR_UDID>

The runner checks Dark, Light, System in both simulator appearances, unset preference in both appearances, invalid preference, nil wrapper, rejected wrapper/native writes, and the production selector in both modes. It verifies transaction rollback, later native and wrapper drift detection, 1,000 repeated native-reference ownership transfers per valid mode, persistence, restart-sheet presentation after navigation, stable glass, contrast, artwork preservation and 50 resizes. It restores the simulator's original appearance on exit. Logs and screenshots are written to build/.

The fixture does not load Spotify and is not proof that every signed-in screen uses its main theme. That still needs the scoped device test after implementation.

Never pass or use a physical device for this harness. No device tooling is called.
