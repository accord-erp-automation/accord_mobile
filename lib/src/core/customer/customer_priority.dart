const String secondaryCustomerName = 'saidamin';

bool isSecondaryCustomerName(String value) {
  return value.trim().toLowerCase() == secondaryCustomerName;
}

int compareCustomerNamesForDefault(String left, String right) {
  final leftSecondary = isSecondaryCustomerName(left);
  final rightSecondary = isSecondaryCustomerName(right);
  if (leftSecondary != rightSecondary) {
    return leftSecondary ? 1 : -1;
  }
  return left.trim().toLowerCase().compareTo(right.trim().toLowerCase());
}

T? preferPrimaryCustomer<T>(
  Iterable<T> items, {
  required String Function(T item) customerName,
}) {
  T? first;
  for (final item in items) {
    first ??= item;
    if (!isSecondaryCustomerName(customerName(item))) {
      return item;
    }
  }
  return first;
}
