import 'dart:async';

import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/widgets/shell/app_loading_indicator.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/widgets/m3_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(M3AsyncPickerSheet.clearMemoryCache);

  testWidgets('async picker reuses cached first page for same cache key',
      (tester) async {
    var loadCalls = 0;

    await tester.pumpWidget(
      _wrap(
        M3AsyncPickerSheet<_PickerItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          cacheKey: 'werka:item-options',
          pageSize: 80,
          loadPage: (query, offset, limit) async {
            loadCalls++;
            return const [_PickerItem('Alo', 'WP-1')];
          },
          itemTitle: (item) => item.title,
          itemSubtitle: (item) => item.subtitle,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loadCalls, 1);
    expect(find.text('Alo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      _wrap(
        M3AsyncPickerSheet<_PickerItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          cacheKey: 'werka:item-options',
          pageSize: 80,
          loadPage: (query, offset, limit) async {
            loadCalls++;
            return const [_PickerItem('Server', 'WP-2')];
          },
          itemTitle: (item) => item.title,
          itemSubtitle: (item) => item.subtitle,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(loadCalls, 1);
    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(find.text('Alo'), findsOneWidget);
    expect(find.text('Server'), findsNothing);
  });

  testWidgets('stale async request cannot flash empty state during search',
      (tester) async {
    final firstPage = Completer<List<_PickerItem>>();
    final searchPage = Completer<List<_PickerItem>>();
    final queries = <String>[];

    await tester.pumpWidget(
      _wrap(
        M3AsyncPickerSheet<_PickerItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          pageSize: 80,
          loadPage: (query, offset, limit) {
            queries.add(query);
            return query.isEmpty ? firstPage.future : searchPage.future;
          },
          itemTitle: (item) => item.title,
          itemSubtitle: (item) => item.subtitle,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'olma');
    await tester.pump(const Duration(milliseconds: 240));
    expect(queries, ['', 'olma']);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    firstPage.complete(const <_PickerItem>[]);
    await tester.pump();

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('Hozircha yozuv yo‘q'), findsNothing);

    searchPage.complete(const [_PickerItem('Olma', 'WP-3')]);
    await tester.pumpAndSettle();

    expect(find.text('Olma'), findsOneWidget);
    expect(find.text('Hozircha yozuv yo‘q'), findsNothing);
  });

  testWidgets('async picker caches first page even when sheet is dismissed',
      (tester) async {
    final firstPage = Completer<List<_PickerItem>>();
    var loadCalls = 0;

    await tester.pumpWidget(
      _wrap(
        M3AsyncPickerSheet<_PickerItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          cacheKey: 'werka:dismissed-item-options',
          pageSize: 80,
          loadPage: (query, offset, limit) {
            loadCalls++;
            return firstPage.future;
          },
          itemTitle: (item) => item.title,
          itemSubtitle: (item) => item.subtitle,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(loadCalls, 1);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    firstPage.complete(const [_PickerItem('Cached after close', 'WP-4')]);
    await tester.pump();

    await tester.pumpWidget(
      _wrap(
        M3AsyncPickerSheet<_PickerItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          cacheKey: 'werka:dismissed-item-options',
          pageSize: 80,
          loadPage: (query, offset, limit) async {
            loadCalls++;
            return const [_PickerItem('Server again', 'WP-5')];
          },
          itemTitle: (item) => item.title,
          itemSubtitle: (item) => item.subtitle,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(loadCalls, 1);
    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(find.text('Cached after close'), findsOneWidget);
    expect(find.text('Server again'), findsNothing);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    locale: const Locale('uz'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _PickerItem {
  const _PickerItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
