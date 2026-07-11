"""hrv_core — platform-agnostic reference implementation of the passive HRV core.

Pure standard-library Python that mirrors the Swift architecture 1:1 (see
docs/HRV_Architecture_Deep_Dive.md). This package is the executable spec the
native Swift port must reproduce numerically; the unit tests are the oracle.

Layers:
  * signal      — HRV metrics + artifact rejection (Deep Dive part A)
  * detection   — rolling baseline + robust-z anomaly state machine (part B)
  * persistence — logical repository over the C.6 schema (part C)
"""
