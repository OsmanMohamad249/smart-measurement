/// Defines the possible states of the user's pose and environment during calibration.
enum CalibrationPoseState {
  /// All conditions are optimal.
  ideal,

  /// The reference card cannot be detected in the frame.
  cardNotDetected,

  /// The reference card is detected but is held at too sharp of an angle.
  cardTilted,

  /// The user is too close to the camera for an accurate reading.
  tooClose,

  /// The user is too far from the camera for an accurate reading.
  tooFar,

  /// The device is moving too much, affecting stability.
  deviceMoving,

  /// The lighting is insufficient for reliable detection.
  poorLighting,
}

