// lib/core/constants/firestore_paths.dart (UPDATED)
class FirestorePaths {
  static const services = 'services';

  static String service(String id) => '$services/$id';
  static String entries(String serviceId) => '$services/$serviceId/entries';
  static String entry(String serviceId, String entryId) =>
      '$services/$serviceId/entries/$entryId';
}

// lib/core/constants/app_strings.dart (UPDATED - Add Sprint 2 strings)
class AppStrings {
  // Sprint 1 strings (keep all existing)
  static const appName = 'QueueLens';
  static const services = 'Services';
  static const serviceDetails = 'Service Details';
  static const open = 'OPEN';
  static const closed = 'CLOSED';
  static const searchServices = 'Search services...';
  static const showOpenOnly = 'Show open only';
  static const noServices = 'No services available';
  static const errorLoading = 'Error loading services';
  static const retry = 'Retry';
  static const activeInQueue = 'Active in Queue';
  static const pendingInQueue = 'Pending';
  static const estimatedWait = 'Estimated Wait';
  static const minutes = 'min';
  static const lastUpdated = 'Last updated';
  static const description = 'Description';
  static const avgServiceTime = 'Avg. Service Time';
  static const perPerson = 'per person';

  // Sprint 2 - Queue Management
  static const scanQR = 'Scan QR Code';
  static const myQueue = 'My Queue';
  static const joinQueue = 'Join Queue';
  static const leaveQueue = 'Leave Queue';
  static const checkIn = 'I\'m Here!';
  static const confirmLeave = 'Confirm Leave';
  static const areYouSure = 'Are you sure you want to leave the queue?';
  static const cancel = 'Cancel';
  static const leave = 'Leave';
  static const position = 'Position';
  static const yourPosition = 'Your Position';
  static const waitingFor = 'Waiting for';
  static const checkInRequired = 'Check-in Required';
  static const checkInBy = 'Check in by';
  static const joinedSuccessfully = 'Joined queue successfully!';
  static const leftSuccessfully = 'Left queue successfully';
  static const alreadyInQueue = 'Already in Queue';
  static const alreadyInThisQueue = 'You are already in this queue';
  static const alreadyInOtherQueue = 'You are already in another queue';
  static const invalidQR = 'Invalid QR Code';
  static const qrExpired = 'QR code has expired';
  static const serviceClosed = 'Service is currently closed';
  static const scanToJoin = 'Scan QR code to join queue';
  static const noActiveQueue = 'No Active Queue';
  static const youAreNotInQueue = 'You are not in any queue';
  static const pending = 'PENDING';
  static const active = 'ACTIVE';
  static const expired = 'EXPIRED';
  static const left = 'LEFT';
  static const served = 'SERVED';
  static const checkInNow = 'Check in now to secure your spot!';
  static const checkedIn = 'Checked In';
  static const timeRemaining = 'Time remaining';
  static const or = 'or';
}
