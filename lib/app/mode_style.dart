import 'package:flutter/material.dart';

import '../models/app_state.dart';
import 'theme.dart';

/// Mode accents — matches `output/mockups/generate_ui_mockups.py` (Ocean / Jade / Terracotta).
Color kuglaModeColor(GameMode mode) => switch (mode) {
      GameMode.dailyPulse => KuglaColors.pulse,
      GameMode.worldAtlas => KuglaColors.atlas,
      GameMode.landmarkLock => KuglaColors.landmark,
    };
