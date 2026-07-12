"""Real-data analysis — parse an Apple Health export and calibrate hrv_core on it.

Mac-independent: runs on Windows with only the watch export. Answers Track H's
Q-B (personal calibration of k/persistence/cooldown) and the passive-SDNN-density
part of Q-A. (Beat-to-beat RR series are not in the standard Health export, so
the full RRExtractor question still needs the on-device app.)
"""
