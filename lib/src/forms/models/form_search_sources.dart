import 'option_item.dart';

/// Search function behind a `"searchSource"` name: returns the options that
/// match [query]. [formData] holds the current form values, so a source can
/// depend on other fields (cities of the selected state).
///
/// Throwing shows a "Could not load results" message with a Retry button.
typedef SearchOptionsFn =
    Future<List<OptionItem>> Function(
      String query,
      Map<String, dynamic> formData,
    );

/// Named search-as-you-type sources for searchable dropdowns.
///
/// Register a source once (for example in `main`), then reference it from
/// JSON with `"searchSource": "<name>"`:
///
/// ```dart
/// FormSearchSources.register('users', (query, formData) async {
///   final res = await dio.get('/users', queryParameters: {'q': query});
///   return [
///     for (final u in res.data as List)
///       OptionItem(label: u['name'] as String, value: u['id']),
///   ];
/// });
/// ```
///
/// A source can also be passed to one form only through
/// `DynamicFormController(searchSources: {...})`, which wins over this
/// registry.
class FormSearchSources {
  const FormSearchSources._();

  static final Map<String, SearchOptionsFn> _sources = {};

  /// Registers (or replaces) the source called [name].
  static void register(String name, SearchOptionsFn search) =>
      _sources[name] = search;

  /// Removes the source called [name].
  static void unregister(String name) => _sources.remove(name);

  /// The source called [name], or null.
  static SearchOptionsFn? lookup(String name) => _sources[name];

  /// Names of every registered source.
  static Iterable<String> get names => _sources.keys;
}
