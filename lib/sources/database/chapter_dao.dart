import "dart:async";

import "package:app/database/database_wrapper.dart";
import "package:app/models/chapter.dart";
import "package:app/models/novel.dart";
import "package:app/sources/database/novel_dao.dart";
import "package:meta/meta.dart";

@immutable
class ChapterDao {
  const ChapterDao(this._database, this._novelDao);

  final DatabaseWrapper _database;

  final NovelDao _novelDao;

  Future<Chapter> get({String slug, Uri url}) async {
    slug ??= slugify(uri: url);

    final chapters = await _database.rawQuery(
      """SELECT
${_chapterColumnSelection()},
${_novelColumnSelection()}
FROM ${Chapter.type}
LEFT JOIN ${Novel.type} ON ${Novel.type}.slug=${Chapter.type}.novelSlug
  AND ${Novel.type}.source=${Chapter.type}.novelSource
WHERE ${Chapter.type}.slug = ?""",
      [slug],
    );

    return chapters.isNotEmpty ? _fromJoin(chapters.single) : null;
  }

  Future<List<Chapter>> list({
    @required String novelSource,
    @required String novelSlug,
    String orderBy,
    int limit,
    int offset,
  }) async {
    final where = <String, dynamic>{
      "novelSlug": novelSlug,
      "novelSource": novelSource,
    };

    final chapters = await _database.query(
      table: Chapter.type,
      where: where,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      columns: [_chapterColumnSelection()],
    );

    return chapters.map(_fromJoin).toList();
  }

  Future<int> count({String novelSlug}) async {
    return _database.count(
      table: Chapter.type,
      where: novelSlug != null ? {"novelSlug": novelSlug} : null,
    );
  }

  Future<List<Chapter>> recents({int limit = 20, int offset = 0}) async {
    final recents = await _database.rawQuery("""SELECT
${_chapterColumnSelection()},
${_novelColumnSelection()},
MAX(readAt)
FROM ${Chapter.type}
LEFT JOIN ${Novel.type} ON ${Novel.type}.slug=${Chapter.type}.novelSlug
  AND ${Novel.type}.source=${Chapter.type}.novelSource
WHERE readAt IS NOT NULL
GROUP BY novelSlug
ORDER BY readAt DESC
LIMIT $limit
OFFSET $offset""");

    return recents.map(_fromJoin).toList();
  }

  Future<bool> exists({String slug, Uri url}) async {
    slug ??= slugify(uri: url);

    final count = await _database.count(
      table: Chapter.type,
      where: {"slug": slug},
      limit: 1,
    );
    return count > 0;
  }

  Future<void> upsert(Chapter chapter) async {
    if (chapter == null) {
      return null;
    }

    // This creates a Map<String, dynamic> of the attributes
    final attributes = chapter.toJson()..remove("novel");

    // Save relation
    _novelDao.upsert(chapter.novel);

    if (await exists(slug: chapter.slug)) {
      // Don't overwrite createdAt attribute during update
      attributes.remove("createdAt");

      await _database.update(
        table: Chapter.type,
        values: attributes,
        where: {"slug": chapter.slug},
      );
    } else {
      await _database.insert(
        table: Chapter.type,
        values: attributes,
      );
    }
  }

  Chapter _fromJoin(Map<String, dynamic> attributes) {
    final chapter = <String, dynamic>{};
    final novel = <String, dynamic>{};

    attributes.forEach((key, value) {
      if (key.startsWith(_chapterColumnPrefix)) {
        chapter[key.substring(_chapterColumnPrefix.length)] = value;
      } else if (key.startsWith(_novelColumnPrefix)) {
        novel[key.substring(_novelColumnPrefix.length)] = value;
      }
    });

    return Chapter.fromJson(chapter).copyWith(
      // Attach the novel object if present
      novel: novel["slug"] != null ? Novel.fromJson(novel) : null,
    );
  }

  static const _chapterColumnPrefix = "${Chapter.type}_";
  static const _novelColumnPrefix = "${Novel.type}_";

  String _chapterColumnSelection() {
    return Chapter.columns.map((col) => "${Chapter.type}.$col AS $_chapterColumnPrefix$col").join(", ");
  }

  String _novelColumnSelection() {
    return Novel.columns.map((col) => "${Novel.type}.$col AS $_novelColumnPrefix$col").join(", ");
  }
}
