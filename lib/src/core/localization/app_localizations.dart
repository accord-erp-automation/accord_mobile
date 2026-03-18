import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('uz'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isUzbek => locale.languageCode == 'uz';

  String get appTitle => isUzbek ? 'Accord' : 'Accord';
  String get profileTitle => isUzbek ? 'Profil' : 'Profile';
  String get werkaAccount => isUzbek ? 'Werka akkaunti' : 'Werka account';
  String get supplierAccount =>
      isUzbek ? 'Supplier akkaunti' : 'Supplier account';
  String get customerAccount =>
      isUzbek ? 'Customer akkaunti' : 'Customer account';
  String get adminAccount => isUzbek ? 'Admin akkaunti' : 'Admin account';
  String get nicknameSaveFailed =>
      isUzbek ? 'Nickname saqlanmadi' : 'Nickname was not saved';
  String get imagePickFailed =>
      isUzbek ? 'Rasm tanlanmadi' : 'Image selection failed';
  String get imageSaveFailed =>
      isUzbek ? 'Rasm saqlanmadi' : 'Image was not saved';
  String get save => isUzbek ? 'Saqlash' : 'Save';
  String get saveChanges => isUzbek ? 'O‘zgarishlarni saqlash' : 'Save changes';
  String get phoneLabel => isUzbek ? 'Telefon' : 'Phone';
  String get legalNameLabel => isUzbek ? 'Asl ism' : 'Legal name';
  String get nicknameLabel => isUzbek ? 'Nickname' : 'Nickname';
  String get nicknameHint =>
      isUzbek ? 'O‘zingizga ko‘rinadigan ism' : 'The name visible to you';
  String get securityTitle => isUzbek ? 'Xavfsizlik' : 'Security';
  String get pinEnabled =>
      isUzbek ? '4 xonali PIN yoqilgan' : 'A 4-digit PIN is enabled';
  String get pinDisabled => isUzbek
      ? 'App uchun 4 xonali PIN o‘rnating'
      : 'Set a 4-digit PIN for the app';
  String get pinSaving => isUzbek ? 'Saqlanmoqda...' : 'Saving...';
  String get pinSet => isUzbek ? 'PIN o‘rnatish' : 'Set PIN';
  String get pinChange => isUzbek ? 'PIN almashtirish' : 'Change PIN';
  String get pinRemove => isUzbek ? 'PIN o‘chirish' : 'Remove PIN';
  String get biometricEnableTitle => isUzbek
      ? 'Biometrik autentifikatsiyani yoqish'
      : 'Enable biometric authentication';
  String get biometricEnabledBody => isUzbek
      ? 'Yoqilgan. App Face ID yoki fingerprint bilan tez ochiladi.'
      : 'Enabled. The app can be unlocked quickly with Face ID or fingerprint.';
  String get biometricDisabledBody => isUzbek
      ? 'O‘chirilgan. Face ID yoki fingerprint bilan tez ochish ishlamaydi.'
      : 'Disabled. Fast unlock with Face ID or fingerprint is off.';
  String get languageTitle => isUzbek ? 'Til' : 'Language';
  String get languageBody =>
      isUzbek ? 'Ilova tilini tanlang' : 'Choose the app language';
  String get uzbek => isUzbek ? 'O‘zbekcha' : 'Uzbek';
  String get english => 'English';
  String get selectedImageNotice => isUzbek
      ? 'Yangi rasm tanlandi. Saqlashni bossangiz profil yangilanadi.'
      : 'A new image was selected. Save to update the profile.';
  String get appLockTitle => isUzbek ? 'App qulfi' : 'App lock';
  String get appLockSubtitle =>
      isUzbek ? '4 xonali PIN kiriting' : 'Enter your 4-digit PIN';
  String get unlock => isUzbek ? 'Ochish' : 'Unlock';
  String get checking => isUzbek ? 'Tekshirilmoqda...' : 'Checking...';
  String get biometricCta =>
      isUzbek ? 'Biometrik autentifikatsiya' : 'Biometric authentication';
  String get pinWrong => isUzbek ? 'PIN noto‘g‘ri' : 'Incorrect PIN';
  String get biometricFailed => isUzbek
      ? 'Biometrik tasdiq bajarilmadi'
      : 'Biometric verification did not complete';

  String get clearTitle => isUzbek ? 'Tozalash' : 'Clear';
  String get yes => isUzbek ? 'Ha' : 'Yes';
  String get no => isUzbek ? 'Yo‘q' : 'No';
  String get retry => isUzbek ? 'Qayta urinish' : 'Retry';
  String get loading => isUzbek ? 'Yuklanmoqda...' : 'Loading...';
  String get confirmTitle => isUzbek ? 'Tasdiqlash' : 'Confirm';
  String get qtyRequired => isUzbek ? 'Miqdor kiriting' : 'Enter quantity';
  String get amountLabel => isUzbek ? 'Miqdor' : 'Quantity';
  String get customerLabel => isUzbek ? 'Customer' : 'Customer';
  String get supplierLabel => isUzbek ? 'Supplier' : 'Supplier';
  String get itemLabel => isUzbek ? 'Mol' : 'Item';
  String get selectCustomer => isUzbek ? 'Customer tanlang' : 'Select customer';
  String get searchCustomer =>
      isUzbek ? 'Customer qidiring' : 'Search customer';
  String get selectSupplier => isUzbek ? 'Supplier tanlang' : 'Select supplier';
  String get searchSupplier =>
      isUzbek ? 'Supplier qidiring' : 'Search supplier';
  String get selectItem => isUzbek ? 'Mol tanlang' : 'Select item';
  String get searchItem => isUzbek ? 'Mol qidiring' : 'Search item';
  String get createHubTitle => isUzbek ? 'Qayd' : 'Create';
  String get unannouncedTitle =>
      isUzbek ? 'Aytilmagan mol' : 'Unannounced item';
  String get customerIssueTitle => isUzbek ? 'Mol jo‘natish' : 'Send item';
  String get unannouncedDescription => isUzbek
      ? 'Supplier, mol va miqdorni bir oqimda tanlang'
      : 'Choose supplier, item, and quantity in one flow';
  String get customerIssueDescription => isUzbek
      ? 'Customerga jo‘natma yaratish oqimi'
      : 'Flow for creating a shipment to a customer';
  String get notificationsTitle =>
      isUzbek ? 'Bildirishnomalar' : 'Notifications';
  String get noNotifications =>
      isUzbek ? 'Hali bildirishnomalar yo‘q.' : 'No notifications yet.';
  String get clearAllNotificationsPrompt => isUzbek
      ? 'Hamma bildirishnomalarni tozalaysizmi?'
      : 'Clear all notifications?';
  String get notificationsLoadFailed =>
      isUzbek ? 'Bildirishnomalar yuklanmadi' : 'Failed to load notifications';
  String get recentTitle => isUzbek ? 'Recent' : 'Recent';
  String get recentSubtitle => isUzbek
      ? 'Avvalgi harakatni prefill bilan qayta ishlating'
      : 'Reuse previous actions with prefill';
  String get recentLoadFailed =>
      isUzbek ? 'Recent yuklanmadi' : 'Failed to load recent';
  String get noRecentActions => isUzbek
      ? 'Hali repeat qilish uchun recent harakat yo‘q.'
      : 'There are no recent actions to repeat yet.';
  String get repeatSendAgain => isUzbek ? 'Yana jo‘natish' : 'Send again';
  String get repeatCreateAgain => isUzbek ? 'Yana qayd qilish' : 'Create again';
  String get pendingStatus => isUzbek ? 'Jarayonda' : 'In progress';
  String get confirmedStatus => isUzbek ? 'Tasdiqlangan' : 'Confirmed';
  String get returnedStatus => isUzbek ? 'Qaytarilgan' : 'Returned';
  String get recordsLoadFailed =>
      isUzbek ? 'Yozuvlar yuklanmadi' : 'Failed to load records';
  String get noRecordsYet => isUzbek
      ? 'Bu ro‘yxatda hozircha yozuv yo‘q.'
      : 'No records in this list yet.';
  String get statusListLoadFailed =>
      isUzbek ? 'Status ro‘yxati yuklanmadi' : 'Failed to load status list';
  String get noStatusRecords => isUzbek
      ? 'Bu statusda hozircha yozuv yo‘q.'
      : 'No records in this status yet.';
  String get receiptsSuffix => isUzbek ? 'ta receipt' : 'receipts';
  String get sentToCustomer =>
      isUzbek ? 'customerga yuborilgan' : 'sent to customer';
  String get receivedFromSupplier =>
      isUzbek ? 'supplierdan qabul qilingan' : 'received from supplier';
  String get acceptedFromQtyPrefix => isUzbek ? 'Qabul' : 'Accepted';
  String get createFlowBack => isUzbek ? 'Qaydga qaytish' : 'Back to create';
  String get pendingListBack =>
      isUzbek ? 'Pending listga qaytish' : 'Back to pending list';
  String get sentSuccess => isUzbek ? 'Jo‘natildi' : 'Sent';
  String get createdSuccess => isUzbek ? 'Qayd qilindi' : 'Created';
  String get receivedSuccess => isUzbek ? 'Qabul qilindi' : 'Received';
  String get customerApproved =>
      isUzbek ? 'Customer tasdiqlagan' : 'Customer approved';
  String get customerRejected =>
      isUzbek ? 'Customer rad etgan' : 'Customer rejected';
  String get partiallyCompleted =>
      isUzbek ? 'Qisman yakunlangan' : 'Partially completed';
  String get cancelled => isUzbek ? 'Bekor qilingan' : 'Cancelled';
  String get waitingCustomerResponse =>
      isUzbek ? 'Customer javobi kutilmoqda' : 'Waiting for customer response';
  String get draft => isUzbek ? 'Draft' : 'Draft';
  String get noExtraNote =>
      isUzbek ? 'Qo‘shimcha izoh yo‘q.' : 'No additional note.';
  String get customerShipmentTitle =>
      isUzbek ? 'Customer jo‘natmasi' : 'Customer shipment';
  String get statusLabel => isUzbek ? 'Status' : 'Status';
  String get dateLabel => isUzbek ? 'Sana' : 'Date';
  String get detailsStateTitle => isUzbek ? 'Holat' : 'State';

  String statusWithName(String name, String status) => '$status • $name';
  String recordsLoadFailedWith(Object error) => '$recordsLoadFailed: $error';
  String statusListLoadFailedWith(Object error) =>
      '$statusListLoadFailed: $error';
  String notificationsLoadFailedWith(Object error) =>
      '$notificationsLoadFailed: $error';
  String recentLoadFailedWith(Object error) => '$recentLoadFailed: $error';
  String sentQtyStatus(num qty, String uom, String statusWord) =>
      '${qty.toStringAsFixed(0)} $uom $statusWord';
  String receiptCountLabel(int count) =>
      isUzbek ? '$count ta receipt' : '$count receipts';
  String customerFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $sentToCustomer';
  String supplierFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $receivedFromSupplier';
  String acceptedQtyLabel(num qty, String uom) =>
      '$acceptedFromQtyPrefix: ${qty.toStringAsFixed(0)} $uom';
  String customerShipmentPendingNote() => isUzbek
      ? 'Bu jo‘natma Werka tomonidan customerga yuborilgan. Qaytarish yoki tasdiqlash customer tomonidan qilinadi.'
      : 'This shipment was sent by Werka to the customer. Any rejection or approval must be done by the customer.';
  String sentToCustomerLine(num qty, String uom) => isUzbek
      ? '${qty.toStringAsFixed(2)} $uom customerga jo‘natildi'
      : '${qty.toStringAsFixed(2)} $uom sent to customer';
  String createdLine(num qty, String uom) => isUzbek
      ? '${qty.toStringAsFixed(2)} $uom qayd qilindi'
      : '${qty.toStringAsFixed(2)} $uom recorded';
  String receivedLine(num qty, String uom) => isUzbek
      ? '${qty.toStringAsFixed(2)} $uom qabul qilindi'
      : '${qty.toStringAsFixed(2)} $uom received';
  String customerIssueFailed(Object error) => isUzbek
      ? 'Mol jo‘natish bo‘lmadi: $error'
      : 'Sending item failed: $error';
  String unannouncedSuppliersFailed(Object error) => isUzbek
      ? 'Supplierlar yuklanmadi: $error'
      : 'Suppliers failed to load: $error';
  String customersLoadFailed(Object error) => isUzbek
      ? 'Customerlar yuklanmadi: $error'
      : 'Customers failed to load: $error';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (item) => item.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
