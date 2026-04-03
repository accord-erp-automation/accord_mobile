import 'package:erpnext_stock_mobile/src/core/customer/customer_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compareCustomerNamesForDefault pushes Saidamin after other customers',
      () {
    expect(
      compareCustomerNamesForDefault('Saidamin', 'Aziz Market'),
      greaterThan(0),
    );
    expect(
      compareCustomerNamesForDefault('Aziz Market', 'Saidamin'),
      lessThan(0),
    );
  });

  test('preferPrimaryCustomer picks non-Saidamin when available', () {
    final picked = preferPrimaryCustomer(
      ['Saidamin', 'Dilnoza Shop', 'Aziz Market'],
      customerName: (item) => item,
    );

    expect(picked, 'Dilnoza Shop');
  });

  test('preferPrimaryCustomer falls back to Saidamin when it is the only one',
      () {
    final picked = preferPrimaryCustomer(
      ['Saidamin'],
      customerName: (item) => item,
    );

    expect(picked, 'Saidamin');
  });
}
