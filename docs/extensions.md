# Extensions

`services_rj` adds extension members to `String`, `String?`, `double`, `double?`, `num` and `BuildContext`. They are available after:

```dart
import 'package:services_rj/services_rj.dart';
```

A test (`test/extensions_doc_test.dart`) fails when a public extension member is missing from this page, so add a row here whenever you add one.

**Name clashes.** If another package (for example GetX or flutter_screenutil) defines a member with the same name and both are imported in one file, Dart reports an ambiguous member. Hide one of the extensions in that file:

```dart
import 'package:services_rj/services_rj.dart' hide AppStringExtensions;
```

---

## String: `AppStringExtensions`

Lengths and positions count user-visible characters, so emoji and scripts such as Hindi are never split in the middle.

### Checks

| Member | Result | Example |
|---|---|---|
| `isBlank` | Empty or only whitespace | `'  '.isBlank` → `true` |
| `isNotBlank` | At least one non-whitespace character | `' a '.isNotBlank` → `true` |
| `isEmail` | `name@domain.tld` (surrounding spaces ignored) | `'a@b.com'.isEmail` → `true` |
| `isPhone` | 7–15 digits, optional leading `+`; spaces, dashes, dots and brackets ignored | `'+91 98765-43210'.isPhone` → `true` |
| `isUrl` | Absolute `http` / `https` URL with a host | `'example.com'.isUrl` → `false` |
| `isNumeric` | Parses as a number | `'-3.5'.isNumeric` → `true` |
| `isAlphabetic` | Only letters in any script, including vowel signs and accents | `'नमस्ते'.isAlphabetic` → `true` |
| `isAlphanumeric` | Only letters and digits | `'Asha1'.isAlphanumeric` → `true` |
| `equalsIgnoreCase(other)` | Same text ignoring case | `'ABC'.equalsIgnoreCase('abc')` → `true` |

### Conversions

| Member | Result | Example |
|---|---|---|
| `toIntOrNull()` | `int` or null | `' 42 '.toIntOrNull()` → `42` |
| `toDoubleOrNull()` | `double` or null | `'abc'.toDoubleOrNull()` → `null` |
| `toBool()` | `true` for `true`, `yes`, `y`, `on`, `1` (any case) | `'Yes'.toBool()` → `true` |

### Case

| Member | Result | Example |
|---|---|---|
| `capitalize()` | First character upper case, rest unchanged | `'hello world'` → `'Hello world'` |
| `toTitleCase()` | Each word capitalized, rest lower case, spacing kept | `'hello WORLD'` → `'Hello World'` |
| `toCamelCase()` | From spaces, `_`, `-`, `.` or PascalCase | `'user_name'` → `'userName'` |
| `toSnakeCase()` | | `'userName'` → `'user_name'` |
| `toKebabCase()` | | `'userName'` → `'user-name'` |

### Editing

| Member | Result | Example |
|---|---|---|
| `removeWhitespace()` | All whitespace removed | `' a b '` → `'ab'` |
| `collapseWhitespace()` | Runs of whitespace become one space, ends trimmed | `'  a   b '` → `'a b'` |
| `onlyDigits()` | Digits only | `'+91 98765-43210'` → `'919876543210'` |
| `reverse()` | Characters in reverse order | `'abc'` → `'cba'` |
| `truncate(maxLength, {ellipsis = '…'})` | At most `maxLength` characters including the ellipsis | `'Hello world'.truncate(8)` → `'Hello w…'` |
| `mask({visibleStart = 0, visibleEnd = 4, char = '•'})` | Hides the middle; unchanged when too short | `'9876543210'.mask()` → `'••••••3210'` |
| `initials` | First letters of the first and last word, upper case | `'Ranjit Kumar Makwana'.initials` → `'RM'` |

## Nullable String: `AppNullableStringExtensions`

| Member | Result | Example |
|---|---|---|
| `isNullOrEmpty` | Null or `''` | `null.isNullOrEmpty` → `true` |
| `isNullOrBlank` | Null, empty or only whitespace | `' '.isNullOrBlank` → `true` |
| `orEmpty` | The text, or `''` when null | `name.orEmpty` |
| `or(fallback)` | The text, or `fallback` when null, empty or blank | `name.or('Guest')` |

---

## double: `AppDoubleExtensions`

| Member | Result | Example |
|---|---|---|
| `roundTo(places)` | Rounded `double` | `3.14159.roundTo(2)` → `3.14` |
| `isWhole` | No fractional part | `3.0.isWhole` → `true` |
| `toCleanString({maxDecimals = 2})` | Up to `maxDecimals` decimals, trailing zeros removed | `2.50` → `'2.5'`, `3.0` → `'3'` |

## Nullable double: `AppNullableDoubleExtensions`

| Member | Result | Example |
|---|---|---|
| `orZero` | The value, or `0.0` when null | `price.orZero` |

## Numbers (double and int): `AppNumExtensions`

Written on `num`, so they work on `double` values and on `int` literals: `1250.5.toCompact()` and `16.heightBox` both work.

### Formatting

| Member | Result | Example |
|---|---|---|
| `withSeparators({decimals = 0, separator = ',', indian = false})` | Thousands separators; `indian` groups as lakh / crore | `1234567.891.withSeparators(decimals: 2)` → `'1,234,567.89'`; with `indian: true` → `'12,34,567.89'` |
| `toCurrency(symbol, {decimals = 2, separator = ',', indian = false})` | Symbol, separators and decimals; the minus sign goes before the symbol | `1499.5.toCurrency('₹')` → `'₹1,499.50'`; `(-20).toCurrency(r'$')` → `'-$20.00'` |
| `toCompact({decimals = 1, indian = false})` | `K`, `M`, `B`, `T`; with `indian`: `K`, `L`, `Cr` | `1250.toCompact()` → `'1.3K'`; `150000.toCompact(indian: true)` → `'1.5L'` |
| `toPercent({decimals = 0})` | A fraction as a percentage | `0.256.toPercent()` → `'26%'` |

Write negative literals in brackets, `(-20).toCurrency(...)`: Dart reads `-20.toCurrency(...)` as `-(20.toCurrency(...))`.

### Ranges

| Member | Result | Example |
|---|---|---|
| `isBetween(min, max)` | `min ≤ value ≤ max` | `5.isBetween(1, 5)` → `true` |

### Layout

| Member | Result |
|---|---|
| `heightBox` | `SizedBox(height: value)` |
| `widthBox` | `SizedBox(width: value)` |
| `allInsets` | `EdgeInsets.all(value)` |
| `horizontalInsets` | `EdgeInsets.symmetric(horizontal: value)` |
| `verticalInsets` | `EdgeInsets.symmetric(vertical: value)` |
| `borderRadius` | `BorderRadius.circular(value)` |

```dart
Column(
  children: [
    Text(price.toCurrency('₹')),
    8.heightBox,
    Text('${views.toCompact()} views'),
  ],
);
Container(
  padding: 16.allInsets,
  decoration: BoxDecoration(borderRadius: 12.borderRadius),
);
```

---

## BuildContext: `AppContextExtensions`

| Member | Result |
|---|---|
| `theme` | `Theme.of(context)` |
| `colors` | `Theme.of(context).colorScheme` |
| `textTheme` | `Theme.of(context).textTheme` |
| `isDarkMode` | Current theme brightness is dark |
| `screenSize` | `MediaQuery.of(context).size` |
| `screenWidth` | Screen width |
| `screenHeight` | Screen height |
